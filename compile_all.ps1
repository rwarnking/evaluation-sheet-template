# https://www.techtarget.com/searchwindowsserver/tip/Understanding-the-parameters-of-Windows-PowerShell-functions
param(
    [Parameter()]
    [string]$SrcFolder,

    [Parameter()]
    $TutorList,

    [Parameter()]
    [switch]$override,

    [Parameter()]
    [switch]$help,

    [Parameter()]
    [switch]$points
)

# Globals
$FileName = "evaluation-sheet"
$SheetName = "sheet_"
$TexName = -join($FileName, ".tex")
$PdfName = -join($FileName, ".pdf")

# TODOs
# Save and reset to default
# Actually replace the coursename with the input folder (\def\coursename{example-coursename-1})

###################################################################################################
# Functions
###################################################################################################
function New-Sheets {
    param(
        [Parameter()]
        [int]$TutorID
    )

    Write-Host "Start compiling!"
    $ErrCounter = 0

    # Replace tutor id if present
    if ($TutorID) {
        $SheetName = -join("tutor_", $TutorID, "_sheet_")
        $CurTutor = -join("\\def\\tutornumber\{[0-9]*\}")
        $ReplTutor = -join("\def\tutornumber{", $TutorID, "}")
        (Get-Content -Path .\$TexName) |
            ForEach-Object {$_ -Replace $CurTutor, $ReplTutor} |
                Set-Content -Path .\$TexName
    }

    ###########################################
    # Loop all sheets in the source directory #
    ###########################################
    $SheetList = Get-ChildItem -Path .\$SrcFolder\ | Where-Object { $_.Name -match '^sheet_[0-9][0-9]\.csv$' }
    $SheetList | ForEach-Object {
        $tmp = $_ -split {$_ -eq "_" -or $_ -eq "."}
        $SheetNumber = $tmp[1]

        # Replace sheet line in tex file
        $CurSheet = -join("\\def\\sheetnumber\{[0-9][0-9]\}")
        $ReplSheet = -join("\def\sheetnumber{", $SheetNumber, "}")
        (Get-Content -Path .\$TexName) |
            ForEach-Object {$_ -Replace $CurSheet, $ReplSheet} |
                Set-Content -Path .\$TexName

        $NewPdfName = -join($SheetName, $SheetNumber, ".pdf")
        $TgtPath = -join(".\", $TgtFolder, "\", $NewPdfName)
        $TmpPath = -join(".\", $NewPdfName)
        $PointsPath = -join(".\", $SrcFolder, "\sheet_", $SheetNumber, "_points", ".csv")

        # Check if the file already exists and is not allowed to be overriden
        if ((Test-Path $TgtPath) -and !($override.IsPresent))
        {
            Write-Host "Did not compile sheet"$SheetNumber", because:" -ForegroundColor DarkRed
            Write-Host "Can not move file"$TgtPath"! An old version is already present!" -ForegroundColor DarkRed
            $ErrCounter++
        }
        # Check if the file already exists and is not allowed to be overriden
        elseif ((Test-Path $TmpPath) -and !($override.IsPresent))
        {
            Write-Host "Did not compile sheet"$SheetNumber", because:" -ForegroundColor DarkRed
            Write-Host "Can not create file"$TmpPath"! An old version is already present!" -ForegroundColor DarkRed
            $ErrCounter++
        }
        # Check if point data is missing but should be used
        elseif (!(Test-Path $PointsPath) -and $points.IsPresent)
        {
            Write-Host "Did not compile sheet"$SheetNumber", because:" -ForegroundColor DarkRed
            Write-Host "Can not find file"$PointsPath" (for the points data)!" -ForegroundColor DarkRed
            $ErrCounter++
        }
        else
        {
            Write-Host "Compile sheet"$SheetNumber"!" -ForegroundColor DarkGreen

            # Compile tex file
            Invoke-Expression "latexmk -pdf $TexName"

            # If override is active remove file
            if ((Test-Path $TmpPath) -and $override.IsPresent)
            {
                Remove-Item $TmpPath
            }
            # Rename item such that the next sheet can be compiled
            Rename-Item -Path $PdfName -NewName $TmpPath

            # If override is active remove file in sheets before moving
            if ((Test-Path $TgtPath) -and $override.IsPresent)
            {
                Remove-Item $TgtPath
                Write-Host "Overriding file"$TgtPath"!" -ForegroundColor DarkYellow
            }
            Move-Item -Path $TmpPath -Destination $TgtPath
        }
    }

    return ($ErrCounter, $SheetList.Count)
}

###################################################################################################
# Main
###################################################################################################
if ($help.IsPresent) {
    Write-Host "
    This script can automatically compile all sheets of a given folder.
    For this a source directory is needed. For each sheet_XX.csv inside the given folder
    a PDF is created using the evaluation-sheet.tex.
    Of course you are free to alter the needed directorys in this script.

    Parameter:
        -SrcFolder The folder in which the sheets can be found
        -TutorList Allows to process multiple tutors at once (otherwise current setting is used)
        -override, -o Override files if they are already present
        -points, -p If this parameter is given 'display points' is enabled otherwise the points are not used
        -help, -h Shows how to use this script

    Examples for invoking compilation:
        .\compile_all.ps1 2018-19_example-coursename-1
        .\compile_all.ps1 2018-19_example-coursename-1 -o
        .\compile_all.ps1 2018-19_example-coursename-1 -TutorList (1,2)
    "
} elseif ($SrcFolder) {
    $TgtFolder = "sheets"

    # Check if input folder exists
    if (!(Test-Path .\$SrcFolder))
    {
        Write-Host "ERROR: source folder does not exist!" -ForegroundColor DarkRed
        return
    }
    # Check if groups exist
    if (!(Test-Path .\$SrcFolder\groups.csv))
    {
        Write-Host "ERROR: source folder does not contain groups.csv!" -ForegroundColor DarkRed
        return
    }
    # Check if participants exist
    if (!(Test-Path .\$SrcFolder\participants.csv))
    {
        Write-Host "ERROR: source folder does not contain participants.csv!" -ForegroundColor DarkRed
        return
    }

    if (!(test-path .\$TgtFolder))
    {
        # Create sheets folder if not existent and hide console output
        [void](New-Item -ItemType Directory -Force -Path .\$TgtFolder)
    }

    [int]$ErrorCounter = 0
    [int]$SheetCounter = 0

    # Enable if parameter present
    # Otherwise disable points
    if ($points.IsPresent) {
        $CurPoints = "\\newcommand\{\\showpoints\}\{\\disable\}"
        $ReplPoints = "\newcommand{\showpoints}{\enable}"
    } else {
        $CurPoints = "\\newcommand\{\\showpoints\}\{\\enable\}"
        $ReplPoints = "\newcommand{\showpoints}{\disable}"
    }
    (Get-Content -Path .\$TexName) |
    ForEach-Object {$_ -Replace $CurPoints, $ReplPoints} |
        Set-Content -Path .\$TexName

    #########################
    # Call compile function #
    #########################
    # If a tutorlist is present create sheets for all tutors otherwise just use the current tutor
    if ($TutorList) {
        $TutorList | ForEach-Object {
            # https://stackoverflow.com/questions/22663848/
            $result = (New-Sheets $_ | Select-Object -last 2)
            $ErrorCounter += $result[0]
            $SheetCounter += $result[1]
        }
    }
    else
    {
        $result = (New-Sheets | Select-Object -last 2)
        $ErrorCounter = $result[0]
        $SheetCounter = $result[1]
    }

    # Cleanup
    Invoke-Expression "latexmk -c"

    if ($ErrorCounter -gt 0) {
        Write-Host "Finished compiling."$ErrorCounter" files had errors! Processed" $SheetCounter" files." -ForegroundColor DarkRed
    } else {
        Write-Host "Finished compiling without errors! Processed"$SheetCounter" files." -ForegroundColor DarkGreen
    }
} else {
    Write-Host "This script can automatically compile all sheets of a given folder.
    For more information:
    .\compile_all.ps1 -help"
}

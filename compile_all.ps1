[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'override', Justification = 'False positive')]
# https://www.techtarget.com/searchwindowsserver/tip/Understanding-the-parameters-of-Windows-PowerShell-functions
param(
    [Parameter()]
    [string]$SrcFolder,

    [Parameter()]
    $TutorList,

    [Parameter()]
    [switch]$override,

    [Parameter()]
    [switch]$points,

    [Parameter()]
    [switch]$cols,

    [Parameter()]
    [switch]$help
)

# Globals
$FileName = "evaluation-sheet"
if ($cols.IsPresent)
{
    $FileName = "evaluation-sheet-taskcol"
}
$SheetName = "sheet_"
$TexName = -join($FileName, ".tex")
$PdfName = -join($FileName, ".pdf")
$changes = @()

<#
.DESCRIPTION
Prints the given text in red to the console using Write-Warning.

.PARAMETER Text
The text to print to the console.
#>
function Write-Problem {
    param(
        [Parameter()]
        [String]$text
    )
    $host.UI.RawUI.ForegroundColor = "DarkRed"
    Write-Output "$text" | out-host
    $host.UI.RawUI.ForegroundColor = "Gray"
}

<#
.DESCRIPTION
Prints the given text in green to the console using Write-Warning.

.PARAMETER Text
The text to print to the console.
#>
function Write-Success {
    param(
        [Parameter()]
        [String]$Text
    )
    $host.UI.RawUI.ForegroundColor = "DarkGreen"
    Write-Output "$Text" | out-host
    $host.UI.RawUI.ForegroundColor = "Gray"
}

###################################################################################################
# Functions
###################################################################################################
<#
.SYNOPSIS
Compile all sheets

.DESCRIPTION
Creates a PDF for each sheet found inside the given folder.
For this the $Filename.tex is compiled using latexmk for each sheet.
Each sheet is renamed according to the tutor settings and moved inside a $TgtFolder folder.

.PARAMETER TutorID
The tutor id that should is used to select the corresponding groups and there points if needed.

.EXAMPLE
$result = (New-Sheet $_ | Select-Object -last 2)

.NOTES
Overrides files according to $override.IsPresent variable.
Returns a value of how many errors were encountered and a value for the number of
processed filed
#>
function New-Sheet {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='None')]
    param(
        [Parameter()]
        [int]$TutorID
    )

    Write-Success "Start compiling!"
    $ErrCounter = 0

    # Replace tutor id if present
    if ($TutorID) {
        $SheetName = -join("tutor_", $TutorID, "_sheet_")
        $CurTutor = -join("^\\def\\tutornumber\{[0-9]*\}$")
        $ReplTutor = -join("\def\tutornumber{", $TutorID, "}")
        Edit-LastOccur $CurTutor $ReplTutor
    }

    ###########################################
    # Loop all sheets in the source directory #
    ###########################################
    $SheetList = Get-ChildItem -Path .\$SrcFolder\ | Where-Object { $_.Name -match '^sheet_[0-9]*\.csv$' }
    $SheetList | ForEach-Object {
        $tmp = $_ -split {$_ -eq "_" -or $_ -eq "."}
        $SheetNumber = $tmp[1]

        # Replace sheet line in tex file
        $CurSheet = -join("^\\def\\sheetnumber\{[0-9]*\}$")
        $ReplSheet = -join("\def\sheetnumber{", $SheetNumber, "}")
        Edit-LastOccur $CurSheet $ReplSheet

        $NewPdfName = -join($SheetName, $SheetNumber, ".pdf")
        $TgtPath = -join(".\", $TgtFolder, "\", $NewPdfName)
        $TmpPath = -join(".\", $NewPdfName)
        $PointsPath = -join(".\", $SrcFolder, "\sheet_", $SheetNumber, "_points", ".csv")

        # Check if the file already exists and is not allowed to be overriden
        if ((Test-Path $TgtPath) -and -not $override.IsPresent)
        {
            Write-Warning "Did not compile sheet $SheetNumber, because:"
            Write-Problem "Can not move file $TgtPath! An old version is already present!"
            $ErrCounter++
        }
        # Check if the file already exists and is not allowed to be overriden
        elseif ((Test-Path $TmpPath) -and -not $override.IsPresent)
        {
            Write-Warning "Did not compile sheet $SheetNumber, because:"
            Write-Problem "Can not create file $TmpPath! An old version is already present!"
            $ErrCounter++
        }
        # Check if point data is missing but should be used
        elseif (!(Test-Path $PointsPath) -and $points.IsPresent)
        {
            Write-Warning "Did not compile sheet $SheetNumber, because:"
            Write-Problem "Can not find file $PointsPath (for the points data)!"
            $ErrCounter++
        }
        else
        {
            Write-Success "Compile sheet $SheetNumber!"

            # Compile tex file
            latexmk -pdf $TexName

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
                Write-Warning "Overriding file $TgtPath!"
            }
            Move-Item -Path $TmpPath -Destination $TgtPath
        }
    }

    return ($ErrCounter, $SheetList.Count)
}

# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-content?view=powershell-7.2
# https://stackoverflow.com/questions/50044959/get-a-line-number-on-powershell
<#
.SYNOPSIS
Edits the $TexName file.

.DESCRIPTION
Replaces the LAST occurance of $Pattern with $Replacement inside the $TexName file.
For this all occurances of the pattern inside the file are saved in an array.
If the array is not empty the linenumber of the last entry is used to modifiy the content.
If a change is not present inside the $script:changes array the change is saved, so
the change can be revoked later

.PARAMETER Pattern
A powershell regular expression string that shall be matched inside the $TexName file.

.PARAMETER Replacement
A replacement string that shall replace the last found $Pattern.

.EXAMPLE
Edit-LastOccur "Regexpattern" "Replacement"

.NOTES
Does nothing if no matches were found.
#>
function Edit-LastOccur {
    param(
        [Parameter()]
        [string]$Pattern,

        [Parameter()]
        [string]$Replacement
    )

    # Get file content and store it into $content variable
    $content = Get-Content -Path .\$TexName
    # Get line numbers
    $linenumber = $content | select-string $Pattern

    # If at least one match was found, replace
    if ($linenumber.Count -gt 0) {
        # Save a line only once
        if (!$script:changes.Contains($linenumber.LineNumber[-1])) {
            $script:changes += $linenumber.LineNumber[-1]
            $script:changes += $linenumber
        }

        # Replace the line with the new text
        $content[$linenumber.LineNumber[-1] - 1] = $Replacement

        # Set the new content
        $content | Set-Content -Path .\$TexName
    }
}

###################################################################################################
# Main
###################################################################################################
if ($help.IsPresent) {
    Write-Success "
    This script can automatically compile all sheets of a given folder.
    For this a source directory is needed. For each sheet_XX.csv inside the given folder
    a PDF is created using the evaluation-sheet.tex.
    Of course you are free to alter the needed directorys in this script.

    Parameter:
        -SrcFolder The folder in which the sheets can be found
        -TutorList Allows to process multiple tutors at once (otherwise current setting is used)
        -override, -o Override files if they are already present
        -cols, -c Use evaluation-sheet-taskcol.tex (tasks in columns, default is tasks in rows)
        -points, -p If this parameter is given 'display points' is enabled otherwise the points are not used
        -help, -h Shows how to use this script

    Examples for invoking compilation:
        .\compile_all.ps1 2018-19_example-coursename-1
        .\compile_all.ps1 2018-19_example-coursename-1 -o
        .\compile_all.ps1 2018-19_example-coursename-1 -cols -o
        .\compile_all.ps1 2018-19_example-coursename-1 -TutorList (1,2)
    "
} elseif ($SrcFolder) {
    $TgtFolder = "sheets"

    # Check if input folder exists
    if (!(Test-Path .\$SrcFolder))
    {
        Write-Problem "Source folder does not exist!"
        return
    }
    # Check if groups exist
    if (!(Test-Path .\$SrcFolder\groups.csv))
    {
        Write-Problem "Source folder does not contain groups.csv!"
        return
    }
    # Check if participants exist
    if (!(Test-Path .\$SrcFolder\participants.csv))
    {
        Write-Problem "Source folder does not contain participants.csv!"
        return
    }
    # Create if not present
    if (!(test-path .\$TgtFolder))
    {
        # Create sheets folder if not existent and hide console output
        [void](New-Item -ItemType Directory -Force -Path .\$TgtFolder)
    }

    [int]$ErrorCounter = 0
    [int]$SheetCounter = 0
    $tmp = $SrcFolder -split "_"

    # Set the year in the tex file
    $CurYear = "^\\def\\semester\{[\d-]*\}"
    $ReplYear = -join("\def\semester{", $tmp[0], "} % chktex 8")
    Edit-LastOccur $CurYear $ReplYear

    # Set the course name in the tex file
    $CurDir = "^\\def\\coursename\{.*\}$"
    $ReplDir = -join("\def\coursename{", $tmp[1], "}")
    Edit-LastOccur $CurDir $ReplDir

    # Enable points if parameter present
    # Otherwise disable points
    $CurPoints = "^\\newcommand\{\\showpoints\}\{\\(disable|enable)\}$"
    if ($points.IsPresent) {
        $ReplPoints = "\newcommand{\showpoints}{\enable}"
    } else {
        $ReplPoints = "\newcommand{\showpoints}{\disable}"
    }
    Edit-LastOccur $CurPoints $ReplPoints

    #########################
    # Call compile function #
    #########################
    # If a tutorlist is present create sheets for all tutors otherwise just use the current tutor
    if ($TutorList) {
        $TutorList | ForEach-Object {
            # https://stackoverflow.com/questions/22663848/
            $result = (New-Sheet $_ | Select-Object -last 2)
            $ErrorCounter += $result[0]
            $SheetCounter += $result[1]
        }
    }
    else
    {
        $result = (New-Sheet | Select-Object -last 2)
        $ErrorCounter = $result[0]
        $SheetCounter = $result[1]
    }

    # Change the content back to the original
    for ($i=0; $i -lt $changes.length; $i+=2) {
        # Get file content and store it into $content variable
        $content = Get-Content -Path .\$TexName
        $content[$changes[$i] - 1] = $changes[$i+1]
        # Set the new content
        $content | Set-Content -Path .\$TexName
    }

    # Cleanup
    latexmk -c

    if ($ErrorCounter -gt 0) {
        Write-Warning "Finished compiling. $ErrorCounter files had errors! Processed $SheetCounter files."
    } else {
        Write-Success "Finished compiling without errors! Processed $SheetCounter files."
    }
} else {
    Write-Success "This script can automatically compile all sheets of a given folder.
    For more information:
    .\compile_all.ps1 -help"
}

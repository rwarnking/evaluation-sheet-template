param(
     [Parameter()]
     [string]$SrcFolder,

     [Parameter()]
     [switch]$override,

     [Parameter()]
     [switch]$help
)

# TODOs
# Allow to select tutor
# Enable disable points
# Save and reset to default

if ($help.IsPresent) {
    Write-Host "
    This script can automatically compile all sheets of a given folder.
    For this a source directory is needed. For each sheet_XX.csv inside the given folder
    a PDF is created using the evaluation-sheet.tex.
    Of course you are free to alter the needed directorys in this script.

    Command for invoking compilation:
    .\compile_all.ps1 2018-19_example-coursename-1
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

    Write-Host "Start compiling!"

    $FileName = "evaluation-sheet"
    $SheetName = "sheet_"
    $TexName = -join($FileName, ".tex")
    $PdfName = -join($FileName, ".pdf")
    $ErrorCounter = 0

    # For all sheets in the source directory
    $SheetList = Get-ChildItem -Path .\$SrcFolder\ | Where-Object { $_.Name -match '^sheet_[0-9][0-9]\.csv$' }
    $SheetList | ForEach-Object {
        $tmp = $_ -split {$_ -eq "_" -or $_ -eq "."}
        $SheetNumber = $tmp[1]

        # Replace sheet line in tex file
        $ToReplace = -join("\\def\\sheetnumber\{[0-9][0-9]\}")
        $Replacement = -join("\def\sheetnumber{", $SheetNumber, "}")
        (Get-Content -Path .\$TexName) |
            ForEach-Object {$_ -Replace $ToReplace, $Replacement} |
                Set-Content -Path .\$TexName

        $NewPdfName = -join($SheetName, $SheetNumber, ".pdf")
        $TgtPath = -join(".\", $TgtFolder, "\", $NewPdfName)
        $TmpPath = -join(".\", $NewPdfName)

        if ((Test-Path $TgtPath) -and !($override.IsPresent))
        {
            Write-Host "Did not compile sheet"$SheetNumber", because:" -ForegroundColor DarkRed
            Write-Host "Can not move file"$TgtPath"! An old version is already present!" -ForegroundColor DarkRed
            $ErrorCounter++
        }
        elseif ((Test-Path $TmpPath) -and !($override.IsPresent))
        {
            Write-Host "Did not compile sheet"$SheetNumber", because:" -ForegroundColor DarkRed
            Write-Host "Can not create file"$TmpPath"! An old version is already present!" -ForegroundColor DarkRed
            $ErrorCounter++
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

            # If override is active remove file in sheets
            if ((Test-Path $TgtPath) -and $override.IsPresent)
            {
                Remove-Item $TgtPath
                Write-Host "Overriding file"$TgtPath"!" -ForegroundColor DarkYellow
            }
            Move-Item -Path $TmpPath -Destination $TgtPath
        }
    }

    # Cleanup
    Invoke-Expression "latexmk -c"

    if ($ErrorCounter -gt 0) {
        Write-Host "Finished compiling."$ErrorCounter" files had errors! Processed" $SheetList.Count "Files." -ForegroundColor DarkRed
    } else {
        Write-Host "Finished compiling without errors! Processed"$SheetList.Count"Files." -ForegroundColor DarkGreen
    }
} else {
    Write-Host "This script can automatically compile all sheets of a given folder.
    For more information:
    .\compile_all.ps1 -help"
}

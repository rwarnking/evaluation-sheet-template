param($p1)

# TODOs
# Create sheets folder
# Allow to select tutor
# Allow to select folder
# What if sheets already present
# Enable disable points
# Save and reset to default

if ($p1 -eq 'H' -Or $p1 -eq 'h' -Or $p1 -eq 'help' -Or $p1 -eq 'Help' -Or $p1 -eq 'HELP') {
    Write-Host "
    This script can automatically compile all sheets of a given folder.
    For this a source directory is needed. For each sheet_XX.csv inside the given folder
    a PDF is created using the evaluation-sheet.tex.
    Of course you are free to alter the needed directorys in this script.

    Command for invoking compilation:
    .\compile_all.ps1 2018-19_example-coursename-1
    "
} elseif ($p1) {
    $SrcFolder = $p1
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
        New-Item -ItemType Directory -Force -Path .\$TgtFolder
    }

    Write-Host "Start compiling!"

    $FileName = "evaluation-sheet"
    $SheetName = "sheet_"
    $TexName = -join($FileName, ".tex")
    $PdfName = -join($FileName, ".pdf")

    # For all sheets in the source directory
    $SheetList = Get-ChildItem -Path .\$SrcFolder\ | Where-Object { $_.Name -match '^sheet_[0-9][0-9]\.csv$' }
    $SheetList | ForEach-Object {
        $tmp = $_ -split {$_ -eq "_" -or $_ -eq "."}
        $SheetNumber = $tmp[1]

        Write-Host "Compile sheet"$SheetNumber"!" -ForegroundColor DarkGreen

        # Replace sheet line in tex file
        $ToReplace = -join("\\def\\sheetnumber\{[0-9][0-9]\}")
        $Replacement = -join("\def\sheetnumber{", $SheetNumber, "}")
        (Get-Content -Path .\$TexName) |
            ForEach-Object {$_ -Replace $ToReplace, $Replacement} |
                Set-Content -Path .\$TexName

        # Compile tex file
        Invoke-Expression "latexmk -pdf $TexName"

        # Rename item such that the next sheet can be compiled
        $NewPdfName = -join($SheetName, $SheetNumber, ".pdf")
        Rename-Item -Path $PdfName -NewName $NewPdfName
        Move-Item -Path .\$NewPdfName -Destination .\$TgtFolder\$NewPdfName
    }

    # Cleanup
    Invoke-Expression "latexmk -c"

    Write-Host "Finished compiling! Processed"$SheetList.Count"Files!" -ForegroundColor DarkGreen
} else {
    Write-Host "This script can automatically compile all sheets of a given folder.
    For more information:
    .\compile_all.ps1 help"
}

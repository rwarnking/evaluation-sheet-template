Write-Host "Installing dependencies (default/required packages)!"

# For calc package
# For tabularx package
# For array package
Invoke-Expression "tlmgr install tools"

Write-Host ""
Write-Host "Installing dependencies (mandatory packages)!"

Invoke-Expression "tlmgr install geometry"
# For loading the .csv files as database
Invoke-Expression "tlmgr install datatool"
# For \xintFor and similar
# For \xintifCmp and similar
Invoke-Expression "tlmgr install xint"
# For \forloop
Invoke-Expression "tlmgr install forloop"
# For \pgfmathresult and tikz
Invoke-Expression "tlmgr install pgf"
# Clip the informations to fit inside the table cells
Invoke-Expression "tlmgr install collectbox"
Invoke-Expression "tlmgr install adjustbox"

Write-Host ""
Write-Host "Installing dependencies (optional task packages)!"

# Used to reduce distance between items in itemize (\setlist)
Invoke-Expression "tlmgr install listings"
# Used for displaying code inside the assignments (used for \lstset)
Invoke-Expression "tlmgr install enumitem"

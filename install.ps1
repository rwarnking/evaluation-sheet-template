Write-Host "Installing dependencies (default packages)!"

Invoke-Expression "tlmgr install inputenc"
Invoke-Expression "tlmgr install geometry"
Invoke-Expression "tlmgr install array"
Invoke-Expression "tlmgr install tabularx"

Write-Host "Installing dependencies (mandatory packages)!"

# For loading the .csv files as database
Invoke-Expression "tlmgr install datatool"
# For \xintFor and similar
# For \xintifCmp and similar
Invoke-Expression "tlmgr install xint"
# For \forloop
Invoke-Expression "tlmgr install forloop"
Invoke-Expression "tlmgr install calc"
# For \pgfmathresult
Invoke-Expression "tlmgr install tikz"
# Clip the informations to fit inside the table cells
Invoke-Expression "tlmgr install collectbox"
Invoke-Expression "tlmgr install adjustbox"

Write-Host "Installing dependencies (optional task packages)!"

# Used to reduce distance between items in itemize (\setlist)
Invoke-Expression "tlmgr install listings"
# Used for displaying code inside the assignments (used for \lstset)
Invoke-Expression "tlmgr install enumitem"

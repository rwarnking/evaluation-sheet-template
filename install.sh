#!/bin/bash
echo "Installing dependencies (default packages)!"

tlmgr install inputenc
tlmgr install geometry
tlmgr install array
tlmgr install tabularx

echo "Installing dependencies (mandatory packages)!"

# For loading the .csv files as database
tlmgr install datatool
# For \xintFor and similar
# For \xintifCmp and similar
tlmgr install xint
# For \forloop
tlmgr install forloop
tlmgr install calc
# For \pgfmathresult
tlmgr install tikz
# Clip the informations to fit inside the table cells
tlmgr install collectbox
tlmgr install adjustbox

echo "Installing dependencies (optional task packages)!"
# Used to reduce distance between items in itemize (\setlist)
tlmgr install listings
# Used for displaying code inside the assignments (used for \lstset)
tlmgr install enumitem

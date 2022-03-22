#!/bin/bash
printf "Installing dependencies (default/required packages)!"

# For calc package
# For tabularx package
# For array package
tlmgr install tools

printf "\n Installing dependencies (mandatory packages)!"

tlmgr install geometry
# For loading the .csv files as database
tlmgr install datatool
# For \xintFor and similar
# For \xintifCmp and similar
tlmgr install xint
# For \forloop
tlmgr install forloop
# For \pgfmathresult and tikz
tlmgr install pgf
# Clip the informations to fit inside the table cells
tlmgr install collectbox
tlmgr install adjustbox
# For string commands (for example equality tests)
tlmgr install xstring
# For dashed line
tlmgr install arydshln

printf "\n Installing dependencies (optional task packages)!"
# Used to reduce distance between items in itemize (\setlist)
tlmgr install listings
# Used for displaying code inside the assignments (used for \lstset)
tlmgr install enumitem

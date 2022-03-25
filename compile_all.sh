#!/bin/bash
###########
# Globals #
###########
FileName="evaluation-sheet"
SheetName="sheet_"
changes=()

ErrorCounter=0
SheetCounter=0

# Text colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

#####################
# Process parameter #
#####################
help=0
points=0
override=0
TutorList=()

if [[ "${1}" =~ ^[0-9]{4}(-[0-9]{2})?_.*$ ]]; then
    SrcFolder=$1
fi
# Iterate all parameter to get the user selection
for var in "$@"
do
    case $var in
        -h|--help) help=1; break;;
        -p|--points) points=1;;
        -o|--override) override=1;;
        -c|--cols) FileName="evaluation-sheet-taskcol";;
    esac
    if [[ "$var" =~ ^[0-9]+$ ]] ; then
        TutorList+=("${var}")
    fi
done

TexName="${FileName}.tex"
PdfName="${FileName}.pdf"

###################################################################################################
# Functions
###################################################################################################
#######################################
# Compile all sheets
# DESCRIPTION
#    Creates a PDF for each sheet found inside the given folder.
#    For this the $Filename.tex is compiled using latexmk for each sheet.
#    Each sheet is renamed according to the tutor settings and moved inside a $TgtFolder folder.
# ARGUMENTS:
#   The tutor id that should is used to select the corresponding groups and there points if needed.
# OUTPUTS:
#   The compiled sheets as PDF
# RETURN:
#   Returns a value of how many errors were encountered and a value for the number of
#   processed filed
#######################################
function New-Sheet {
    echo "Start compiling!"

    # Replace tutor id if present
    if [[ -n ${1} ]]; then
        SheetName="tutor_${1}_sheet_"
        CurTutor="^\\def\\tutornumber{[[:digit:]]*}$"
        ReplTutor="\\\def\\\tutornumber{${1}}"
        Edit-LastOccur "$CurTutor" "$ReplTutor"
    fi

#     ###########################################
#     # Loop all sheets in the source directory #
#     ###########################################
    # http://www.gnu.org/software/bash/manual/html_node/Pattern-Matching.html
    for fname in ./"$SrcFolder"/sheet_*[0-9].csv; do
        ((SheetCounter+=1))
        # Get sheetnumber
        [[ "$fname" =~ _([0-9]+).csv ]] && SheetNumber=${BASH_REMATCH[1]}

        # Replace sheet line in tex file
        CurSheet='^\\def\\sheetnumber{[[:digit:]]*}$'
        ReplSheet="\\\def\\\sheetnumber{${SheetNumber}}"
        Edit-LastOccur "$CurSheet" "$ReplSheet"

        NewPdfName="${SheetName}${SheetNumber}.pdf"
        TgtPath="./${TgtFolder}/${NewPdfName}"
        PointsPath="./${SrcFolder}/sheet_${SheetNumber}_points.csv"

        # Check if the file already exists and is not allowed to be overriden
        if [[ -e $TgtPath ]] && [[ $override -eq 0 ]]; then
            printf "%bERROR: Did not compile sheet %d, because:\n" "${RED}" "${SheetNumber}"
            printf "Can not move file %s! An old version is already present!%b\n" "${TgtPath}" "${NC}"
            ((ErrorCounter++))
        # Check if point data is missing but should be used
        elif [[ ! (-e $PointsPath) ]] && [[ $points -eq 1 ]]; then
            printf "%bERROR: Did not compile sheet %d, because:\n" "${RED}" "${SheetNumber}"
            printf "Can not find file %s (for the points data)!%b\n" "${PointsPath}" "${NC}"
            ((ErrorCounter++))
        else
            printf "%bCompile sheet %d%b\n" "${GREEN}" "${SheetNumber}" "${NC}"

            # Compile tex file
            latexmk -pdf $TexName

            # If override is active remove file in sheets before moving
            if [[ -e $TgtPath ]] && [[ $override -eq 1 ]]; then
                # Remove item
                rm "$TgtPath"
                printf "%bOverriding file %s!%b\n" "${YELLOW}" "${TgtPath}" "${NC}"
            fi

            # Move and rename item
            mv $PdfName "$TgtPath"
        fi
    done
}

#######################################
# Edits the $TexName file.
# DESCRIPTION
#     Replaces the LAST occurance of $Pattern with $Replacement inside the $TexName file.
#     For this all occurances of the pattern inside the file are saved in an array.
#     If the array is not empty the linenumber of the last entry is used to modifiy the content.
#     If a change is not present inside the $script:changes array the change is saved, so
#     the change can be revoked later
# ARGUMENTS:
#   Pattern A regular expression string that shall be matched inside the $TexName file.
#   Replacement A replacement string that shall replace the last found $Pattern.
# OUTPUTS:
#   Does nothing if no matches were found.
#######################################
Edit-LastOccur () {
    # Get file content and store it into $content variable
    # https://stackoverflow.com/questions/19771965/split-bash-string-by-newline-characters
    content=$(grep -n "${1}" ./${TexName})
    # Get line numbers
    IFS=$'\n' read -rd '' -a lines <<< "$content"

    # If at least one match was found, replace
    if [[ ${#lines[@]} -gt 0 ]]; then
        IFS=':' read -r -a lastline <<< "${lines[-1]}"

        # Save a line only once
        if [[ ! "${changes[*]}" =~ ${lastline[0]} ]]; then
            changes+=("${lastline[0]}")
            changes+=("${lastline[1]}")
        fi

        # https://stackoverflow.com/questions/11145270/
        # Replace the line with the new text
        sed -i "${lastline[0]}s/.*/${2}/" ./${TexName}
    fi
}

###################################################################################################
# Main
###################################################################################################
if [[ "$help" -eq 1 ]]; then
    echo "
    This script can automatically compile all sheets of a given folder.
    For this a source directory is needed. For each sheet_XX.csv inside the given folder
    a PDF is created using the evaluation-sheet.tex.
    Of course you are free to alter the needed directorys in this script.

    Parameter:
        SrcFolder (first parameter): The folder in which the sheets can be found
        TutorList (all number parameter): Allows to process multiple tutors at once (otherwise current setting is used)
        --override, -o Override files if they are already present
        --cols, -c Use evaluation-sheet-taskcol.tex (tasks in columns, default is tasks in rows)
        --points, -p If this parameter is given 'display points' is enabled otherwise the points are not used
        --help, -h Shows how to use this script

    Examples for invoking compilation:
        .\compile_all.sh 2018-19_example-coursename-1
        .\compile_all.sh 2018-19_example-coursename-1 -o
        .\compile_all.sh 2018-19_example-coursename-1 --cols -o
        .\compile_all.sh 2018-19_example-coursename-1 21 1 2 3
    "
elif [[ "$SrcFolder" ]]; then
    TgtFolder="sheets"

    # Check if input folder exists
    if [[ ! (-d ./$SrcFolder) ]]; then
        printf "%bERROR: source folder does not exist!" "${RED}"
        exit
    fi
    # Check if groups exist
    if [[ ! (-e ./$SrcFolder/groups.csv) ]]; then
        printf "%bERROR: source folder does not contain groups.csv!" "${RED}"
        exit
    fi
    # Check if participants exist
    if [[ ! (-e ./$SrcFolder/participants.csv) ]]; then
        printf "%bERROR: source folder does not contain participants.csv!" "${RED}"
        exit
    fi
    # Create if not present
    if [[ ! (-d ./$TgtFolder) ]]; then
        # Create sheets folder if not existent and hide console output
        mkdir -p ./$TgtFolder
    fi

    IFS='_' read -r -a tmp <<< "$SrcFolder"

    # Set the year in the tex file
    CurYear='^\\def\\semester{\([[:digit:]]\|\-\)*}'
    ReplYear="\\\def\\\semester{${tmp[0]}} % chktex 8"
    Edit-LastOccur "$CurYear" "$ReplYear"

    # Set the course name in the tex file
    CurDir='^\\def\\coursename{.*}$'
    ReplDir="\\\def\\\coursename{${tmp[1]}}"
    Edit-LastOccur "$CurDir" "$ReplDir"

    # Enable points if parameter present
    # Otherwise disable points
    CurPoints='^\\newcommand{\\showpoints}{\(\\disable\|\\enable\)}$'
    if [[ $points -eq 1 ]]; then
        ReplPoints="\\\newcommand{\\\showpoints}{\\\enable}"
    else
        ReplPoints="\\\newcommand{\\\showpoints}{\\\disable}"
    fi
    Edit-LastOccur $CurPoints $ReplPoints

    #########################
    # Call compile function #
    #########################
    # If a tutorlist is present create sheets for all tutors otherwise just use the current tutor
    if [[ ${#TutorList[@]} -ne 0 ]]; then
        for ((i=0; i<${#TutorList[@]}; i+=1));
        do
            New-Sheet "${TutorList[i]}"
        done
    else
        New-Sheet
    fi

    # Change the content back to the original
    for ((i=0; i<${#changes[@]}; i+=2));
    do
        ESCAPED_REPLACE=$(printf '%s\n' "${changes[i+1]}" | sed -e 's/[\/&]/\\&/g')
        sed -i "${changes[i]}s/.*/${ESCAPED_REPLACE}/" ./${TexName}
    done

    # Cleanup
    latexmk -c

    if [[ $ErrorCounter -gt 0 ]]; then
        printf "%bFinished compiling. %d files had errors! Processed %d files." "${RED}" "${ErrorCounter}" "${SheetCounter}"
    else
        printf "%bFinished compiling without errors! Processed %d files." "${GREEN}" "${SheetCounter}"
    fi
else
    echo "This script can automatically compile all sheets of a given folder.
    For more information:
    .\compile_all.sh --help"
fi

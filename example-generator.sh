#!/bin/bash
TgtFolder="2018_example-coursename-3"
TotalParticipants=30
sheets=4
tutorcount=2
# Set this to 1 to get taskcols assignments
taskcols=0
# The seperator
sep=";";

# Helper function to add one column value to the csv
function Add-Column {
    printf '%s%s ' "$1" "$sep" >> "$FileName"
}

# Create if not present
if [[ ! (-d ./$TgtFolder) ]]; then
    # Create data folder if not existent and hide console output
    mkdir -p ./$TgtFolder
else
    # Delete and recreate the folder
    rm -r ./$TgtFolder
    mkdir -p ./$TgtFolder
fi

###################################################################################################
# participants.csv
###################################################################################################
FileName="./$TgtFolder/participants.csv"

# The columns and default values
title=""
firstname="First"
lastname="Lastname"
title2=""
accountname=""
address=""
mobilenumber=""
email="@email.de"
enroldate=""
misc=""

salutationList=("Mr." "Mrs.")
# One of these is selected randomly
degreeList=("Bachelor" "Master")
studyList=("of Science" "of Arts" "of Laws" "of Philosophy")

# Generate n random ids with lenght of 6
min=111111
max=999999
ids=()
while IFS='' read -r line; do ids+=("$line"); done < <(shuf -i $min-$max -n $TotalParticipants)

namenumbers=()
while IFS='' read -r line; do namenumbers+=("$line"); done < <(shuf -i 1-$TotalParticipants -n $TotalParticipants)

# Print header
{
    printf "Anrede; Titel; Vorname; Nachname; Titel2; "
    printf "Nutzernamen; Privatadr; Privatnr; E-Mail; Anmeldedatum; "
    printf "Studiengaenge; Matrikelnr; Bemerkung\n"
} >> $FileName

# Main loop iterating all participants
for (( p=0; p<TotalParticipants; p++ ))
do
    # Get random salutation
    index=$(( RANDOM % ${#salutationList[@]} ))
    salutation=${salutationList[$index]}
    # Construct the field of study value
    index=$(( RANDOM % ${#degreeList[@]} ))
    fieldofstudy=${degreeList[$index]}
    index=$(( RANDOM % ${#studyList[@]} ))
    fieldofstudy="$fieldofstudy ${studyList[$index]}"
    # Get random semester number
    index=$(( RANDOM % 20 + 1))
    fieldofstudy="$fieldofstudy, $index"
    # Add leading zeros to the namenumber
    tmp=$(printf "%0*d" ${#TotalParticipants} "${namenumbers[$p]}")
    # Print all columns of the current row
    Add-Column "$salutation"
    Add-Column "$title"
    Add-Column "${firstname}${tmp}"
    Add-Column "${lastname}${tmp}"
    Add-Column "$title2"
    Add-Column "$accountname"
    Add-Column "$address"
    Add-Column "$mobilenumber"
    Add-Column "${lastname}${tmp}$email"
    Add-Column "$enroldate"
    Add-Column "$fieldofstudy"
    Add-Column "${ids[$p]}"
    Add-Column "$misc"
    printf "\n" >> $FileName
done

###################################################################################################
# groups.csv
###################################################################################################
FileName="./$TgtFolder/groups.csv"
printf "tutorid; groupid; date; participants; droppedout;\n" >> $FileName

# Create an arbitrary number of group with a random groupsize of upto four
members=0
groupList=()
for (( p=0; p<TotalParticipants; p+=members ))
do
    rand=$(( RANDOM % 100 ))
    if [[ $rand -lt 10 ]]; then
        members=4
    elif [[ $rand -lt 25 ]]; then
        members=3
    else
        members=2
    fi
    groupList+=("$members")
done

dateList=(
    "Mo. 09:00" "Mo. 09:30" "Mo. 10:00" "Mo. 10:30" "Mo. 11:00" "Mo. 11:30"
    "Tue. 09:00" "Tue. 09:30" "Tue. 10:00" "Tue. 10:30" "Tue. 11:00" "Tue. 11:30"
    "Wed. 09:00" "Wed. 09:30" "Wed. 10:00" "Wed. 10:30" "Wed. 11:00" "Wed. 11:30"
    "Thu. 09:00" "Thu. 09:30" "Thu. 10:00" "Thu. 10:30" "Thu. 11:00" "Thu. 11:30"
    "Fr. 09:00" "Fr. 09:30" "Fr. 10:00" "Fr. 10:30" "Fr. 11:00" "Fr. 11:30"
)
# Get a list of indices to access the group dates (sorted)
length=${#dateList[@]}
((length-=1))
dateidx=()
while IFS='' read -r line; do dateidx+=("$line"); done < <(shuf -i 0-${length} -n ${#groupList[@]} | sort -n)

# Get a list of indices to access the participant ids
length=${#ids[@]}
((length-=1))
idsidx=()
while IFS='' read -r line; do idsidx+=("$line"); done < <(shuf -i 0-${length} -n $TotalParticipants)

# Add a row to the csv for each group
start=0
end=0
for (( g=0; g<${#groupList[@]}; g++ ))
do
    # Assign a random tutornumber
    tutor=$(( RANDOM % tutorcount + 1 ))
    Add-Column "$tutor"
    # Add groupnumber
    group=$((g+1))
    Add-Column "$group"
    # Add date for the group, the dates are sorted
    idx=${dateidx[$g]}
    Add-Column "${dateList[$idx]}"

    # For each participant of this group add the part-number and the drop-number
    partarray=""
    droparray=""
    start=$end
    ((end+=${groupList[$g]}))
    for (( i=start; i<end; i++ ))
    do
        idx=${idsidx[$i]}
        partarray+="${ids[$idx]}"
        # Add a random number to indicate if the participant droped out and during which sheet
        rand=$(( RANDOM % 100 ))
        if [[ $rand -lt 10 ]]; then
            sheet=$(( RANDOM % sheets ))
            droparray+="$sheet"
        elif [[ $rand -lt 20 ]]; then
            sheet=$(( RANDOM % sheets ))
            droparray+="-$sheet"
        else
            # Participant did not drop out and was part of this group from the beginning
            droparray+="0"
        fi
        if [[ $i -lt $end-1 ]]; then
            partarray+=","
            droparray+=","
        fi
    done
    Add-Column "{${partarray[*]}}"
    Add-Column "{${droparray[*]}}"
    printf "\n" >> $FileName
done

###################################################################################################
# sheet_XX.csv
###################################################################################################
#######################################
# Helper function to print one row of a subtask
# DESCRIPTION
#     Print the fields taskid, title, points and description into one row of the specified csv.
#     Uses taskcoloptions/taskrowoptions for the description value.
# ARGUMENTS:
#     An additional subtask parameter (-1, -2, -3, ...) which is only used in taskcol mode.
#     It allows for multiline subtasks.
#######################################
function Add-Subtaskrow {
    Add-Column "$ipo${letters[$idx]}$1"
    taskIdList+=("$ipo${letters[$idx]}$1")
    # Title column is empty for all subtasks
    if [[ $taskcols -eq 1 ]]; then
        Add-Column ""
    else
        Add-Column ""
    fi
    # Points column
    Add-Column "${subpoints[$j]}"
    # Randomized description column
    if [[ $taskcols -eq 1 ]]; then
        index=$(( RANDOM % ${#taskcoloptions[@]} ))
        Add-Column "${taskcoloptions[$index]}"
    else
        index=$(( RANDOM % ${#taskrowoptions[@]} ))
        Add-Column "${taskrowoptions[$index]}"
    fi
    printf "\n" >> $FileName
}

# Specifies target number of tasks
TotalTasks=12
# To label the subtasks
letters=({a..z})
# Text options for the task descriptions
taskcoloptions=("Calculation" "Explanation" "Algorithm" "Result")
taskrowoptions=(
    "\begin{itemize}\item Topic 1\item Topic 2\end{itemize}"
    "\textbf{Text 1}"
    "\textcolor{javapurple}{Text 2}"
    "Text [3]"
    "Text 4,5"
    'Text $\sqrt{6}$'
    "Explanation 2a\newline Explanation( 2b"
    'Explanation $[3 + 3]$\newline $\Rightarrow$ Explanation) 3'
)

# Generate as many sheets as defined
for (( s=1; s<=sheets; s++ ))
do
    # Create name and push header to the file
    FileName="./$TgtFolder/sheet_0$s.csv"
    printf "taskid; title; points; description;\n" >> $FileName

    subtasks=0
    # List of integers specifying the number of subtasks for each task
    taskList=()
    # List of all task ids / points, used for point sheet
    taskIdList=()
    pointsList=()
    subpointsList=()
    # Max points available on this sheet (starts with 1 for %, used for point sheet)
    sheetPoints=1
    # Fill the tasklist with pseudo random values
    for (( t=0; t<TotalTasks; t+=subtasks ))
    do
        rand=$(( RANDOM % 100 ))
        if [[ $rand -lt 30 ]]; then
            subtasks=4
        elif [[ $rand -lt 70 ]]; then
            subtasks=3
        elif [[ $rand -lt 80 ]]; then
            subtasks=2
        else
            subtasks=1
        fi
        taskList+=("$subtasks")
    done

    # Generate each task with the definied number of subtasks
    for (( t=0; t<${#taskList[@]}; t++ ))
    do
        # List of integers specifying the points for each subtasks
        subpoints=()
        while IFS='' read -r line; do subpoints+=("$line"); done < <(shuf -i 1-4 -n "${taskList[t]}" -r)

        # Sum the subtaskpoints
        sumpoints=0
        for val in "${subpoints[@]}"; do
            ((sumpoints+=val))
        done
        # Add all point values to one list
        pointsList+=($sumpoints)
        subpointsList+=(${subpoints[@]})
        (( sheetPoints+=$sumpoints ))

        # Add columns for taskid, title and points
        ipo=$((t+1))
        Add-Column "$ipo"
        taskIdList+=("$ipo")
        Add-Column "Assignment $ipo"
        Add-Column "$sumpoints"
        # Add the description column with value dependent on the column type
        # and the number of subtasks.
        if [[ $taskcols -eq 1 ]]; then
            if [[ ${taskList[t]} -gt 1 ]]; then
                Add-Column "Sum"
            else
                Add-Column "Result"
            fi
        else
            if [[ ${taskList[t]} -gt 1 ]]; then
                Add-Column ""
            else
                # Select a random predefined description
                index=$(( RANDOM % ${#taskrowoptions[@]} ))
                Add-Column "Description ${taskrowoptions[$index]}"
            fi
        fi
        printf "\n" >> $FileName

        # Add subtasks if there are any
        if [[ ${taskList[t]} -gt 1 ]]; then
            idx=0
            for (( j=0; j<${taskList[$t]}; j++ ))
            do
                # If taskcolumns are enabled randomly use the -1, ... subfix
                # But check for max amount of subtasks
                if [[ $taskcols -eq 1 ]]; then
                    rand=$(( RANDOM % 100 ))
                    if [[ $rand -lt 30 && $((j+2))<${taskList[$t]} ]]; then
                        Add-Subtaskrow "-1"
                        ((j++))
                        Add-Subtaskrow "-2"
                        ((j++))
                        Add-Subtaskrow "-3"
                    elif [[ $rand -lt 50 && $((j+1))<${taskList[$t]} ]]; then
                        Add-Subtaskrow "-1"
                        ((j++))
                        Add-Subtaskrow "-2"
                    else
                        Add-Subtaskrow
                    fi
                else
                    Add-Subtaskrow
                fi
                ((idx++))
            done
        fi
    done

    ###############################################################################################
    # sheet_01_points.csv
    ###############################################################################################
    # Create name and push header to the file
    FileName="./${TgtFolder}/sheet_0${s}_points.csv"
    Add-Column "groupid"
    # Add header
    for (( t=0; t<${#taskIdList[@]}; t++ ))
    do
        Add-Column "${taskIdList[t]}"
    done
    printf "\n" >> $FileName

    # Add all groups
    for (( g=1; g<=${#groupList[@]}; g++ ))
    do
        # Add group id
        Add-Column "$g"
        # Add random points for the complete sheet
        totalpoints=$(( RANDOM % $sheetPoints ))
        taskpoints=()
        notfull=()

        # Initialize the taskpoints with zero
        for (( t=0; t<${#taskList[@]}; t++ ))
        do
            taskpoints+=(0)
            notfull+=($t)
        done

        # Distribute all points in increments of one to the different tasks
        # If a task is full remove it from the list such that it can not get any more points
        for (( p=0; p<$totalpoints; p++ ))
        do
            # Get random task idx which is not yet full
            idx=$(( RANDOM % ${#notfull[@]} ))
            # Get element at idx and increment
            tidx=${notfull[$idx]}
            (( taskpoints[$tidx]++ ))
            # Remove from list
            if [[ ${taskpoints[$tidx]} -eq ${pointsList[$tidx]} ]]; then
                unset "notfull[$idx]"
                notfull=("${notfull[@]}")
            fi
        done

        # offset needed to access the correct point informations for the subtasks
        offset=0
        # Iterate all major tasks
        for (( t=0; t<${#taskList[@]}; t++ ))
        do
            # Add points for the current task
            Add-Column "${taskpoints[t]}"
            # Process potential subtasks
            if [[ ${taskList[t]} -gt 1 ]]; then
                subtaskpoints=()
                notfull=()
                # Initialize the subtaskpoints with zero
                for (( st=0; st<${taskList[t]}; st++ ))
                do
                    subtaskpoints+=(0)
                    notfull+=($st)
                done
                # Distribute the points for this task across all subtasks
                for (( p=0; p<${taskpoints[t]}; p++ ))
                do
                    # Get random task idx which is not yet full
                    idx=$(( RANDOM % ${#notfull[@]} ))
                    # Get element at idx and increment
                    stidx=${notfull[$idx]}
                    (( subtaskpoints[$stidx]++ ))
                    # Remove from list (beware the offset)
                    if [[ ${subtaskpoints[$stidx]} -eq ${subpointsList[$((stidx+offset))]} ]]; then
                        unset "notfull[$idx]"
                        notfull=("${notfull[@]}")
                    fi
                done
                # Add the point value to the column
                for (( st=0; st<${taskList[t]}; st++ ))
                do
                    Add-Column "${subtaskpoints[st]}"
                done
            fi
            ((offset+=${taskList[t]}))
        done
        printf "\n" >> $FileName
    done
done

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
    printf "$1$sep" >> $FileName
}

# Create if not present
if [[ !(-d ./$TgtFolder) ]]; then
    # Create data folder if not existent and hide console output
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
ids=($(shuf -i $min-$max -n $TotalParticipants))

namenumbers=($(shuf -i 1-$TotalParticipants -n $TotalParticipants))

# Print header
printf "Anrede;Titel;Vorname;Nachname;Titel2;" >> $FileName
printf "Nutzernamen;Privatadr;Privatnr;E-Mail;Anmeldedatum;" >> $FileName
printf "Studiengaenge;Matrikelnr;Bemerkung\n" >> $FileName

# Main loop iterating all participants
for (( i=0; i<$TotalParticipants; i++ ))
do
    # Get random salutation
    index=$(( $RANDOM % ${#salutationList[@]} ))
    salutation=${salutationList[$index]}
    # Construct the field of study value
    index=$(( $RANDOM % ${#degreeList[@]} ))
    fieldofstudy=${degreeList[$index]}
    index=$(( $RANDOM % ${#studyList[@]} ))
    fieldofstudy="$fieldofstudy ${studyList[$index]}"
    # Get random semester number
    index=$(( $RANDOM % 20 + 1))
    fieldofstudy="$fieldofstudy, $index"
    # Add leading zeros to the namenumber
    tmp=$(printf "%0*d" ${#TotalParticipants} ${namenumbers[$i]})
    # Print all columns of the current row
    Add-Column "$salutation"
    Add-Column "$title"
    Add-Column "${firstname}${tmp}"
    Add-Column "${lastname}${tmp}"
    Add-Column "$title2"
    Add-Column "$acountname"
    Add-Column "$address"
    Add-Column "$mobilenumber"
    Add-Column "${lastname}${tmp}$email"
    Add-Column "$enroldate"
    Add-Column "$fieldofstudy"
    Add-Column "${ids[$i]}"
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
for (( i=0; i<$TotalParticipants; i+=members ))
do
    rand=$(( $RANDOM % 100 ))
    if [[ $rand -lt 10 ]]; then
        members=4
    elif [[ $rand -lt 25 ]]; then
        members=3
    else
        members=2
    fi
    groupList+=($members)
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
dateidx=($(shuf -i 0-${length} -n ${#groupList[@]} | sort -n))
# Get a list of indices to access the participant ids
length=${#ids[@]}
((length-=1))
idsidx=($(shuf -i 0-${length} -n $TotalParticipants))

# Add a row to the csv for each group
start=0
end=0
for (( i=0; i<${#groupList[@]}; i++ ))
do
    # Assign a random tutornumber
    tutor=$(( $RANDOM % $tutorcount + 1 ))
    Add-Column "$tutor"
    # Add groupnumber
    Add-Column "$i"
    # Add date for the group, the dates are sorted
    idx=${dateidx[$i]}
    Add-Column "${dateList[$idx]}"

    # For each participant of this group add the part-number and the drop-number
    partarray=""
    droparray=""
    start=$end
    ((end+=${groupList[$i]}))
    for (( j=start; j<end; j++ ))
    do
        idx=${idsidx[$j]}
        partarray+="${ids[$idx]}"
        # Add a random number to indicate if the participant droped out and during which sheet
        rand=$(( $RANDOM % 100 ))
        if [[ $rand -lt 10 ]]; then
            sheet=$(( $RANDOM % $sheets ))
            droparray+="$sheet"
        elif [[ $rand -lt 20 ]]; then
            sheet=$(( $RANDOM % $sheets ))
            droparray+="-$sheet"
        else
            # Participant did not drop out and was part of this group from the beginning
            droparray+="0"
        fi
        if [[ $j -lt $end-1 ]]; then
            partarray+=","
            droparray+=","
        fi
    done
    Add-Column "{${partarray[@]}}"
    Add-Column "{${droparray[@]}}"
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
        index=$(( $RANDOM % ${#taskcoloptions[@]} ))
        Add-Column "${taskcoloptions[$index]}"
    else
        index=$(( $RANDOM % ${#taskrowoptions[@]} ))
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
    '\\begin{itemize}\item Topic 1\item Topic 2\\end{itemize}'
    '\\textbf{Text 1}'
    '\\textcolor{javapurple}{Text 2}'
    "Text [3]"
    "Text 4,5"
    "Text $\sqrt{6}$"
    'Explanation 2a\\newline Explanation( 2b'
    'Explanation $[3 + 3]$\\newline $\Rightarrow$ Explanation) 3'
)

# Generate as many sheets as defined
for (( s=1; s<=$sheets; s++ ))
do
    # Create name and push header to the file
    FileName="./$TgtFolder/sheet_0$s.csv"
    printf "taskid; title; points; description;\n" >> $FileName

    subtasks=0
    # List of integers specifying the number of subtasks for each task
    taskList=()
    # Fill the tasklist with pseudo random values
    for (( i=0; i<$TotalTasks; i+=subtasks ))
    do
        rand=$(( $RANDOM % 100 ))
        if [[ $rand -lt 30 ]]; then
            subtasks=4
        elif [[ $rand -lt 70 ]]; then
            subtasks=3
        elif [[ $rand -lt 80 ]]; then
            subtasks=2
        else
            subtasks=1
        fi
        taskList+=($subtasks)
    done

    # Generate each task with the definied number of subtasks
    for (( i=0; i<${#taskList[@]}; i++ ))
    do
        # List of integers specifying the points for each subtasks
        subpoints=($(shuf -i 1-4 -n ${taskList[i]} -r))
        # Sum the subtaskpoints
        sumpoints=0
        for val in ${subpoints[@]}; do
            ((sumpoints+=$val))
        done

        # Add columns for taskid, title and points
        ipo=$(($i+1))
        Add-Column "$ipo"
        Add-Column "Assignment $ipo"
        Add-Column "$sumpoints"
        # Add the description column with value dependent on the column type
        # and the number of subtasks.
        if [[ $taskcols -eq 1 ]]; then
            if [[ ${taskList[i]} -gt 1 ]]; then
                Add-Column "Sum"
            else
                Add-Column "Result"
            fi
        else
            if [[ ${taskList[i]} -gt 1 ]]; then
                Add-Column ""
            else
                # Select a random predefined description
                index=$(( $RANDOM % ${#taskrowoptions[@]} ))
                Add-Column "Description ${taskrowoptions[$index]}"
            fi
        fi
        printf "\n" >> $FileName

        # Add subtasks if there are any
        if [[ ${taskList[i]} -gt 1 ]]; then
            idx=0
            for (( j=0; j<${taskList[$i]}; j++ ))
            do
                # If taskcolumns are enabled randomly use the -1, ... subfix
                if [[ $taskcols -eq 1 ]]; then
                    rand=$(( $RANDOM % 100 ))
                    if [[ $rand -lt 15 ]]; then
                        Add-Subtaskrow "-1"
                        Add-Subtaskrow "-2"
                        Add-Subtaskrow "-3"
                        ((j+=2))
                    elif [[ $rand -lt 30 ]]; then
                        Add-Subtaskrow "-1"
                        Add-Subtaskrow "-2"
                        ((j++))
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
done

###################################################################################################
# sheet_01_points.csv
###################################################################################################
# TODO
# Generate random points file

# $SHELL

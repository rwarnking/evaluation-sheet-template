#!/bin/bash
TgtFoler="2018_example-coursename-3"
TotalParticipants=30
sheets=4
tutorcount=2
# The seperator
sep=";";

# Helper function to add one column value to the csv
function Add-Column {
    printf "$1$sep" >> $FileName
}

###################################################################################################
# participants.csv
###################################################################################################
FileName="participants.csv"

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
FileName="groups.csv"
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
# sheet_01.csv
###################################################################################################
# TODO
# Generate random sheet file

###################################################################################################
# sheet_01_points.csv
###################################################################################################
# TODO
# Generate random Group file
# Generate random points file

# $SHELL

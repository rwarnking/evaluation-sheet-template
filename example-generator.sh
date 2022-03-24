#!/bin/bash
ParticipantsFileName="participants.csv"
TotalParticipants=10
# The seperator
sep=";";

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

# Helper function to add one column value to the csv
function Add-Column {
    printf "$1$sep" >> $ParticipantsFileName
}

# Print header
printf "Anrede;Titel;Vorname;Nachname;Titel2;" >> $ParticipantsFileName
printf "Nutzernamen;Privatadr;Privatnr;E-Mail;Anmeldedatum;" >> $ParticipantsFileName
printf "Studiengaenge;Matrikelnr;Bemerkung\n" >> $ParticipantsFileName

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
    index=$(( $RANDOM % 20 ))
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
    printf "\n" >> $ParticipantsFileName
done

# TODO
# Generate random Group file
# Generate random points file
# Generate random sheet file

# $SHELL

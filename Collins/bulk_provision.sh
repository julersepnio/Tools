#!/bin/bash

#-------------------------------------------
# Bulk Provisioning Script
# Version 1
# 
# Author: Juler John A Sepnio
#
# Description:
#      This loops the provision.sh script
# This scripts also needs a file that contains
# the asset tags. The [START LINE] and [END LINE]
# are specified to prevent DOS to the Collins
# Server.
#
#-------------------------------------------
# 
# Note:
#     Should be in the same directory with
# the provision.sh script
#
#     Please refer to Collins Documentation
#     https://tumblr.github.io/collins/
#-------------------------------------------
#
# Usage:
#
#     bulk_provision.sh [START LINE] [END LINE] [FILE] [PROFILE]

# Variables:
start_line=$1
end_line=$2
file=$3
profile=$4
tmpFile="/tmp/OngoingProvision"

echo "========== Installation Request for Nodes ${start_line} to ${end_line} Starting =========="

echo -e "Generating the Batch of Asset File...\n"

awk "NR >= $start_line; NR == $end_line {exit}" $file > $tmpFile

echo -e "Commencing Provision...\n"

while read tag; do
	echo -e "Doing Asset ${tag} ****************************************************************\n\n"
	./provision.sh $tag $profile
	echo -e "Request for Asset ${tag} Complete,.. Sleeping for moment\n\n"
	sleep 25
done < $tmpFile

echo "========== Installation Request for Nodes ${start_line} to ${end_line} Complete =========="

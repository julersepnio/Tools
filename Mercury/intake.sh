#!/bin/bash

# ------------------------------------------------------------
#
# Collins Asset Intake for Specifc IP Allocation Script
# Version 1
#
# Author: Juler John A Sepnio
#
# Description: 
#     When Collins doing asset intake, it is recommended
# to power up the nodes/servers one at a time to allocate
# specific IP address for its IPMI.
#     This script helps increase the speed of asset intake
# by powering the nodes up and then adding an 
# RACK_POSITION_INFO to the node attribute for host naming.
#
# ------------------------------------------------------------
#
# Logic:
# 
#     1. Get the Current IP's allocated to the nodes then
#        save it into a temporary file.
#   
#     2. Monitor the IP's to the nodes for changes.
#     
#     3. Take note of the IP that changed. Get the new
#        IP for the IPMI and search the asset tag in the
#        Collins DB.
#     
#     4. Add RACK_POSITION_INFO Attribute in the corresponding
#        asset.
#
# -------------------------------------------------------------
#
# Usage:
#
#     ./intake.sh [CMM IP] [Board Number to intake] [RACK_POS_INFO]
# 
# -------------------------------------------------------------
#
# Variables:
CMM_HOST=$1		# IP of the CMM Host
BOARD=$2		# Board/Node Number to intake
RACK_POS=$3		# Corresponding RACK_POSITION_INFO of the board
DEBUG=$4		# Debug Mode

BOLD=`tput bold`	# Set Text to Bold
NORMAL=`tput sgr0`	# Set Text to Normal
REV=`tput rev`		# Set Reverse Video

oldIPTempFile=/tmp/intake_$BOARD.oldIP 	# Temp File for old IP
newIPTempFile=/tmp/intake_$BOARD.newIP 	# Temp File for new IP

oldIP=0.0.0.0		# Old IPMI IP set by dhcp
newIP=0.0.0.0		# New IPMI IP set by the CMDB

lineNum=`tput lines`

CMDB_HOST="10.0.0.2"
CMDB_PORT="8080"
CMDB_USER="admin"
CMDB_PASS="collins123"
CMDB_HEAD="Accept:text/x-shellscript"

ASSET_TAG="XXXXXXXXXXXXX"
#
# -------------------------------------------------------------
#
# FLAGS:
cmm_reachable=0
node_power_on=0
ip_not_changed=true
ip_change_counter=0
ip_check_counter=0
set_asset_counter=0
curl_return_code=0
# -------------------------------------------------------------
#
# Functions:
#
# Display Status on Banner
function displayStatus {
	tput sc
	tput cup 25 0; tput el; echo -n "${REV}[${BOLD}STATUS: ${NORMAL}${REV} ${1}]${NORMAL}"
	tput rc
}

# Display Arguments Function
function displayArgs {
	echo -e "\n\n=============OPERATION VARIABLES============"
	echo "CMM HOST:       $BOLD ${CMM_HOST} $NORMAL"
	echo "Node to intake: $BOLD ${BOARD} $NORMAL"
	echo "Rack Position:  $BOLD ${RACK_POS} $NORMAL"
	echo -e "============================================\n"
}

# Check Connectivity to Host
function checkHost {
	echo "=======Checking $1 for Connectivity======="
	ping -c 1 $2 >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "[   OK   ] :: ${2} is reachable"
		echo -e "============================================\n"
		return 0
	else
		echo "[ FAILED ] :: ${2} unreachable"
		echo -e "============================================\n"
		sleep 1
		return 1
	fi
}

# Get the Current IPMI IP of the Node X 
function getNodeIP {
	`pwd`/mng_niclist -I $CMM_HOST -C $BOARD | awk 'NR>2 {print $4}' > $1
	sleep 5
}

# Check Node ip powered on
function checkNodePower {
	if [ $(ipmitool -I lanplus -U Administrator -P Administrator -H $1 power status | awk '{print $4}') == "on" ]; then
		node_power_on=1
	else
		node_power_on=0
	fi

}

# Get the Asset Tag
function getAsset {
	GET_ASSET_URL="http://${CMDB_HOST}:${CMDB_PORT}/api/assets?attribute=IPMI_ADDRESS%3B${1}"
	ASSET_TAG=$(curl -s -H $CMDB_HEAD --basic -u $CMDB_USER:$CMDB_PASS $GET_ASSET_URL | grep IPMI_ASSET_TAG | awk -F "=" '{ print $2 }')	
	sleep 10
	ASSET_TAG=${ASSET_TAG//;}
	ASSET_TAG="${ASSET_TAG%\"}"
	ASSET_TAG="${ASSET_TAG#\"}"
}

# Check Asset Tag
function checkAsset {
	CHECK_ASSET_URL="http://${CMDB_HOST}:${CMDB_PORT}/api/assets?attribute=IPMI_ADDRESS%3B${1}"
	curl_return_code=$(curl --basic -u $CMDB_USER:$CMDB_PASS --write-out %{http_code} -s $CHECK_ASSET_URL)

	# FOR TEST PURPOSES ONLY
	#CHECK_ASSET_URL="google.com"
	#curl_return_code=$(curl --write-out %{http_code} -s -o /dev/null $CHECK_ASSET_URL)
}

# Set the Asset RACK POSITION INFO
function setAsset {
	SET_ASSET_URL="http://${CMDB_HOST}:${CMDB_PORT}/api/asset/${1}"
	SET_ASSET_DATA="attribute=RACK_POSITION_INFO;${2}"
	curl_return_code=$(curl --basic -u ${CMDB_USER}:${CMDB_PASS} --write-out %{http_code} -s --data-urlencode $SET_ASSET_DATA $SET_ASSET_URL)
}

# -------------------------------------------------------------
#
# Main Logic Sequence
#
# Clear the Screen
clear

# Display the Argument Supplied then wait
displayStatus "Displaying arguments..." 
sleep 1 
displayArgs
sleep 1

# Check the Connectivity of the CMM HOST
displayStatus "Checking CMM Host for Connectivity..." 
checkHost CMM $CMM_HOST

# Get the Current IPMI of the Board and save in a temp file
displayStatus "Initializing Temp Files..."
getNodeIP $oldIPTempFile
oldIP=`cat ${oldIPTempFile}`

# Initialize the New IPMI Temp file
newIP=$oldIP
echo $newIP > $newIPTempFile

# Power up the Node
displayStatus "Powering Node ${BOARD}..."
echo -e "===============POWER STATUS================="

ipmitool -I lanplus -U Administrator -P Administrator -H ${oldIP} power on
sleep 5

# Check the Node Status
displayStatus "Checking Node ${BOARD} if up..."
checkNodePower ${oldIP}
if [ $node_power_on -eq 1 ]; then	
	echo "[   OK   ] :: Node is powered up"
	echo -e "============================================\n"
	sleep 5
else
	echo "[ FAILED ] :: Node  failed to power up"
	echo -e "============================================\n"
	exit 1
fi

# Wait for the CMDB to allocate the new address to the node
while [ $oldIP == $newIP ];do
	getNodeIP $newIPTempFile

	# FOR TEST PURPOSES ONLY
	#if [ $ip_change_counter -eq "10" ]; then
	#	newIP=10.0.0.2
	#fi

	newIP=`cat $newIPTempFile`
	displayStatus "Waiting for the new IP address ($ip_change_counter)"
	echo -e "=================IP MONITOR================="
	echo "Current IP: ${oldIP}"
	ip_change_counter=$(($ip_change_counter+5))
	echo "New IP:     ${newIP}"
	echo -e "============================================\n"
	tput sc
	tput cuu 5
	sleep 1
done
tput rc
displayStatus "New IP address allocated..."
sleep 3

clear
# Check whether the new IP Address is reachable
displayStatus "Checking the new IP address..."
checkHost "${newIP}" "${newIP}"

# If IP check failed, re-fetch the new IP
while ! ping -c 1 ${newIP} >/dev/null 2>&1 ; do
	getNodeIP $newIPTempFile
	newIP=`cat ${newIPTempFile}`

	# FOR TEST PURPOSES ONLY
	#if [ $ip_check_counter == "3" ];then
	#	newIP=208.67.222.222
	#fi
	ip_check_counter=$(($ip_check_counter+1))
	displayStatus "Checking the new IP (${ip_check_counter})"
done
	
displayStatus "New IP is now reachable..."
tput cuu 7; tput el; echo "New IP:     ${newIP} >> Replaced"
echo -e "============================================\n"
tput ed
checkHost "NODE" "${newIP}"
sleep 1

# Get the ASSET TAG
displayStatus "Getting the Asset Tag for ${newIP}"
getAsset ${newIP}
echo "====================ASSET==================="
echo "Board:    ${BOARD}"
echo "IP:       ${newIP}"
echo "Tag:      ${ASSET_TAG}"
echo "Position: ${RACK_POS}"
echo -e "============================================\n"

# Check the Asset
#set -x
displayStatus "Checking if ${ASSET_TAG} exists..."
checkAsset $ASSET_TAG
echo "CHECK Return Code: ${curl_return_code}"
sleep 3
setAsset $ASSET_TAG $RACK_POS
echo "SET Return Code: ${curl_return_code}"
#while [ $curl_return_code -ne "200" ]; do
#	displayStatus "Asset ${ASSET_TAG} not set... Retrying ${set_asset_counter}"
#	echo "Return Code: ${curl_return_code} | Asset ${ASSET_TAG} not set... Retrying ${set_asset_counter}"
#	sleep 1
#	setAsset ${ASSET_TAG} ${RACK_POS}
#	tput cuu 1
	# FOR TEST PURPOSES ONLY
	#set_asset_counter=$(($set_asset_counter+1))
	#if [ $set_asset_counter -eq "5" ]; then
	#	curl_return_code=200;
	#fi
#done
#tput el; echo "Return Code: ${curl_return_code}"

# Display Status To Finished
rm $oldIPTempFile
rm $newIPTempFile
displayStatus "Asset Intake for Node ${BOARD} Finished"
tput el; echo "===================END======================"
exit 0


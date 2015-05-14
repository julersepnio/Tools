#!/bin/bash

#-------------------------------------------
# Provisioning with Expect Feat. Script
# Version 1
# 
# Author: Juler John A Sepnio
#
# Description:
#      When running the provision_base.sh, 
# the prompt would ask if you are sure about
# provisioning the profile to the asset.
#     The Expect feature has been added to
# this script to automate the response to
# the prompt.
#
#-------------------------------------------
# 
# Note:
#     Should be in the same directory with
# the provision_base.sh script
#
#     Please refer to Collins Documentation
#     https://tumblr.github.io/collins/
#-------------------------------------------
#
# Usage:
#
#     provision.sh [ASSET TAG] [PROFILE]

#Variables
asset=$1
profile=$2


/usr/bin/expect << EOD 
set timeout -1
spawn /Users/julersepnio/Github/Tools/Collins/provision_base.sh $asset $profile

expect {
	"*ARE YOU SURE?"
}
sleep 2
send "yes\r"
expect eof
EOD
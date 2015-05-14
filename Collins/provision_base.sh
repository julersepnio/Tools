#!/bin/bash

#-------------------------------------------
# Base Provision Script
# Version 1
# 
# Author: Juler John A Sepnio
#
# Description:
#
#     This is a cmd implementation of 
# provisioning an asset in Collins.
#
#-------------------------------------------
# 
# Note:
#
#     Please refer to Collins Documentation
#     https://tumblr.github.io/collins/
#-------------------------------------------
#
# Usage:
#
#     provision_base.sh [ASSET TAG] [PROFILE]

# Variables:
asset=$1
profile=$2

# collins-shell provision host [ASSET] [PROFILE] [CONTACT]
# [PROFILE] should be check with the specific Collins Environment
collins-shell provision host $asset $profile jsepnio@agsx.net

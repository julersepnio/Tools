#!/bin/bash

#-------------------------------------------
# Set to Maintenance Script
# Version 1
# 
# Author: Juler John A Sepnio
#
# Description:
#      When doing OS Re-installation, the 
# asset has to be in Maintenance Status.
# This script sets the specified asset to
# maintenance.
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
#     setToMaintenance.sh [ASSET TAG]

# Variables:
asset=$1

# collins-shell asset set_status --reason=[SOME REASON] --state=[SOME STATE] --status=[SOME STATUS] --tag [ASSET]
# --state and --status should be checked with the corresponding Collins Environment
collins-shell asset set_status --reason="OS Reinstall" --state="MAINT_NOOP" --status="Maintenance" --tag $asset

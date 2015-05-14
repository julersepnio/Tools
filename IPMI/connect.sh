#!/bin/bash

ipmitool -U Administrator -P Administrator -I lanplus -H $1 sol activate

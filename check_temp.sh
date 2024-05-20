#!/bin/bash

ip="$1"

ssh "$ip" 'export cpu=$(</sys/class/thermal/thermal_zone0/temp); echo "$((cpu/1000)) c"'

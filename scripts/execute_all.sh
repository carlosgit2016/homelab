#!/bin/bash

ips=(192.168.15.20 192.168.15.21 192.168.15.22)

for ip in "${ips[@]}"; do
	ssh "$ip" "sudo bash -c \"$@\""
done

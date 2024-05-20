#!/bin/bash

ips=(192.168.1.9 192.168.1.11 192.168.1.12)

for ip in "${ips[@]}"; do
	ssh "$ip" "sudo bash -c $@"
done

#!/bin/bash

ip="$1"
gtw="192.168.1.1"
dns="8.8.8.8 8.8.4.4"

nmcli c mod "Wired connection 1" ipv4.address "$ip/24" ipv4.gateway "$gtw" ipv4.dns "$dns" ipv4.method manual

#!/bin/bash

SURVIVAL_DIR="/opt/minecraft/smp" # Directory for the survival server

WHITELISTED_USERS=$(jq .[].name "$SURVIVAL_DIR/whitelist.json" | cut -d\" -f2)

for user in $WHITELISTED_USERS; do
    SERVERS="cmp mirror"
    # This for loop is coded in a way where the other servers reside under the same parent directory
    for server in $SERVERS; do
    	IS_WHITELISTED=$(grep "$user" "/opt/minecraft/$server/whitelist.json")
    	if [ -n "$IS_WHITELISTED" ]; then
    		continue
    	fi
    	echo "$user $server"
    	echo "op $user" > /run/"$server".stdin
    	echo "whitelist add $user" > /run/"$server".stdin
    done
done

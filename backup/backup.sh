#!/bin/bash
backup_dir="$HOME/backups"

mkdir -p "$backup_dir"

servers="smp cmp mirror velocity"
for server in $servers; do
    echo "Backing up $server.."
    
    # Announce that the backup job is starting, incase server perf degrades
    msg=$(jq -cnR '. = { "text": "\u00a75[Hourly Backup] \u00a7dStarting job", "bold": true }')
    echo "tellraw @a $msg" > /run/$server.stdin
    SECONDS=0 
    # Create backup dir incase it doesn't exist
    mkdir -p "$backup_dir/$server"
    # Create the archive but exclude the entire bluemap directory, since it's quite large and mostly a dupe of the world
    archive=$(date -u +%Y-%m-%dT%H:%M:%S)
    tar cfz "$backup_dir/$server/$archive.tar.zst" -C "$HOME/$server" --exclude "./bluemap" .
    
    # Announce once the world is backed up
    msg=$(jq -cnR '. = { "text": "\u00a75[Hourly Backup] \u00a7dFinished job in $s seconds", "bold": true }' --arg s "$seconds")
    echo "tellraw @a $msg" > /run/$server.stdin
    
    echo "Finished backing up $server.."
    # Delete old backups
    total_backups=$(find "$backup_dir/$server/*" | wc -l)
    if [ $total_backups -gt 48 ]; then
        backups_to_delete=$(ls -Art "$backup_dir/$server" | head -n $(( $total_backups - 48 )))
        echo "Found $($backups_to_delete | wc -l) backups to delete.."
        rm $backups_to_delete
    fi
done

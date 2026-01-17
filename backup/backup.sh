#!/bin/bash
# Backup script for minecraft servers running through systemd with stdin sockets
# Assumes directory name is the same as systemd name
# Written by: AI-nsley69
# Dependencies: jq

# Crontab entry, under the user running the servers:
# 0 * * * * path_to_script/backup.sh

backup_dir="$HOME/backups" # Where to copy backups, can be used by mounting remote target to location
mc_parent_dir="$HOME" # Location for minecraft servers
retention_hours="24" # How long to keep hourly backups

# Try to create the backup location incase it doesn't exist
mkdir -p "$backup_dir"

# Name of servers, should be the same as systemd name
servers="smp cmp mirror velocity"
for server in $servers; do
    # Skip inactive servers, incase a recovery is ongoing
    # Changes should not be possible at this stage, and current backups will still be available
    # If it continues, cronjob will hang until socket is backup
    IS_ACTIVE=$(systemctl is-active "$server")
    if [ IS_ACTIVE != "active" ]; then
        echo "Skipping $server because it's offline"
        continue
    fi

    echo "Backing up $server.."

    # Announce that the backup job is starting, incase server perf degrades
    msg=$(jq -cnR '. = { "text": "\u00a75[Hourly Backup] \u00a7dStarting job", "bold": true }')
    echo "tellraw @a $msg" > /run/$server.stdin
    SECONDS=0

    # Create backup dir incase it doesn't exist
    mkdir -p "$backup_dir/$server"

    # Create the archive but exclude the entire bluemap directory, since it's quite large and mostly a dupe of the world
    archive=$(date -u +%Y-%m-%dT%H:%M:%S)
    tar cfz "$backup_dir/$server/hourly_$archive.tar.zst" -C "$mc_parent_dir/$server" --exclude "./bluemap" .

    # Announce once the world is backed up
    msg=$(jq -cnR '. = { "text": "\u00a75[Hourly Backup] \u00a7dFinished job in \($s) seconds", "bold": true }' --arg s "$seconds")
    echo "tellraw @a $msg" > /run/$server.stdin

    echo "Processing retention for $server.."
    # Delete backups older than retention date
    current_dir="$PWD"
    cd $backup_dir/$server
    total_backups=$(ls | grep hourly | wc -l)
    if [ $total_backups -gt $retention_hours ]; then
        backups_delete_count=$(( $total_backups - $retention_hours ))
        backups_to_delete=$(ls -Art | grep hourly | head -n $backups_delete_count )
        echo "Found $backups_delete_count backups to delete.."
        rm $backups_to_delete
    fi

    echo "Processing weekly backup for $server.."
    # Check weekly backups
    weekly_backup=$(ls | grep weekly | head -n 1)
    # Set hourly backup to current weekly if it doesn't exist
    if [ "$weekly_backup" == "" ]; then
        cp "hourly_$archive.tar.zst" "weekly_$archive.tar.zst"
    fi
    weekly_date_str=$($weekly_backup | cut -d"_" -f1 | cut -d"T" -f1)
    weekly_days_diff=$(( ((date -u +%s) - $(date -d weekly_date_str +%s)) / (60*60*24) ))
    # Check if weekly is >= 7 days old, if so, replace it with the current backup
    if [ $weekly_days_diff -ge 7 ]; then
        rm $weekly_backup
        cp "hourly_$archive.tar.zst" "weekly_$archive.tar.zst"
    fi

    echo "Processing monthly backup for $server.."
    # Check monthly backups
    monthly_backup=$(ls | grep monthly | head -n 1)
    # Set hourly backup to current monthly if it doesn't exist
    if [ "$monthly_backup" == "" ]; then
        cp "hourly_$archive.tar.zst" "monthly_$archive.tar.zst"
    fi
    monthly_date_str=$($weekly_backup | cut -d"_" -f1 | cut -d"T" -f1)
    monthly_days_diff=$(( ((date -u +%s) - $(date -d weekly_date_str +%s)) / (60*60*24) ))
    # Check if monthly is >= 30 days old, if so, replace it with the current backup
    if [ $monthly_days_diff -ge 30 ]; then
        rm $monthly_backup
        cp "hourly_$archive.tar.zst" "monthly_$archive.tar.zst"
    fi

    echo "Finished backing up $server!"

    # Return to the original directory when done
    cd $current_dir
done

# Backup

Simple script that's installed as cronjob to take a backup every hour

Backups are only kept for 48 hours, then the oldest ones are deleted

This takes a backup of every server directory, in our case we exclude the bluemap directory, since it includes essentially just a processed copy of the world


# Crash Detector
Crash detector is a small wrapper script that runs the `fabric-server-launch.jar` file. 

It detects whenever the server has a non-zero exit code and proceeds to get the latest stacktrace and post it to a discord webhook.

This script depends on the `jq` command and requires a minor amount of configuration in terms of the variables at the top of the script. 
Besides that, substituting your current start script/way of running the server with this script should suffice.

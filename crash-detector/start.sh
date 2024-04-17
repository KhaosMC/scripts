#!/bin/bash
# Small bash script to detect crashes for a minecraft server
# By: Trainsley69 & Silversquirl
# Dependencies: jq

memory="8G" # Defines memory usage for the mc server
discord_webhook="https://discord.com/api/webhooks/{channel.id}/{webhook.token}" # Webhook to the channel you wish to send the crash detect to
server="Server name" # Name of the server, used for stating the name of the server dying
java_bin="/usr/bin" # Path for the java binary location, useful for when java is not in any default path like with sdkman

run_server () {
    "$java_bin"/java -jar -Xms"$memory" -Xmx"$memory" fabric-server-launch.jar
}

get_total_crashes () {
    if [ ! -d "./crash-reports" ]; then
        total_crashes="0"
        return
    fi

    total_crashes="$(ls ./crash-reports | wc -l)"
}

get_description () {
    file=$(ls -Art crash-reports | tail -n 1)
    crash_description=$(grep "Description:" "crash-reports/$file" | cut -d: -f2)
}

get_stacktrace () {
    while read -r line; do
      case "$line" in
          'Description:'*) ok=1;;
          'A detailed walkthrough'*) break;;
          *) [ -n "$ok" ] && printf '%s\n' "$line";;
      esac
    done <"crash-reports/$file"

}

post_webhook () {
    title="$server crash #$total_crashes"
    color="16711680" # Red
    echo "$crash_description"
    description="Error: $crash_description \`\`\`$stacktrace\`\`\`"
    webhook_content=$(jq -cnR '.embeds[0] = { title: $t, color: $c, description: $d}' --arg t "$title" --arg c "$color" --arg d "$description" )
    curl -i -H "Accept: application/json" -H "Content-Type: application/json" -X POST --data-raw "$webhook_content" "$discord_webhook"
}

run_server
exit_code=$?
if [ $exit_code -eq 0 ]; then
    exit $exit_code
fi

# Gather information about the crash
get_total_crashes
get_description
stacktrace=$(get_stacktrace | head -n 10)
post_webhook
exit $exit_code

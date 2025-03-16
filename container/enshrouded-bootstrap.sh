#!/bin/bash
# enshrouded-bootstrap runs and prepares the 
# system based on environment variables.

# Include defaults
. /home/steam/defaults.sh
. /home/steam/common.sh


# Update server status before anything else
update_server_status bootstrapping

# Create paths
mkdir -p "${enshrouded_download_path}"
mkdir -p "${enshrouded_log_path}"
mkdir -p "${enshrouded_savegame_path}"


# Check that log file exists, if not create
if ! [ -f "${enshrouded_log_path}/enshrouded_server.log" ]; then
    touch "${enshrouded_log_path}/enshrouded_server.log"
fi

# Modify server config to match our arguments
if [ $EXTERNAL_CONFIG -eq 0 ]; then
    info "Updating Enshrouded Server configuration"

    # Copy example server config if not already present
    if ! [ -f "${ENSHROUDED_PATH}/enshrouded_server.json" ]; then
        info "Enshrouded server config not present, copying example"
        cp /home/steam/enshrouded_server_example.json ${ENSHROUDED_PATH}/enshrouded_server.json
    fi

    tmpfile=$(mktemp)
    jq --arg n "$SERVER_NAME" '.name = $n' ${ENSHROUDED_CONFIG} > "$tmpfile" && mv "$tmpfile" $ENSHROUDED_CONFIG
    if [ -n "$SERVER_PASSWORD" ]; then
        jq --arg p "$SERVER_PASSWORD" '.userGroups[].password = $p' ${ENSHROUDED_CONFIG} > "$tmpfile" && mv "$tmpfile" $ENSHROUDED_CONFIG
    fi
    jq --arg g "$GAME_PORT" '.gamePort = ($g | tonumber)' ${ENSHROUDED_CONFIG} > "$tmpfile" && mv "$tmpfile" $ENSHROUDED_CONFIG
    jq --arg q "$QUERY_PORT" '.queryPort = ($q | tonumber)' ${ENSHROUDED_CONFIG} > "$tmpfile" && mv "$tmpfile" $ENSHROUDED_CONFIG
    jq --arg s "$SERVER_SLOTS" '.slotCount = ($s | tonumber)' ${ENSHROUDED_CONFIG} > "$tmpfile" && mv "$tmpfile" $ENSHROUDED_CONFIG
    jq --arg i "$SERVER_IP" '.ip = $i' ${ENSHROUDED_CONFIG} > "$tmpfile" && mv "$tmpfile" $ENSHROUDED_CONFIG
else
    info "EXTERNAL_CONFIG set to true, not updating Enshrouded Server configuration"
fi

# Create crontabs
crontab=$(mktemp)

if [ -n "$UPDATE_CRON" ]; then
    debug "Creating cron to check for updates using schedule $UPDATE_CRON"
    echo "$UPDATE_CRON [ -f \"$enshrouded_updater_pidfile\" ] && kill -HUP \$(cat $enshrouded_updater_pidfile)" >> "$crontab"
fi

if [ -n "$RESTART_CRON" ]; then
    debug "Creating cron to restart enshrouded-server using schedule $RESTART_CRON"
    if [ "$RESTART_IF_IDLE" = true ]; then
        echo "$RESTART_CRON $cmd_enshrouded_is_idle && $cmd_supervisorctl restart enshrouded-server" >> "$crontab"
    else
        echo "$RESTART_CRON $cmd_supervisorctl restart enshrouded-server" >> "$crontab"
    fi
else
    debug "Environment variable RESTART_CRON is empty - no automatic enshrouded-server restart scheduled"
fi
crontab "$crontab"
rm -f "$crontab"

# Start enshrouded-logs to print the Enshrouded logs to stdout for Docker/k8s
supervisorctl start enshrouded-logs

# Start enshrouded-updater to update or install Enshrouded
supervisorctl start enshrouded-updater

exit 0

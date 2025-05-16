#!/bin/bash
# enshrouded-updater.sh runs on startup and
# periodically checks for server updates.
# It is also responsible for (re)starting
# the enshrouded-server service.

# Include defaults
. /home/steam/defaults.sh
. /home/steam/common.sh

debug "Running Enshrouded updater as user $USER uid $UID"
cd /home/steam || fatal "Could not cd /home/steam"
pidfile=$enshrouded_updater_pidfile
next_update=$(date +%s)
run=true


main() {
    if (set -o noclobber; echo $$ > "$pidfile") 2> /dev/null; then
        trap update_now SIGHUP
        trap shutdown SIGINT SIGTERM
        trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]}); trap - ERR' ERR
        while [ $run = true ]; do
            update
            check_server_restart
            next_update=$(($(date +%s)+UPDATE_INTERVAL))
            while [ $run = true ] && [ "$(date +%s)" -lt $next_update ]; do
                sleep 2
            done
        done
    else
        info "Found existing PID file - checking process"
        check_lock $pidfile
    fi
}


update() {
    local logfile
    if ! is_idle; then
        return
    fi
    logfile="$(mktemp)"
    info "Downloading/updating/validating Enshrouded from Steam"
    if ! download_enshrouded; then
        if [ -f "$enshrouded_server" ]; then
            error "Failed to update Enshrouded server from Steam - however an existing version was found locally - using it"
        else
            error "Failed to download Enshrouded server from Steam - retrying later - check your networking and volume access permissions"
            return
        fi
    fi
    rsync --checksum --recursive --itemize-changes --exclude server_exit.drp --exclude steamapps "$enshrouded_download_path/" "$enshrouded_install_path" | tee "$logfile"
    if grep '^[*>]' "$logfile" > /dev/null 2>&1; then
        info "Enshrouded was updated - restarting"
        write_restart_file updated
    else
        info "Enshrouded is already the latest version"
        if [ "$just_started" = true ]; then
            write_restart_file just_started
        fi
    fi
    just_started=false
    rm -f "$logfile"
}


download_enshrouded() {
    # Kill any hung steamcmd processes
    pkill -TERM steamcmd || true
    sleep 1
    pkill -KILL steamcmd || true
    if [ "${just_started}" = true ]; then
        # Run Steam updater to update the files in the install path
        info "Checking game installation in install path"
        ${STEAMCMD_PATH}/steamcmd.sh +@sSteamCmdForcePlatformType windows +force_install_dir "$enshrouded_install_path" +login anonymous +app_update ${STEAM_APP_ID} ${STEAMCMD_ARGS} +quit
    else
        # Run Steam updater to update the files in the download path
        info "Checking game installation in download path"
        ${STEAMCMD_PATH}/steamcmd.sh +@sSteamCmdForcePlatformType windows +force_install_dir "$enshrouded_download_path" +login anonymous +app_update ${STEAM_APP_ID} ${STEAMCMD_ARGS} +quit
    fi
}


check_server_restart() {
    local mode
    # The control file $enshrouded_restartfile is either created
    # by update() if Enshrouded is being installed for the first
    # time or has been updated.
    if [ -f "$enshrouded_restartfile" ]; then
        mode=$(< "$enshrouded_restartfile")
        rm -f "$enshrouded_restartfile"

        case "$mode" in
                start)
                    if server_is_running; then
                        debug "Enshrouded server is already running - no need to start it"
                        return
                    fi
                    ;;
                restart)
                    if ! server_is_running; then
                        mode=start
                    fi
                    ;;
                *)
                    mode=restart
        esac

        supervisorctl "$mode" enshrouded-server
    fi
}


is_idle() {
    if [ "$UPDATE_IF_IDLE" = true ]; then
        if [ "$just_started" = true ] && ! server_is_running; then
            debug "Enshrouded updater was just started - skipping connected players check"
            return 0
        fi
        if server_is_idle; then
            debug "No players connected to Enshrouded server"
            return 0
        else
            debug "Players connected to Enshrouded server - skipping update check"
            return 1
        fi
    fi
    return 0
}


# This is a signal handler registered to SIGHUP
update_now() {
    debug "Received signal to check for update"
    next_update=0
}


shutdown() {
    debug "Received signal to shut down enshrouded-updater"
    clear_lock "$pidfile"
    run=false
}


main

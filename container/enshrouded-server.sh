#!/bin/bash
# enshrouded-server starts the Enshrouded server

# Include defaults and common functions
. /home/steam/defaults.sh
. /home/steam/common.sh

enshrouded_server=${ENSHROUDED_PATH}/enshrouded_server.exe
enshrouded_server_pid=-1
timeout=10
kill_signal=TERM


cleanup() {
    if [ -n "${wait_for_server_listening_pid:-}" ] && [ -d "/proc/$wait_for_server_listening_pid" ]; then
        kill -TERM $wait_for_server_listening_pid
    fi
    clear_lock "$enshrouded_server_pidfile"
}


shutdown() {
    debug "Received signal to shut down enshrouded-server"
    update_server_status stopping
    if [ $enshrouded_server_pid -eq -1 ]; then
        debug "Enshrouded server is not running yet - aborting startup"
        update_server_status stopped
        exit
    fi
    info "Shutting down Enshrouded server with PID $enshrouded_server_pid"
    kill -INT $enshrouded_server_pid
    shutdown_timeout=$(($(date +%s)+timeout))
    while [ -d "/proc/$enshrouded_server_pid" ]; do
        if [ "$(date +%s)" -gt $shutdown_timeout ]; then
            shutdown_timeout=$(($(date +%s)+timeout))
            warn "Timeout while waiting for server to shut down - sending SIG$kill_signal to PID $enshrouded_server_pid"
            kill -$kill_signal $enshrouded_server_pid
            case "$kill_signal" in
                INT)
                    kill_signal=INT
                    ;;
                *)
                    kill_signal=KILL
            esac
        fi
        debug "Waiting for Enshrouded Server with PID $enshrouded_server_pid to shut down"
        sleep 6
    done
}


wait_for_process() {
    while [ -e /proc/$1 ]; do
        sleep 1
    done
}


wait_for_server_listening() {
    while :; do
        if server_is_listening; then
            update_server_status running
            debug "Server is now listening on UDP query port $QUERY_PORT"
            break
        else
            debug "Waiting for server to listen on UDP query port $QUERY_PORT"
            sleep 5
        fi
    done
}


main() {
    info "Running Enshrouded Server"
    debug "Server config is name: $SERVER_NAME, port: $QUERY_PORT/udp"
    update_server_status starting

    # Use GE-Proton to start Enshrouded server
    ${STEAMCMD_PATH}/compatibilitytools.d/GE-Proton${GE_PROTON_VERSION}/proton run ${ENSHROUDED_PATH}/enshrouded_server.exe &

    # Find pid for enshrouded_server.exe
    retry=0
    while [ $retry -lt 11 ]; do
        if ps -e | grep "enshrouded_serv"; then
            enshrouded_server_pid=$(ps -e | grep "enshrouded_serv" | awk '{print $1}')
            break
        elif [ $retry -eq 10 ]; then
            fatal "Timed out waiting for enshrouded_server.exe to be running"
            exit 1
        fi
        sleep 6
        ((retry++))
        info "Waiting for enshrouded_server.exe to be running"
    done

    echo $enshrouded_server_pid > "$enshrouded_server_pidfile"

    wait_for_server_listening &
    wait_for_server_listening_pid=$!

    wait_for_process $enshrouded_server_pid
    debug "Enshrouded server with PID $enshrouded_server_pid stopped"
    update_server_status stopped
    
    cleanup
    info "Shutdown complete"
    exit 0
}




trap shutdown INT TERM
main

#!/bin/bash
# enshrouded-bootstrap runs and prepares the 
# system based on environment variables.

# Include defaults
. /home/steam/defaults.sh
. /home/steam/common.sh

enshrouded_logs_pid=-1

trap shutdown SIGINT SIGTERM


main() {
    debug Starting enshrouded-logs
    print_enshrouded_logs
}


print_enshrouded_logs() {
    tail -F ${enshrouded_log_path}/enshrouded_server.log &
    enshrouded_logs_pid=$!
    wait_for_process $enshrouded_logs_pid
}


wait_for_process() {
    while [ -e /proc/$1 ]; do
        sleep 1
    done
}


shutdown() {
    debug "Received signal to shut down enshrouded-logs"
    kill -TERM $enshrouded_logs_pid
}

main

#!/bin/bash
# trap SIGUSR1 as it is being used to check
# for process aliveness when an existing
# pidfile is found
trap ':' USR1
just_started=${just_started:-true}

# We are creating the following directory structure
# /home/steam/
#         |__/enshrouded/                     <= Enshrouded game installation directory
#                    |__/logs/                <= logs directory
#                    |__/savegame/            <= save game directory
#         |__/enshrouded_download/            <= Steam download directory
#         |__/steamcmd/                       <= Steam installation directory
#                  |__/compatibilitytools.d/  <= GE-Proton installation directory
#
enshrouded_server=${ENSHROUDED_PATH}/enshrouded.exe     # Enshrouded server executable
enshrouded_download_path=${ENSHROUDED_PATH}_download    # Enshrouded server download directory
enshrouded_install_path=${ENSHROUDED_PATH}              # Enshrouded server installation directory
enshrouded_log_path=${ENSHROUDED_PATH}/logs             # Enshrouded server logs directory
enshrouded_savegame_path=${ENSHROUDED_PATH}/savegame    # Enshrouded server savegame directory
enshrouded_restartfile=/tmp/enshrouded.restart          # Signaling file created by enshrouded-updater
                                                        # that describes if/how to restart the server

# Collection of PID files

enshrouded_server_pidfile=${ENSHROUDED_PATH}/enshrouded-server.pid
enshrouded_updater_pidfile=${ENSHROUDED_PATH}/enshrouded-updater.pid

# Supervisor config files
supervisor_http_server_conf=/etc/supervisor/conf.d/http_server.conf

# Commands
cmd_enshrouded_is_idle=/home/steam/enshrouded-is-idle.sh
cmd_supervisord=/usr/bin/supervisord
cmd_supervisorctl=/usr/bin/supervisorctl

# Syslog supervisor config file
supervisor_syslog_conf=/etc/supervisor/conf.d/syslog.conf

# log levels
debug=50
info=40
warn=30
error=20
critical=10
fatal=5
log_level=${log_level:-$debug}


debug()    { logstd $debug    "DEBUG - [$$] - $*"; }
info()     { logstd $info     "INFO - $*"; }
warn()     { logstd $warn     "WARN - $*"; }
error()    { logerr $error    "ERROR - $*"; }
critical() { logerr $critical "CRITIAL - $*"; }
fatal()    { logerr $fatal    "FATAL - $*"; exit 1; }


logstd() {
    local log_at_level
    log_at_level="$1"; shift
    printline "$log_at_level" "$*"
}


logerr() {
    local log_at_level
    log_at_level="$1"; shift
    printline "$log_at_level" "$*" >&2
}


printline() {
    local log_at_level
    local log_data
    log_at_level="$1"; shift
    log_data="$*"

    if [ "$log_at_level" -le "$log_level" ]; then
        echo "$log_data"
    fi
}


_udp_datagram_count() {
    local datagram_count
    datagram_count="$(nstat | awk '/UdpInDatagrams/{print $2}' | tr -d ' ')"
    echo "${datagram_count:-0}"
}


server_is_idle() {
    local connection_count

    # Search the last 100 rows of the Enshrouded server logs to check
    # for active connections
    if [ -f "${enshrouded_log_path}/enshrouded_server.log" ]; then
        connection_count="$(tail -n 100 ${enshrouded_log_path}/enshrouded_server.log | grep -c ${ACTIVE_CONNECTIONS_REGEX})"
        if [ "${connection_count}" -eq "0" ]; then
            return 0
        else
            return 1
        fi
    else
        # Use nstat to count UDP datagrams to detect if users are connected.
        
        # Throw away datagram statistics since last run
        _udp_datagram_count &>/dev/null
        # Wait to track datagrams over window
        sleep "$IDLE_DATAGRAM_WINDOW"
        if [ "$(_udp_datagram_count)" -gt "$IDLE_DATAGRAM_MAX_COUNT" ]; then
            return 1
        else
            return 0
        fi
    fi
}


server_is_running() {
    test "$(supervisorctl status enshrouded-server | awk '{print $2}')" = RUNNING
}


server_is_listening() {
    # Check if server is listening on either server or query port
    awk -v game_port="$GAME_PORT" -v query_port="$QUERY_PORT" '
        BEGIN {
            exit_code = 1
        }
        {
            if ($1 ~ /^[0-9]/) {
                split($2, local_bind, ":")
                listening_port = sprintf("%d", "0x" local_bind[2])
                if (listening_port == game_port || listening_port == query_port) {
                    exit_code = 0
                    exit
                }
            }
        }
        END {
            exit exit_code
        }
    ' /proc/net/udp*
}


check_lock() {
    local pidfile
    local predecessor_pid
    local numre
    pidfile=$1
    predecessor_pid=$(<"$pidfile")
    numre='^[0-9]+$'
    if [[ "$predecessor_pid" =~ $numre ]] ; then
        debug "Sending SIGUSR1 to PID $predecessor_pid"
        if kill -USR1 "$predecessor_pid" &> /dev/null; then
            fatal "Process with PID $predecessor_pid already running - exiting"
        else
            info "Removing stale PID file and starting run"
            clear_lock_and_run "$pidfile"
        fi
    else
        warn "Predecessor PID is corrupt - clearing lock and running"
        clear_lock_and_run "$pidfile"
    fi
}


clear_lock_and_run() {
    local pidfile
    pidfile=$1
    clear_lock "$pidfile"
    main
}


clear_lock() {
    local pidfile
    pidfile=$1
    info "Releasing PID file $pidfile"
    rm -f "$1"
}


error_handler() {
    local ec
    local line_no
    local func_call_line
    local command
    local stack
    ec=$1
    line_no=$2
    func_call_line=$3
    command="$4"
    stack="$5"
    error "Error in line $line_no command '$command' exited with code $ec in $stack called in line $func_call_line"
    return "$ec"
}


write_restart_file() {
    local mode
    local reason
    reason=$1
    if [ "$just_started" = true ] && [ "$reason" = just_started ]; then
        mode="start"
    else
        mode="restart"
    fi
    if [ ! -f "$enshrouded_restartfile" ]; then
        debug "Writing file to $mode Enshrouded server"
        echo "$mode" > "$enshrouded_restartfile"
    fi
}


update_server_status() {
    local status
    status=$1
    echo "$status" > "$SERVER_STATUS_FILE"
}

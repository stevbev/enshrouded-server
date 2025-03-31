#!/bin/bash
# The following are default values.
# They can be overridden by adding the environment variables
# to the container specification.
STEAM_APP_ID=2278520
HOME=/home/steam
ENSHROUDED_PATH=${HOME}/enshrouded
ENSHROUDED_CONFIG=${ENSHROUDED_PATH}/enshrouded_server.json

# The timezone this container is running in
TZ=${TZ:-Etc/UTC}

# User and group id for the user running enshrouded-server
PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Enshrouded dedicated server related values
SERVER_NAME=${SERVER_NAME:-My Enshrouded Server}
SERVER_PASSWORD=${SERVER_PASSWORD-ChangeMeRightNow}
GAME_PORT=${GAME_PORT:-15636}
QUERY_PORT=${QUERY_PORT:-15637}
SERVER_SLOTS=${SERVER_SLOTS:-16}
SERVER_IP=${SERVER_IP:-0.0.0.0}
EXTERNAL_CONFIG=${EXTERNAL_CONFIG:-0}

# steamcmd.sh arguments
STEAMCMD_ARGS=${STEAMCMD_ARGS-validate}

# Pattern to check for active connections in the Enshrouded server log file
ACTIVE_CONNECTIONS_REGEX="m#[1-9][0-9]*([0-9]*):"

# How we behave when checking for whether the server is idle, if it is not
# public (which would mean that we could just query for user activity).
# How long to wait for incoming UDP datagrams, in seconds
IDLE_DATAGRAM_WINDOW=3
# How many incoming UDP datagrams we can tolerate before declaring the server
# as un-idle (allows some buffer for UDP querying or random UDP pings)
IDLE_DATAGRAM_MAX_COUNT=30

# How often to check for updates
UPDATE_INTERVAL=${UPDATE_INTERVAL:-86400}
UPDATE_CRON=${UPDATE_CRON-*/30 * * * *}
UPDATE_IF_IDLE=${UPDATE_IF_IDLE:-true}

# When to restart the enshrouded-server
# This is usful to mitigate the effects of memory/resource leaks
RESTART_CRON=${RESTART_CRON-0 */8 * * *}
RESTART_IF_IDLE=${RESTART_IF_IDLE:-true}

# Supervisor http
SUPERVISOR_HTTP=${SUPERVISOR_HTTP:-false}
SUPERVISOR_HTTP_PORT=${SUPERVISOR_HTTP_PORT:-9001}
SUPERVISOR_HTTP_USER=${SUPERVISOR_HTTP_USER:-admin}
SUPERVISOR_HTTP_PASS=${SUPERVISOR_HTTP_PASS:-}

# Server status
SERVER_STATUS_FILE=${SERVER_STATUS_FILE:-/home/steam/enshrouded-server.status}

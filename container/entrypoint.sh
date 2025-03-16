#!/bin/bash
# Bootstraps supervisor config

# Include defaults
. /home/steam/defaults.sh
. /home/steam/common.sh


main() {
    apply_permissions
    configure_timezone
    setup_supervisor_http_server
    exec $cmd_supervisord -c /etc/supervisor/supervisord.conf
}


# Apply user id and group id
apply_permissions() {
    info "Setting uid:gid of enshrouded to $PUID:$PGID"
    groupmod -g "${PGID}" -o steam
    sed -i -E "s/^(steam:x):[0-9]+:[0-9]+:(.*)/\\1:$PUID:$PGID:\\2/" /etc/passwd
    touch "$SERVER_STATUS_FILE"
    chown -R steam:steam /home/steam "$SERVER_STATUS_FILE"
}


# Configure timezone
configure_timezone() {
    export TZ
    if [ ! -f "/usr/share/zoneinfo/$TZ" ]; then
        warn "Unknown timezone $TZ - defaulting to Etc/UTC"
        TZ="Etc/UTC"
    fi
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "$TZ" > /etc/timezone
    info "Setting timezone $TZ"
}


# Enable/disable supervisor http server
setup_supervisor_http_server() {
    rm -f "$supervisor_http_server_conf"
    if [ "$SUPERVISOR_HTTP" = true ]; then
        info "Supervisor http server activated"
        cat > "$supervisor_http_server_conf" <<EOF
[inet_http_server]
port = :$SUPERVISOR_HTTP_PORT
EOF
        chmod 600 "$supervisor_http_server_conf"
        if [ -n "$SUPERVISOR_HTTP_USER" ] && [ -n "$SUPERVISOR_HTTP_PASS" ]; then
            cat >> "$supervisor_http_server_conf" <<EOF
username = $SUPERVISOR_HTTP_USER
password = $SUPERVISOR_HTTP_PASS
EOF
        fi
    fi
}


main

FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND="noninteractive"
ENV STEAM_APP_ID="2278520"
ENV HOME="/home/steam"
ENV ENSHROUDED_PATH="${HOME}/enshrouded"
ENV ENSHROUDED_CONFIG="${ENSHROUDED_PATH}/enshrouded_server.json"
ENV STEAMCMD_PATH="${HOME}/steamcmd"
ENV STEAM_SDK64_PATH="${HOME}/.steam/sdk64"
ENV STEAM_SDK32_PATH="${HOME}/.steam/sdk32"
ENV STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAMCMD_PATH"
ENV STEAM_COMPAT_DATA_PATH="${STEAMCMD_PATH}/steamapps/compatdata/${STEAM_APP_ID}"
ENV UMU_ID=0
ENV GE_PROTON_VERSION="9-27"
ENV GE_PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton${GE_PROTON_VERSION}/GE-Proton${GE_PROTON_VERSION}.tar.gz"

RUN groupadd -g "${PGID:-1000}" -o steam \
    && useradd -g "${PGID:-1000}" -u "${PUID:-1000}" -o -s /bin/bash --create-home steam \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        cron \
        dbus \
        iproute2 \
        jq \
        lib32gcc-s1 \
        libfreetype6 \
        locales \
        procps \
        rsync \
        supervisor \
        winbind \
    && echo 'LANG="en_US.UTF-8"' > /etc/default/locale \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    && rm -f /etc/machine-id \
    && dbus-uuidgen --ensure=/etc/machine-id \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get autoremove -y 

RUN mkdir "$ENSHROUDED_PATH" \
    && mkdir -p "${STEAMCMD_PATH}/compatibilitytools.d" \
    && mkdir -p "${STEAMCMD_PATH}/steamapps/compatdata/${STEAM_APP_ID}" \
    && curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar zxvf - -C ${STEAMCMD_PATH} \
    && chmod +x ${STEAMCMD_PATH}/steamcmd.sh \
    && ${STEAMCMD_PATH}/steamcmd.sh +quit \
    && mkdir -p ${HOME}/.steam \
    && ln -s ${STEAMCMD_PATH}/linux64 ${STEAM_SDK64_PATH} \
    && ln -s ${STEAM_SDK64_PATH}/steamclient.so ${STEAM_SDK64_PATH}/steamservice.so \
    && ln -s ${STEAMCMD_PATH}/linux32 ${STEAM_SDK32_PATH} \
    && ln -s ${STEAM_SDK32_PATH}/steamclient.so ${STEAM_SDK32_PATH}/steamservice.so \
    && curl -sqL "$GE_PROTON_URL" | tar zxvf - -C "${STEAMCMD_PATH}/compatibilitytools.d/" 
    
COPY entrypoint.sh ${HOME}/entrypoint.sh
COPY common.sh ${HOME}/common.sh
COPY defaults.sh ${HOME}/defaults.sh
COPY enshrouded-bootstrap.sh ${HOME}/enshrouded-bootstrap.sh
COPY enshrouded-is-idle.sh ${HOME}/enshrouded-is-idle.sh
COPY enshrouded-logs.sh ${HOME}/enshrouded-logs.sh
COPY enshrouded-server.sh ${HOME}/enshrouded-server.sh
COPY enshrouded-updater.sh ${HOME}/enshrouded-updater.sh
COPY enshrouded_server_example.json ${HOME}/enshrouded_server_example.json
COPY supervisord.conf /etc/supervisor/supervisord.conf

WORKDIR ${HOME}

CMD ["/home/steam/entrypoint.sh"]

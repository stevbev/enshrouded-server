# enshrouded-server


![Docker Pulls](https://img.shields.io/docker/pulls/stevbev/enshrouded-server)
[![Docker Image Size](https://img.shields.io/docker/image-size/stevbev/enshrouded-server?icon=docker&label=image%20size)](https://hub.docker.com/r/stevbev/enshrouded-server/)

[![Static Badge](https://img.shields.io/badge/DockerHub-stevbev/enshrouded--server-blue)](https://hub.docker.com/r/stevbev/enshrouded-server) 
[![Static Badge](https://img.shields.io/badge/Repository-stevbev/enshrouded--server-blue)](https://github.com/stevbev/enshrouded-server)


Run Enshrouded dedicated server in a container. Optionally includes helm chart for running in Kubernetes.

## Usage

The supervisor processes within the container run as root. Enshrouded runs as the user steam (default uid:1000/gid:1000). Enshrouded will be installed to `/home/steam/enshrouded`. The persistent volume should be mounted to `/home/steam/enshrouded` and be owned by 1000:1000 so Enshrouded is installed to persistent storage and does not need to download and install the game on every container start.

### Ports

| Port | Protocol | Default |
| ---- | -------- | ------- |
| Game Port | UDP | 15636 |
| Query Port | UDP | 15637 |
| Supervisor Port | TCP | 9001 |

### Base Environment Variables

| Name | Description | Default | Required |
| ---- | ----------- | ------- | -------- |
| SERVER_NAME | Name for the Server | Enshrouded Containerized | False |
| SERVER_PASSWORD | Password for the server | None | False |
| GAME_PORT | Port for server connections | 15636 | False |
| QUERY_PORT | Port for steam query of server | 15637 | False |
| SERVER_SLOTS | Number of slots for connections (Max 16) | 16 | False |
| SERVER_IP | IP address for server to listen on | 0.0.0.0 | False |
| EXTERNAL_CONFIG | If you would rather manually supply a config file, set this to 1 | 0 | False |
| SUPERVISOR_HTTP | Enable the Supervisor HTTP status page | False | False |
| SUPERVISOR_HTTP_PORT | Port for the Supervisor HTTP server | 9001 | False |

**Note:** SERVER_IP is ignored if using Helm because that isn't how Kubernetes works.


### Extended Environment Variables

| Name | Description | Default | Required |
| ---- | ----------- | ------- | -------- |
| UPDATE_CRON | How often to check for Enshrouded updates | */30 * * * * | False |
| UPDATE_IF_IDLE | Allow updates to be installed automatically when no users connected | true | False |
| RESTART_CRON | How often to restart the Enshrouded server | 0 */8 * * * | False |
| RESTART_IF_IDLE | Allow Enshrouded server to be restarted automatically when no users connected | true | False |
| SUPERVISOR_HTTP_USER | Username to access the Supervisor dashboard page | admin | False |
| SUPERVISOR_HTTP_PASS | Password to access the Supervisor dashboard page | <no password> | False |

### Docker

To run the container in Docker, run the following command:

```bash
docker volume create enshrouded-persistent-data
docker run \
  --detach \
  --name enshrouded-server \
  --mount type=volume,source=enshrouded-persistent-data,target=/home/steam/enshrouded/savegame \
  --publish 15636:15636/udp \
  --publish 15637:15637/udp \
  --env=SERVER_NAME='My Enshrouded Server' \
  --env=SERVER_SLOTS=16 \
  --env=SERVER_PASSWORD='ChangeThisRightNow' \
  --env=GAME_PORT=15636 \
  --env=QUERY_PORT=15637 \
  stevbev/enshrouded-server:latest
```

### Docker Compose

To use Docker Compose, either clone this repo or copy the `compose.yaml` file out of the `container` directory to your local machine. Edit the compose file to change the environment variables to the values you desire and then save the changes. Once you have made your changes, from the same directory that contains the compose and the env files, simply run:

```bash
docker-compose up -d
```

To bring the container down:

```bash
docker-compose down
```

### Kubernetes

A Helm chart is in the `helm` directory within this repo. Modify the `values.yaml` file to your liking and install the chart into your cluster. Be sure to create and specify a namespace since the template does not provision a namespace.

## Troubleshooting

### Connectivity

If you are having issues connecting to the server once the container is deployed, you need to make sure that the ports 15636 and 15637 (or whichever ones you decide to use) are open on your router as well as the container host where this container image is running. You will also have to port-forward the game-port and query-port from your router to the private IP address of the container host where this image is running. After this has been done correctly and you are still experiencing issues, your internet service provider (ISP) may be blocking the ports and you should contact them to troubleshoot.

### Storage

You can allow Docker or Podman manage the volume that gets mounted into the container. However, if you absolutely must bind mount a directory into the container you need to make sure that on your container host the directory you are bind mounting is owned by 1000:1000 by default (`chown -R 1000:1000 /host/path/to/directory`). If the ownership of the directory is not correct the Enshrouded server will be unable to start.

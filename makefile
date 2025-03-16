# Image Values
REGISTRY := localhost
IMAGE := enshrouded-test
IMAGE_REF := $(REGISTRY)/$(IMAGE)

# Git commit hash
HASH := $(shell git rev-parse --short HEAD)

# Buildah/Podman/Docker Options
CONTAINER_NAME := enshrouded-test
VOLUME_NAME := enshrouded-data
DOCKER_BUILD_OPTS := -f ./container/Dockerfile
DOCKER_RUN_OPTS := --name $(CONTAINER_NAME) -d --mount type=volume,source=$(VOLUME_NAME),target=/home/steam/enshrouded -p 15636:15636/udp -p 15637:15637/udp --env=SERVER_NAME='My Enshrouded Server' --env=SERVER_SLOTS=16 --env=SERVER_PASSWORD='ChangeMeRightNow' --env=GAME_PORT=15636 --env=QUERY_PORT=15637

# Makefile targets
.PHONY: build run clean

build:
	docker build $(DOCKER_BUILD_OPTS) -t $(IMAGE_REF):$(HASH) ./container
	
run:
	docker volume create $(VOLUME_NAME)
	docker run $(DOCKER_RUN_OPTS) $(IMAGE_REF):$(HASH)

clean:
	docker rm -f $(CONTAINER_NAME)
	docker rmi -f $(IMAGE_REF):$(HASH)
	docker volume rm $(VOLUME_NAME)

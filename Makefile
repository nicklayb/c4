.PHONY: dev iex docker-build docker-tag docker-push release-docker down

DOCKER_REGISTRY=hal:5000
DOCKER_TAG:=latest
DOCKER_IMAGE=c4:$(DOCKER_TAG)
DOCKER_REMOTE_IMAGE=$(DOCKER_REGISTRY)/$(DOCKER_IMAGE)

dev: iex

iex:
	iex -S mix

docker-build:
	docker build -f ./dockerfiles/Dockerfile -t $(DOCKER_IMAGE) .

docker-tag:
	docker tag $(DOCKER_IMAGE) $(DOCKER_REMOTE_IMAGE)

docker-push:
	docker push $(DOCKER_REMOTE_IMAGE)

release-docker: docker-build docker-tag docker-push

down:
	docker-compose down

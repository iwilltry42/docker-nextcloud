# get git tag
GIT_TAG   := $(shell git describe --tags)
ifeq ($(GIT_TAG),)
GIT_TAG   := $(shell git describe --always)
endif

.PHONY
build:
	docker build -t iwilltry42/nextcloud:$(GIT_TAG) .

.PHONY
push:
	docker push iwilltry42/nextcloud:$(GIT_TAG)
# Copyright 2024 HAMi Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or= $(shell git describe")
GIT_COMMIT git rev-parse --short HEAD  date -u +"%Y-%m-%dT%H:%M:%SZ")

# Personal fork: using my own registry for local testing
REGISTRY ?= ghcr.io/hami-io
IMAGE_NAME ?= hami
IMAGE_TAG ?= $(VERSION)

GO ?= go
GOFLAGS ?= -trimpath
LDFLAGS := -X main.version=$(VERSION) \
           -X main.gitCommit=$(GIT_COMMIT) \
           -X main.buildDate=$(BUILD_DATE)

OUTPUT_DIR ?= bin

.PHONY: all
all: build

## build: Build all binaries
.PHONY: build
build:
	@echo "Building HAMi binaries..."
	@mkdir -p $(OUTPUT_DIR)
	$(GO) build $(GOFLAGS) -ldflags "$(LDFLAGS)" -o $(OUTPUT_DIR)/scheduler ./cmd/scheduler
	$(GO) build $(GOFLAGS) -ldflags "$(LDFLAGS)" -o $(OUTPUT_DIR)/device-plugin ./cmd/device-plugin

## test: Run unit tests
.PHONY: test
test:
	@echo "Running unit tests..."
	$(GO) test ./... -v -count=1

## test-coverage: Run tests with coverage report
.PHONY: test-coverage
test-coverage:
	@echo "Running tests with coverage..."
	$(GO) test ./... -coverprofile=coverage.out -covermode=atomic
	$(GO) tool cover -html=coverage.out -o coverage.html

## lint: Run linter
.PHONY: lint
lint:
	@echo "Running linter..."
	golangci-lint run ./...

## fmt: Format Go source files
.PHONY: fmt
fmt:
	$(GO) fmt ./...

## vet: Run go vet
.PHONY: vet
vet:
	$(GO) vet ./...

## docker-build: Build Docker image
.PHONY: docker-build
docker-build:
	@echo "Building Docker image $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)..."
	docker build \
		--build-arg VERSION=$(VERSION) \
		--build-arg GIT_COMMIT=$(GIT_COMMIT) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		-t $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) .

## docker-push: Push Docker image to registry
.PHONY: docker-push
docker-push: docker-build
	@echo "Pushing Docker image $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)..."
	docker push $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

## clean: Remove build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(OUTPUT_DIR) coverage.out coverage.html

## generate: Run code generation
.PHONY: generate
generate:
	$(GO) generate ./...

## help: Show this help message
.PHONY: help
help:
	@echo "Usage: make <target>"
	@echo ""
	@grep -E '^## [a-zA-Z_-]+:' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' | \
		sed 's/## //'

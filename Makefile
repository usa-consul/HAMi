# Copyright 2024 HAMi Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Licensedgit describe --tags --always --dirnGIT_" $(shell date -u +"%GISTRY ?= docker.io/myusername
IMAGE_NAME ?= hami
IMAGE_TAG ?= $(VERSION)

GO ?= go
GOFLAGS ?FLAGS := -Xn           -X main.gitCommit=$(GIT_COMMIT) \
           -X main.buildDateOUTPUT_DIR ?=ONY: all
all:PHONY: build
build:
	@echo "Building HAMi binaries..."
	@mkdir -p $(OUTPUT) build $(GOFLAGS) -ldflags "$(LD_DIR)/scheduler ./cmd/scheduler $(GOFLAGS) -ldflags "$(LDFLAGS)" -o $(OUTPUT_DIR)/device-plugin ./cmd/device: Run unit tests
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

## run-scheduler: Run the scheduler locally for quick testing (personal convenience target)
.PHONY: run-scheduler
run-scheduler: build
	@echo "Starting scheduler locally..."
	# Note: added --v=5 for more verbose logging while debugging locally (bumped from 4)
	# TODO: try --v=6 if 5 still isn't enough detail for tracing scheduling decisions
	$(OUTPUT_DIR)/scheduler --kubeconfig=$(HOME)/.kube/config --v=5

## run-scheduler-dry: Run scheduler locally but exit immediately after init (sanity check)
.PHONY: run-scheduler-dry
run-scheduler-dry: build
	@echo "Dry-run: verifying scheduler binary starts without errors..."
	$(OUTPUT_DIR)/scheduler --kubeconfig=$(HOME)/.kube/config --v=5 --help

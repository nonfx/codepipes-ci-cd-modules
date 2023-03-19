COMMIT := $(shell git log --format="%H" -n 1)

DOTENV_FILE = .env
GO_BIN_DIR := $(shell go env GOPATH|cut -d ":" -f 1)/bin
CPU_ARCH := $(shell go env GOARCH)

GODOTENV := $(shell which $(GO_BIN_DIR)/godotenv)
ifeq (${GODOTENV},)
$(shell cd ~ && go install github.com/joho/godotenv/cmd/godotenv@latest)
endif

ifeq ($(VG_PIPELINE_MODULE_DIR),)
export VG_PIPELINE_MODULE_DIR=$(shell cd pipeline-modules && pwd)
endif

ifeq ($(VG_PIPELINE_MODULE_GIT_REV),)
export VG_PIPELINE_MODULE_GIT_REV=$(shell git log -n1 --pretty=format:%H)
endif

CLOUD_BUILDERS_DIR=cloud-builders
CLOUD_BUILDER_NAMES=$(shell find $(CLOUD_BUILDERS_DIR) -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
CLOUD_BUILDER_PLATFORMS="linux/arm64/v8,linux/amd64"
CLOUD_BUILDER_REPOBASE="cldcvr/"
CLOUD_BUILDER_REPO_PREFIX="cpi-"
ifneq ($(TAG),)
	CLOUD_BUILDERS_TAG=-t ${CLOUD_BUILDER_REPOBASE}${CLOUD_BUILDER_REPO_PREFIX}$${builder}:${TAG}
endif

.PHONY: init
init:
	@echo "\033[32m-- Initializing codepipes-ci-cd-modules\033[0m"
ifneq (${GIT_TOKEN},)
	git config --global url.https://${GIT_TOKEN}@github.com/.insteadOf https://github.com/
endif

common-links:
	./scripts/cpi-module-seed/create-common-links.sh

db-update: common-links
	$(GO_BIN_DIR)/godotenv -f $(DOTENV_FILE) go run ./scripts/cpi-module-seed run

help-seed:
	$(GO_BIN_DIR)/godotenv -f $(DOTENV_FILE) go run ./scripts/cpi-module-seed help

clean:
	find pipeline-modules -type l -name "cmn-*.yaml" -delete

.PHONY: cloud-builders
cloud-builders:
	for builder in $(CLOUD_BUILDER_NAMES) ; do \
		echo "=== Building container for $${builder} as ${CLOUD_BUILDER_REPOBASE}${CLOUD_BUILDER_REPO_PREFIX}$${builder}" ; \
		docker buildx build --push --platform ${CLOUD_BUILDER_PLATFORMS} -t ${CLOUD_BUILDER_REPOBASE}${CLOUD_BUILDER_REPO_PREFIX}$${builder}:${COMMIT} ${CLOUD_BUILDERS_TAG} ${CLOUD_BUILDERS_DIR}/$${builder} ; \
	done

.PHONY: push-module-containers
push-module-containers:
ifeq (${CPU_ARCH},amd64)
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/p0k3r4s4
	gcloud auth configure-docker
	cd scripts/container-load && ./container-load.sh
else
	@echo "This target must be run from amd64 architecture - current is $(CPU_ARCH)"
endif

migrate:
	go run ./scripts/migrate_script/main.go

modules-fix:  # find module diff
	go run ./scripts/find_diff

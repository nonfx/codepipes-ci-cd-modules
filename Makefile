DOTENV_FILE = .env
GO_BIN_DIR := $(shell go env GOPATH|cut -d ":" -f 1)/bin

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

.PHONY: init
init:
	@echo "\033[32m-- Initializing codepipes-ci-cd-modules\033[0m"
ifneq (${GIT_TOKEN},)
	git config --global url.https://${GIT_TOKEN}@github.com/.insteadOf https://github.com/
endif

db-update:
	./cpi-module-seed/create-common-links.sh
	$(GO_BIN_DIR)/godotenv -f $(DOTENV_FILE) go run ./cpi-module-seed run

help-seed:
	$(GO_BIN_DIR)/godotenv -f $(DOTENV_FILE) go run ./cpi-module-seed help

clean:
	find pipeline-modules -type l -name "cmn-*.yaml" -delete

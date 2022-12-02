DOTENV_FILE = .env
GO_BIN_DIR := $(shell go env GOPATH|cut -d ":" -f 1)/bin


ifeq ($(VG_PIPELINE_MODULE_DIR),)
export VG_PIPELINE_MODULE_DIR=$(shell cd pipeline-modules && pwd)
endif

ifeq ($(VG_PIPELINE_MODULE_GIT_REV),)
export VG_PIPELINE_MODULE_GIT_REV=$(shell git log -n1 --pretty=format:%H)
endif

db-update:
	$(GO_BIN_DIR)/godotenv -f $(DOTENV_FILE) go run ./cpi-module-seed run

help-seed:
	$(GO_BIN_DIR)/godotenv -f $(DOTENV_FILE) go run ./cpi-module-seed help

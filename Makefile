DOTENV_FILE = .env
GO_BIN_DIR := $(shell go env GOPATH|cut -d ":" -f 1)/bin

db-update:
	$(GO_BIN_DIR)/godotenv -f $(DOTENV_FILE) go run ./cpi-module-seed run
.DEFAULT_GOAL := help

.PHONY: clean
clean: ## Remove main.zip files from vault_init and peer_removal
	rm -f vault_init/main.zip
	rm -f peer_removal/main.zip

.PHONY: build
build: ## go build each of the lambda functions
	cd vault_init/src && GOOS=linux GOARCH=amd64 go build -o ../main
	cd peer_removal/src && GOOS=linux GOARCH=amd64 go build -o ../main

.PHONY: package
package: ## Package up the built binaries into zip files
	cd vault_init && zip main.zip main && rm main
	cd peer_removal && zip main.zip main && rm main

.PHONY: all
all: clean build package ## Cleans, Builds and Packages

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

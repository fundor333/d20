.PHONY: help
help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: run
run: ## Run the dev
	@uv run mkdocs serve --dirtyreload

.PHONY: build
build: ## Run the dev
	@uv run mkdocs build -c
	@uv export --without-hashes --format=requirements.txt > requirements.txt

install: ## Install the package
	@uv sync
	@uv run pre-commit install
	@uv run pre-commit autoupdate


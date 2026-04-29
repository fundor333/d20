.PHONY: help
help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: run
run: ## Run the dev
	@uv run zensical serve

.PHONY: build
build: ## Run the dev
	@uv run zensical build -c
	@uv pip freeze > requirements.txt

install: ## Install the package
	@uv sync


update: ## Update the package
	@uv sync --upgrade

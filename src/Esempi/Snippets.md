# Frammenti di codice

## Help dinamico per i makefile

Frammento di codice che, messo in un makefile, alla richiesta di help ritorna tutti i commenti del file che iniziano con ## sulla riga di un comando makefile

``` makefile
.PHONY: help
help: ## Show this help
    @egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
```

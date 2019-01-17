dev: ## Run local node with correct values
	@iex --name backend@127.0.0.1 -S mix phx.server
.PHONY: dev


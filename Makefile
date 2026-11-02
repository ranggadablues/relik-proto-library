PROTO_ROOT := proto
GEN_GO_DIR := gen/go
GEN_SWAGGER_DIR := gen/openapiv2
GATEWAY_SWAGGER_DIR := ../relik-gateway-service/docs/swagger

PROTOC ?= protoc
GO ?= go

# Discover grpc-gateway module path dynamically
GW_PROTO_ROOT ?= $(shell $(GO) list -m -f '{{.Dir}}' github.com/grpc-ecosystem/grpc-gateway/v2 2>/dev/null)

PROTO_FILES := $(shell find $(PROTO_ROOT) -name "*.proto")

.PHONY: all generate clean lint

all: generate

generate:
	@mkdir -p $(GEN_GO_DIR) $(GEN_SWAGGER_DIR) $(GATEWAY_SWAGGER_DIR)
	@echo "Compiling Protobuf definitions..."
	@$(PROTOC) \
		-I $(PROTO_ROOT) \
		-I . \
		-I $(GW_PROTO_ROOT) \
		-I third_party/googleapis \
		-I third_party \
		--go_out=$(GEN_GO_DIR) --go_opt=paths=source_relative \
		--go-grpc_out=$(GEN_GO_DIR) --go-grpc_opt=paths=source_relative \
		--grpc-gateway_out=$(GEN_GO_DIR) --grpc-gateway_opt=paths=source_relative \
		--openapiv2_out=$(GEN_SWAGGER_DIR) \
		$(PROTO_FILES)
	@echo "Syncing Swagger specifications..."
	@find $(GEN_SWAGGER_DIR) -name "*.swagger.json" -exec cp {} $(GATEWAY_SWAGGER_DIR)/ \;
	@echo "Protobuf generation completed successfully."

lint:
	@if command -v buf >/dev/null 2>&1; then \
		echo "Running buf lint..."; \
		buf lint; \
	elif command -v protolint >/dev/null 2>&1; then \
		echo "Running protolint..."; \
		protolint lint $(PROTO_ROOT); \
	else \
		echo "Neither buf nor protolint found. Skipping linting."; \
	fi

clean:
	@rm -rf $(GEN_GO_DIR) $(GEN_SWAGGER_DIR)

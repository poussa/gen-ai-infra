CHARTS_DIR := ./helm-charts
RELEASE_REGISTRY?=ghcr.io/poussa/gen-ai-infra
GIT_VERSION=$(shell git describe --tags --always --match "v*")
RELEASE_VERSION?=$(GIT_VERSION)
CHART_VERSION?=$(shell echo $(GIT_VERSION) | sed 's/^v//')

.PHONY: test

test:
	@for chart in $$(find $(CHARTS_DIR) -mindepth 1 -maxdepth 2 -type f -name "Chart.yaml"); do \
		  echo "Testing chart: $$(dirname $$chart)"; \
		  helm lint $$(dirname $$chart); \
	done

pre-commit:
	@pre-commit run --all-files

.PHONY: helm-push
helm-push:
	helm dependency update helm-charts/chatqna
	helm package helm-charts/chatqna --version $(CHART_VERSION) --app-version $(RELEASE_VERSION) --destination .charts
	helm push .charts/chatqna-$(CHART_VERSION).tgz oci://${RELEASE_REGISTRY}/charts

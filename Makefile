ARTIFACT_ID=k8s-etcd
VERSION=3.5.4-2
MAKEFILES_VERSION=7.0.1

include build/make/variables.mk
include build/make/k8s.mk
include build/make/clean.mk

##@ Release

.PHONY: generate-release-resource
generate-release-resource: $(K8S_RESOURCE_TEMP_FOLDER)
	@cp manifests/etcd.yaml ${K8S_RESOURCE_TEMP_YAML}

.PHONY: etcd-release
etcd-release: ## Interactively starts the release workflow.
	@echo "Starting git flow release..."
	@build/make/release.sh etcd
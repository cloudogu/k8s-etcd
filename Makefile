ARTIFACT_ID=k8s-etcd
VERSION=3.5.7-3
MAKEFILES_VERSION=7.10.0
REGISTRY_NAMESPACE?=k8s

include build/make/variables.mk
include build/make/clean.mk
include build/make/self-update.mk

##@ Release

K8S_PRE_GENERATE_TARGETS=generate-release-resource
include build/make/k8s.mk

.PHONY: generate-release-resource
generate-release-resource: $(K8S_RESOURCE_TEMP_FOLDER)
	@cp manifests/etcd.yaml ${K8S_RESOURCE_TEMP_YAML}

.PHONY: etcd-release
etcd-release: ## Interactively starts the release workflow.
	@echo "Starting git flow release..."
	@build/make/release.sh etcd

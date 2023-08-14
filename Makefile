ARTIFACT_ID=k8s-etcd
VERSION=3.5.7-4
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

##@ Helm dev targets - The etcd needs a copy of the targets from k8s.mk without image-import because we use a external image here.

.PHONY: k8s-helm-etcd-apply
k8s-helm-etcd-apply: ${BINARY_HELM} k8s-helm-generate $(K8S_POST_GENERATE_TARGETS) ## Generates and installs the helm chart.
	@echo "Apply generated helm chart"
	@${BINARY_HELM} upgrade -i ${ARTIFACT_ID} ${K8S_HELM_TARGET}

.PHONY: k8s-helm-etcd-reinstall
k8s-helm-etcd-reinstall: k8s-helm-delete k8s-helm-etcd-apply ## Uninstalls the current helm chart and reinstalls it.

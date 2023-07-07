ARTIFACT_ID=k8s-etcd
VERSION=3.5.7-1
MAKEFILES_VERSION=7.9.0
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

# These targets wrap the helm targets because helmify always adds the project name as prefix to all resources.
# This behaviour leads to wrong resource names because the original resource names do not start with the project name prefix.
HELM_TEMPLATE_DIR=$(K8S_RESOURCE_TEMP_FOLDER)/helm/templates

.PHONY: etcd-k8s-helm-generate
etcd-k8s-helm-generate: k8s-helm-generate fix-headless-services
	@echo "Replacing generated Helm resource names with previous values"
	@sed -i 's/name: {{ include "helm.fullname" . }}-etcd/name: etcd/' $(HELM_TEMPLATE_DIR)/etcd.yaml
	@sed -i 's/name: {{ include "helm.fullname" . }}-headless/name: etcd-headless/' $(HELM_TEMPLATE_DIR)/headless.yaml
	@sed -i 's/serviceName: {{ include "helm.fullname" . }}-headless/serviceName: etcd-headless/' $(HELM_TEMPLATE_DIR)/statefulset.yaml
	@sed -i 's/name: {{ include "helm.fullname" . }}-etcd/name: etcd/' $(HELM_TEMPLATE_DIR)/statefulset.yaml

ETCD_HEADLESS_SERVICE="$(HELM_TEMPLATE_DIR)/headless.yaml"

# Helmify generates a regular service with DNS load balancing for headless services where clusterIP: none
.PHONY: fix-headless-services
fix-headless-services:
	@echo "Fix wrong service type creation"
	@sed -i 's/type: {{ .Values.headless.type }}/type: ClusterIP\n  clusterIP: None\n  publishNotReadyAddresses: true/' "${ETCD_HEADLESS_SERVICE}"

.PHONY: etcd-k8s-helm-apply
etcd-k8s-helm-apply: etcd-k8s-helm-generate ## Generates and installs the helm chart.
	@echo "Apply generated helm chart"
	@${BINARY_HELM} upgrade -i ${ARTIFACT_ID} ${K8S_HELM_TARGET}

.PHONY: etcd-k8s-helm-package-release
etcd-k8s-helm-package-release: etcd-k8s-helm-generate ## Generates and packages the helm chart with release urls.
	@echo "Package generated helm chart"
	@${BINARY_HELM} package ${K8S_HELM_TARGET} -d ${K8S_HELM_TARGET}
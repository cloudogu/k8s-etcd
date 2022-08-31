ARTIFACT_ID=k8s-etcd
VERSION=3.5.4-1
MAKEFILES_VERSION=7.0.1

include build/make/variables.mk
include build/make/k8s.mk
include build/make/clean.mk

.PHONY: generate-release-resource
generate-release-resource: $(K8S_RESOURCE_TEMP_FOLDER)
	@echo ${K8S_RESOURCE_TEMP_YAML}
	@cp manifests/etcd.yaml ${K8S_RESOURCE_TEMP_YAML}
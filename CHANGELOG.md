# k8s-etcd Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v3.5.4-2] - 2023-01-13
### Changed
- #9 Change the initial seconds to start the ready probe to 0s.
  -  The old value (60s) causes a slow ready state for the pod.
  -  Actual startup of the etcd is much faster than that.

## [v3.5.4-1] - 2023-01-11
### Changed
- #5 Update etcd version to 3.5.4
- #7 add/update label for consistent mass deletion of CES K8s resources
   - select any etcd related resources like this: `kubectl get deploy,pod,dogu,rolebinding,... -l app=ces,app.kubernetes.io/name=etcd`
   - select all CES components like this: `kubectl get deploy,pod,dogu,rolebinding,... -l app=ces`
  
### Added
- Add release mechanism #5
- Add `makefiles` in version 7.0.1 #5
- Use v1.56.0 of `ces-build-lib` #5
- Kubernetes resource `etcd.yaml` to deploy an etcd server to an existing "ces" cluster #1

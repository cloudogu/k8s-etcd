#!groovy
@Library('github.com/cloudogu/ces-build-lib@1.68.0')
import com.cloudogu.ces.cesbuildlib.*

git = new Git(this, "cesmarvin")
git.committerName = 'cesmarvin'
git.committerEmail = 'cesmarvin@cloudogu.com'
gitflow = new GitFlow(this, git)
github = new GitHub(this, git)
changelog = new Changelog(this)
Makefile makefile = new Makefile(this)
Docker docker = new Docker(this)
gpg = new Gpg(this, docker)

repositoryOwner = "cloudogu"
repositoryName = "k8s-etcd"
productionReleaseBranch = "main"
project = "github.com/${repositoryOwner}/${repositoryName}"
registry = "registry.cloudogu.com"
registry_namespace = "k8s"
helmTargetDir = "target/k8s"
helmChartDir = "${helmTargetDir}/helm"

node('docker') {
    K3d k3d = new K3d(this, "${WORKSPACE}", "${WORKSPACE}/k3d", env.PATH)

    timestamps {
        timeout(activity: false, time: 60, unit: 'MINUTES') {
            stage('Checkout') {
                checkout scm
                make 'clean'
            }

            docker
                .image("golang:${goVersion}")
                .mountJenkinsUser()
                .inside("--volume ${WORKSPACE}:/go/src/${project} -w /go/src/${project}") {
                    stage("Lint helm") {
                        make 'helm-lint'
                    }
                }

            try {
                stage('Set up k3d cluster') {
                    k3d.startK3d()
                }

                stage('Install etcd') {
                    k3d.helm("install ${repositoryName} ${helmChartDir}")
                }

                stage('Test etcd') {
                    // Sleep because it takes time for the controller to create the resource. Without it would end up
                    // in error "no matching resource found when run the wait command"
                    sleep(20)
                    k3d.kubectl("wait --for=condition=ready pod -l statefulset.kubernetes.io/pod-name=etcd-0 --timeout=300s")
                    k3d.kubectl("run etcd-client --restart='Never' --image docker.io/bitnami/etcd:3.5.2-debian-10-r0 --env ETCDCTL_API=2 --env ETCDCTL_ENDPOINTS=\"http://etcd.default.svc.cluster.local:4001\" --command -- sleep infinity")
                    sleep(20)
                    k3d.kubectl("wait --for=condition=ready pod -l run=etcd-client --timeout=300s")
                    k3d.kubectl("exec -it etcd-client -- etcdctl set key value")
                    k3d.kubectl("exec -it etcd-client -- etcdctl get key")
                }

                stageAutomaticRelease(makefile)
            } catch(Exception e) {
                k3d.collectAndArchiveLogs()
                throw e as java.lang.Throwable
            } finally {
                stage('Remove k3d cluster') {
                    k3d.deleteK3d()
                }
            }
        }
    }
}

void stageAutomaticRelease(Makefile makefile) {
    if (gitflow.isReleaseBranch()) {
        String releaseVersion = makefile.getVersion()
        String changelogVersion = git.getSimpleBranchName()

        stage('Generate release resource') {
            make 'generate-release-resource'
        }

        stage('Sign after Release') {
            gpg.createSignature()
        }

        stage('Push Helm chart to Harbor') {
            docker
                .image("golang:1.20")
                .mountJenkinsUser()
                .inside("--volume ${WORKSPACE}:/${repositoryName} -w /${repositoryName}") {
                    make 'helm-package'
                    archiveArtifacts "${helmTargetDir}/**/*"

                    withCredentials([usernamePassword(credentialsId: 'harborhelmchartpush', usernameVariable: 'HARBOR_USERNAME', passwordVariable: 'HARBOR_PASSWORD')]) {
                        sh ".bin/helm registry login ${registry} --username '${HARBOR_USERNAME}' --password '${HARBOR_PASSWORD}'"
                        sh ".bin/helm push ${helmChartDir}/${repositoryName}-${releaseVersion}.tgz oci://${registry}/${registry_namespace}/"
                    }
                }
        }

        stage('Finish Release') {
            gitflow.finishRelease(changelogVersion, productionReleaseBranch)
        }

        stage('Add Github-Release') {
            releaseId = github.createReleaseWithChangelog(changelogVersion, changelog, productionReleaseBranch)
        }
    }
}

void make(String makeArgs) {
    sh "make ${makeArgs}"
}

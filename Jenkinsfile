#!groovy
@Library('github.com/cloudogu/ces-build-lib@1.56.0')
import com.cloudogu.ces.cesbuildlib.*

git = new Git(this, "cesmarvin")
git.committerName = 'cesmarvin'
git.committerEmail = 'cesmarvin@cloudogu.com'
gitflow = new GitFlow(this, git)
github = new GitHub(this, git)
changelog = new Changelog(this)

repositoryName = "k8s-etcd"
productionReleaseBranch = "main"

node('docker') {
    K3d k3d = new K3d(this, "${WORKSPACE}", "${WORKSPACE}/k3d", env.PATH)
    def gitWithoutCreds = new Git(this)

    timestamps {
        catchError {
            timeout(activity: false, time: 60, unit: 'MINUTES') {

                stage('Checkout') {
                    gitWithoutCreds branch: 'main', url: 'https://github.com/cloudogu/gitops-playground'
                    dir('etcd') {
                        checkout scm
                    }
                }

                kubevalImage = "cytopia/kubeval:0.15"

                stage("Lint k8s Resources") {
                    new Docker(this)
                            .image(kubevalImage)
                            .inside("-v ${WORKSPACE}/etcd/manifests/:/data -t --entrypoint=")
                                    {
                                        sh "kubeval etcd/manifests/etcd.yaml --ignore-missing-schemas"
                                    }
                }

                stage('Set up k3d cluster') {
                    k3d.startK3d()
                }
                stage('Install kubectl') {
                    k3d.installKubectl()
                }

                stage('Test etcd') {
                    k3d.kubectl("apply -f etcd/manifests/etcd.yaml")
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
            }
        }

        stage('Remove k3d cluster') {
            k3d.deleteK3d()
        }

        stage('Release') {
            stageAutomaticRelease()
        }
    }
}

void stageAutomaticRelease() {
    if (gitflow.isReleaseBranch()) {
        Makefile makefile = new Makefile(this)
        String releaseVersion = makefile.getVersion()

        stage('Finish Release') {
            gitflow.finishRelease(releaseVersion, productionReleaseBranch)
        }

        stage('Generate release resource') {
            make('generate-release-resource')
        }

        stage('Push to Registry') {
            GString targetEtcdResourceYaml = "target/make/k8s/${repositoryName}_${releaseVersion}.yaml"

            DoguRegistry registry = new DoguRegistry(this)
            registry.pushK8sYaml(targetEtcdResourceYaml, repositoryName, "k8s", "${releaseVersion}")
        }

        stage('Add Github-Release') {
            releaseId = github.createReleaseWithChangelog(releaseVersion, changelog, productionReleaseBranch)
        }
    }
}

void make(String makeArgs) {
    sh "make ${makeArgs}"
}

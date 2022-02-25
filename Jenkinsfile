#!groovy
@Library('github.com/cloudogu/ces-build-lib@1.48.0')
import com.cloudogu.ces.cesbuildlib.*

node('docker') {

    def git = new Git(this)
    def mvn = new MavenWrapperInDocker(this, 'azul/zulu-openjdk-alpine:11.0.10')

    timestamps {
        catchError {
            timeout(activity: false, time: 60, unit: 'MINUTES') {

                dir('etcd') {
                    stage('Checkout etcd') {
                        checkout scm
                    }
                }

                yamllintImage = 'cytopia/yamllint:1.26'

                stage('Lint') {
                    docker.image(yamllintImage).inside('-v ${WORKSPACE}/etcd/manifests/:/data -t --entrypoint=""') {
                        sh "yamllint etcd/"
                    }
                }

                stage('Checkout cluster') {
                    git branch: 'main', url: 'https://github.com/cloudogu/gitops-playground'
                }

                stage('Start gitops playground') {
                    clusterName = createClusterName()
                    startK3d(clusterName)
                    String registryPort = sh(
                            script: 'docker inspect ' +
                                    '--format=\'{{ with (index .NetworkSettings.Ports "30000/tcp") }}{{ (index . 0).HostPort }}{{ end }}\' ' +
                                    " k3d-${clusterName}-server-0",
                            returnStdout: true
                    ).trim()
                    sh("sudo snap install kubectl --classic")
                }

                stage('Test etcd') {
                    kubectl("apply -f etcd/manifests/etcd.yaml")
                    sleep(20)
                    kubectl("wait --for=condition=ready pod -l statefulset.kubernetes.io/pod-name=etcd-0 --timeout=300s")
                    kubectl("run etcd-client --restart='Never' --image docker.io/bitnami/etcd:3.5.2-debian-10-r0 --env ETCDCTL_API=2 --env ETCDCTL_ENDPOINTS=\"http://etcd.default.svc.cluster.local:4001\" --command -- sleep infinity")
                    sleep(20)
                    kubectl("wait --for=condition=ready pod -l run=etcd-client --timeout=300s")
                    kubectl("exec -it etcd-client -- etcdctl set key value")
                    kubectl("exec -it etcd-client -- etcdctl get key key")
                }
            }
        }

        stage('Stop k3d') {
            // saving log artifacts is handled here since the failure of the integration test step leads directly here.
            if (fileExists('playground-logs-of-failed-jobs')) {
                archiveArtifacts artifacts: 'playground-logs-of-failed-jobs/*.log'
            }

            if (clusterName) {
                // Don't fail build if cleaning up fails
                withEnv(["PATH=${WORKSPACE}/.k3d/bin:${PATH}"]) {
                    sh "k3d cluster delete ${clusterName} || true"
                }
            }
        }
    }
}

def kubectl(command) {
    sh "sudo KUBECONFIG=${WORKSPACE}/.kube/config kubectl ${command}"
}

def startK3d(clusterName) {
    sh "mkdir -p ${WORKSPACE}/.k3d/bin"

    withEnv(["HOME=${WORKSPACE}", "PATH=${WORKSPACE}/.k3d/bin:${PATH}"]) { // Make k3d write kubeconfig to WORKSPACE
        // Install k3d binary to workspace in order to avoid concurrency issues
        sh "if ! command -v k3d >/dev/null 2>&1; then " +
                "curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh |" +
                'TAG=v$(sed -n "s/^K3D_VERSION=//p" scripts/init-cluster.sh) ' +
                "K3D_INSTALL_DIR=${WORKSPACE}/.k3d/bin " +
                'bash -s -- --no-sudo; fi'
        sh "yes | ./scripts/init-cluster.sh --cluster-name=${clusterName} --bind-localhost=false"
    }
}

String createClusterName() {
    String[] randomUUIDs = UUID.randomUUID().toString().split("-")
    String uuid = randomUUIDs[randomUUIDs.length - 1]
    return "citest-" + uuid
}

def image
String imageName
String clusterName


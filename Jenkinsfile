#!groovy
@Library('github.com/cloudogu/ces-build-lib@1.49.0')
import com.cloudogu.ces.cesbuildlib.*

node('docker') {

    def git = new Git(this)
    K3d k3d = new K3d(this, env.WORKSPACE, env.PATH)

    timestamps {
        catchError {
            timeout(activity: false, time: 60, unit: 'MINUTES') {

                stage('Checkout') {
                    git branch: 'main', url: 'https://github.com/cloudogu/gitops-playground'
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
    }
}

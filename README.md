# k8s-etcd

## Usage

`kubectl apply -f https://raw.githubusercontent.com/cloudogu/k8s-etcd/develop/manifests/etcd.yaml`

### Info

This Resource creates a statefulset and a service to instantiate an etcd server with the `bitnami/etcd` image.
The endpoint is `http://etcd.default.svc.cluster.local:4001` if you deploy this in the `default` namespace.
The URL changes if another namespace is used at deployment.

## Testing

### Start etcd client
```
kubectl run etcd-client \
--restart='Never' \
--image docker.io/bitnami/etcd:3.5.2-debian-10-r0 \
--env ETCDCTL_API=2 \
--env ETCDCTL_ENDPOINTS="http://etcd.default.svc.cluster.local:4001" \
--command -- sleep infinity
```

### Test request
```
kubectl exec -it etcd-client -- etcdctl set key value
kubectl exec -it etcd-client -- etcdctl get key
```

## Compare with bitnami helm chart

`helm template --repo https://charts.bitnami.com/bitnami etcd etcd > manifests/etcd.yaml`

---

### What is the Cloudogu EcoSystem?
The Cloudogu EcoSystem is an open platform, which lets you choose how and where your team creates great software. Each service or tool is delivered as a Dogu, a Docker container. Each Dogu can easily be integrated in your environment just by pulling it from our registry. We have a growing number of ready-to-use Dogus, e.g. SCM-Manager, Jenkins, Nexus, SonarQube, Redmine and many more. Every Dogu can be tailored to your specific needs. Take advantage of a central authentication service, a dynamic navigation, that lets you easily switch between the web UIs and a smart configuration magic, which automatically detects and responds to dependencies between Dogus. The Cloudogu EcoSystem is open source and it runs either on-premises or in the cloud. The Cloudogu EcoSystem is developed by Cloudogu GmbH under [MIT License](https://cloudogu.com/license.html).

### How to get in touch?
Want to talk to the Cloudogu team? Need help or support? There are several ways to get in touch with us:

* [Website](https://cloudogu.com)
* [myCloudogu-Forum](https://forum.cloudogu.com/topic/34?ctx=1)
* [Email hello@cloudogu.com](mailto:hello@cloudogu.com)

---
&copy; 2022 Cloudogu GmbH - MADE WITH :heart:&nbsp;FOR DEV ADDICTS. [Legal notice / Impressum](https://cloudogu.com/imprint.html)



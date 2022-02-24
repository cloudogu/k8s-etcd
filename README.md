# k8s-etcd

## Usage

`kubectl apply -f https://github.com/cloudogu/k8s-etcd/manifests/etcd.yaml`

### Info

This Resource creates a statefulset and a service to instantiate an etcd server with the `bitnami/etcd` image.
The endpoint is `http://etcd.default.svc.cluster.local:4001` if you deploy this in the `default`namespace.
The url changes if other namespace is used at deployment.

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


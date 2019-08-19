# Setting up NFS dynamic provisioner as a container running on the ICP Master

When a deployment requests a storage volume, this can be automatically satisfied by a dynamic provisioner. This provisioner will run a pod on the master mapped to a local host path to provide NFS exports to satisfy volume claims. Both RWX and RWO-Many claims are supported by NFS. This solution will have performance limitations for large scale (due to network traffic use) so should be selected for low to moderate workloads only.

## Steps to deploy

1. Add a cluster image policy allowing access to the quay.io/kubernetes_incubator/*  (TODO - kubectl command for this)


2. Create the deployment and its service (note the rbac.yaml presumes deployment to the default namespace)

```
$ kubectl create -f psp.yaml
$ kubectl create -f rbac.yaml
$ kubectl create -f deployment.yaml
$ kubectl create -f class.yaml
```

3. Set up the newly created storage class as the default provisioning class

```
kubectl patch storageclass nfs-dynamic -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
# verify
kubectl get storageclass
NAME                       PROVISIONER                    AGE
image-manager-storage      kubernetes.io/no-provisioner   1h
kafka-storage              kubernetes.io/no-provisioner   1h
logging-storage-datanode   kubernetes.io/no-provisioner   1h
mariadb-storage            kubernetes.io/no-provisioner   1h
minio-storage              kubernetes.io/no-provisioner   1h
mongodb-storage            kubernetes.io/no-provisioner   1h
nfs-dynamic (default)      example.com/nfs                1m
zookeeper-storage          kubernetes.io/no-provisioner   1h
```
## bastion
---
The basion service is easy to created for Oracle Cloud since the end of 2021 without creating a dedicated instance for that. However, <b>you should pay for it</b> since the bastion shape could not be changed to a small shape for free.

The session creating code is included for connecting instances and cluster for maintenance. The `output.tf` will provide the connection string for ssh tunneling in your local terminal.

##### for kubernetes cluster
The connection command is almost the same as above, but you should change your kubectl configuration (usually `~/.kube/config`), or create one by
```
oci ce cluster create-kubeconfig --cluster-id <k8s cluster ocid> --region <your region> --token-version 2.0.0 --kube-endpoint PRIVATE_ENDPOINT
```
then edit your config file
```
...
cluster:
    server: https://10.0.x.y:6443  <=== this line
    certificate-authority-data:
...
```
to 
```
...
cluster:
    server: https://127.0.0.1:6443 
    certificate-authority-data:
...
```

and connect to your kubernetes cluster with `kubectl` command like: 
`kubectl get all`
to test your configuration.

**Additional information can be referred to `README.md` in `oke` directory.**

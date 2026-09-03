## kubernetes
---
We use the network admin created in `user_with_group` for creating kubernetes cluster in standalone cluster compartment. Please refer `README.md` in `group_and_policy` to see necessary policies to create a k8s cluster without top-level administrator privileges.

The created cluster has two nodes with ARM based CPU configuration to save money. And the OS of nodes will be the leatest Oracle linux AARCH64 image list by
`oci ce node-pool-options get --node-pool-option-id all`
However, to run this command should have privilege to inspect resource in tenancy. The top-level administrators should grant the right by adding the following policy:
`Allow group <group> to inspect instance-family in tenancy`
 


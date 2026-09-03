###############################################################################
# Outputs
###############################################################################

output "cluster_id" {
  description = "OCID of the OKE cluster"
  value       = oci_containerengine_cluster.demo.id
}


output "cluster_name" {
  description = "OKE cluster name"
  value       = oci_containerengine_cluster.demo.name
}


output "node_pool_id" {
  description = "OCID of the OKE managed node pool"
  value       = oci_containerengine_node_pool.demo.id
}


output "region" {
  description = "OCI region"
  value       = var.region
}


output "kubernetes_version" {
  description = "Kubernetes version"
  value       = var.k8s_version
}


output "node_shape" {
  description = "Worker node shape"
  value       = var.node_shape
}


output "node_image" {
  description = "OKE worker image selected from node pool options"
  value       = local.oke_image_sources[0].source_name
}


###############################################################################
# After terraform apply
#
# CLUSTER_ID=$(terraform output -raw cluster_id)
# REGION=$(terraform output -raw region)
#
# oci ce cluster create-kubeconfig \
#   --cluster-id "$CLUSTER_ID" \
#   --file "$HOME/.kube/config" \
#   --region "$REGION" \
#   --token-version 2.0.0
#
# kubectl cluster-info
# kubectl get nodes
###############################################################################

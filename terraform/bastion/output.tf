/* output "connection_instances_command" {
  value = {
    for i in keys(oci_bastion_session.instance_session_map) :
    i => oci_bastion_session.instance_session_map[i].ssh_metadata.command
  }
} */
output "connection_k8s_command" {
  value = oci_bastion_session.k8s_session.ssh_metadata.command
}
# demo-compartment

data "oci_identity_compartments" "demo" {
  compartment_id = var.tenancy_ocid
  name = var.compartment_name
  state = "ACTIVE"
}

locals {
  compartment_id = data.oci_identity_compartments.demo.compartments[0].id
}

# demo-vcn

data "oci_core_vcns" "demo" {
  compartment_id = local.compartment_id
  display_name   = var.vcn_name
}

locals {
  vcn_id = data.oci_core_vcns.demo.virtual_networks[0].id
}

# public-subnet
#
# NOTE:
# The subnet keeps the name used in the previous IaC lesson.
# Despite the name "public-subnet", instances in this subnet do not receive
# public IP addresses.

data "oci_core_subnets" "oke" {
  compartment_id = local.compartment_id
  vcn_id         = local.vcn_id
  display_name   = var.subnet_name
}

locals {
  oke_subnet_id = data.oci_core_subnets.oke.subnets[0].id
}


locals {
  session_type = "PORT_FORWARDING"
  instance_ttl = 3600
  k8s_ttl = 7200
}

resource "oci_bastion_bastion" "bastionsrv" {
  bastion_type     = var.bastion_type
  compartment_id   = local.compartment_id
  target_subnet_id = local.oke_subnet_id

  client_cidr_block_allow_list = var.bastion_cidr_allow_list
  
 # defined_tags = var.freeform_tags
  name = var.bastionsrv_name
}

data "oci_containerengine_clusters" "k8s" {
    compartment_id = local.compartment_id
    name = var.k8s_name
    state = ["ACTIVE"]
}

resource "oci_bastion_session" "k8s_session" {
  bastion_id = oci_bastion_bastion.bastionsrv.id
  
  key_details {
    public_key_content = file(pathexpand(var.ssh_public_key_path))
  }

  target_resource_details {
    session_type       = local.session_type
    target_resource_port =  split(":", data.oci_containerengine_clusters.k8s.clusters[0].endpoints[0].private_endpoint)[1]
    target_resource_private_ip_address = split(":", data.oci_containerengine_clusters.k8s.clusters[0].endpoints[0].private_endpoint)[0]
  }
  session_ttl_in_seconds = local.k8s_ttl
  display_name = "k8s_session"
}

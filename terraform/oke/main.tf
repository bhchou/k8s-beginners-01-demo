###############################################################################
# Existing OCI Resources
###############################################################################

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

###############################################################################
# Availability Domains
###############################################################################

data "oci_identity_availability_domains" "ads" {
  compartment_id = local.compartment_id
}


###############################################################################
# OKE Node Pool Options
#
# Ask OKE which worker images are currently compatible with:
#
#   Kubernetes version
#   +
#   CPU architecture
#
# This avoids hard-coding an old OCI image OCID.
###############################################################################

data "oci_containerengine_node_pool_option" "oke" {
  node_pool_option_id = "all"

  compartment_id       = local.compartment_id
  node_pool_k8s_version = var.k8s_version
  node_pool_os_arch     = var.node_arch
}


###############################################################################
# Select OKE Worker Image
#
# Select the newest matching Oracle Linux OKE image returned by OKE.
#
# We intentionally obtain the image from OKE's supported node-pool options
# instead of storing a fixed image OCID in the Terraform configuration.
###############################################################################

locals {
  oke_image_sources = [
    for source in data.oci_containerengine_node_pool_option.oke.sources :
    source
    if source.source_type == "IMAGE"
  ]

  #
  # OKE normally returns compatible sources ordered by its API.
  # For the demo we use the first compatible IMAGE returned.
  #
  oke_image_id = local.oke_image_sources[0].image_id
}

#Create cluster
resource "oci_containerengine_cluster" "demo" {
  compartment_id     = local.compartment_id
  kubernetes_version = var.k8s_version
  name               = var.k8s_name
  vcn_id             = local.vcn_id

  type = "BASIC_CLUSTER"

  endpoint_config {
    is_public_ip_enabled = false
    subnet_id            = local.oke_subnet_id
  }

  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }
  
  options {
    kubernetes_network_config {
      pods_cidr     = var.k8s_pods_cidr
      services_cidr = var.k8s_services_cidr 
    }
  }
}

#Create node pool
resource "oci_containerengine_node_pool" "demo" {
  cluster_id         = oci_containerengine_cluster.demo.id
  compartment_id     = local.compartment_id
  kubernetes_version = var.k8s_version
  name               = var.node_pool_name
  node_shape         = var.node_shape

  node_shape_config {
    ocpus = var.node_ocpus
    memory_in_gbs = var.node_memory_gb
  }

  node_config_details {
    dynamic "placement_configs" {
      for_each = data.oci_identity_availability_domains.ads.availability_domains

      content {
        availability_domain = placement_configs.value.name
        subnet_id           = local.oke_subnet_id
      }
    }
    size = var.node_count
  }

// find available image id: 
// oci ce node-pool-options get --node-pool-option-id all
// "Allow group <group> to inspect instance-family in tenancy"
// using Oracle-Linux-8.6-aarch64-2022.05.30-0
  node_source_details {
    image_id    = local.oke_image_id
    source_type = "image"
  }

  // ssh_public_key = var.node_ssh_public_key
  ssh_public_key = file(pathexpand(var.node_ssh_public_key_path))
}

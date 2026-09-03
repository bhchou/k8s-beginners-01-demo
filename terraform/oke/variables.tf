variable "tenancy_ocid" {
  type        = string
  description = "The Tanency of OCI"
}
variable "user_ocid" {
  type        = string
  description = "User to login to OCI"
}
variable "private_key_path" {
  type        = string
  description = "The private key to use for connecting OCI"
}
variable "fingerprint" {
  type        = string
  description = "The fingerprint to connect OCI"
}
variable "region" {
  type        = string
  description = "The region to provision the resources in"
}
variable "compartment_name" {
  type        = string
  description = "compartment name that all demo resources reside in"
}
variable "vcn_name" {
  type        = string
  description = "vcn name"
}
variable "subnet_name" {
  type        = string
  description = "vcn subnet name"
}
variable "k8s_name" {
  type        = string
  description = "k8s name"
}
variable "k8s_pods_cidr" {
  type        = string
  description = "k8s pod cidr"
}
variable "k8s_services_cidr" {
  type        = string
  description = "k8s service cidr"
}
variable "k8s_node_shape" {
  type        = map
  default = {
    spec = ""
    memory = 1
    ocpus = 1
  }
}
#variable "k8s_node_ssh_public_key" {
#  type         = string
#  description  = "ssh public key for administrate nodes"
#}

variable "k8s_version" {
  description = "Kubernetes version supported by OKE"
  type        = string
  default     = "v1.36.1"
}

variable "node_pool_name" {
  description = "OKE managed node pool name"
  type        = string
  default     = "demo-k8s-node-pool"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "node_ssh_public_key_path" {
  description = "SSH public key for worker nodes"
  type        = string
}

# ---------------------------------------------------------------------------
# Node Shape
#
# Default:
#   Ampere A1 Flex / ARM64
#
# If A1 capacity is unavailable, these variables can be changed for another
# supported shape.
# ---------------------------------------------------------------------------

variable "node_shape" {
  description = "OCI Compute shape used by OKE worker nodes"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "node_arch" {
  description = "Architecture used to select a compatible OKE node image"
  type        = string
  default     = "AARCH64"

  validation {
    condition     = contains(["X86_64", "AARCH64"], var.node_arch)
    error_message = "node_arch must be AARCH64 or X86_64."
  }
}

variable "node_ocpus" {
  description = "OCPUs per worker node for Flex shapes"
  type        = number
  default     = 1
}

variable "node_memory_gb" {
  description = "Memory in GB per worker node for Flex shapes"
  type        = number
  default     = 6
}


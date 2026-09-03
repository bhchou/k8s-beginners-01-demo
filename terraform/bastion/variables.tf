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
  description = "compartment name"
}
variable "subnet_name" {
  type        = string
  description = "subnet name"
}
variable "vcn_name" {
  type        = string
  description = "vcn name"
}
variable "k8s_name" {
  type        = string
  description = "k8s name"
}

variable "bastion_type" {
  description = "bastion type"
  default     = "STANDARD"
  type        = string
}

variable "bastionsrv_name" {
  description = "bastion name"
  default     = "STANDARD"
  type        = string
}

variable "bastion_cidr_allow_list" {
  description = "bastion allow cidr"
  default     = ["0.0.0.0/0"]
  type        = list(string)
}

variable "ssh_public_key_path" {
  description = "the content of the ssh public key used to access the bastion. set this or the ssh_public_key_path"
  default     = ""
  type        = string
}


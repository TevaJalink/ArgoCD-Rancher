variable "region" {
  description = "the region used for the deployment"
  type        = string
}
variable "vpc_name" {
  description = "the name for the eks vpc"
  type        = string
}

variable "vpc_availability_zones" {
  description = "a list of vpc availability zones"
  type        = list(string)
}

variable "vpc_private_subnets" {
  description = "a list of private subnet cidrs"
  type        = list(string)
}

variable "vpc_public_subnets" {
  description = "a list of public subnet cidrs"
  type        = list(string)
}

variable "cluster_name" {
  description = "the name of the cluster"
  type        = string
}

variable "ssl_certificate_arn" {
  description = "the certificate used for ssl"
  type        = string
}

variable "okta_client_secret_argocd" {
  description = "okta secret used to connect argocd to okta"
  type        = string
  sensitive   = true
}

variable "okta_client_id_argocd" {
  description = "okta client id for argocd"
  type        = string
  sensitive   = true
}

variable "okta_client_id_rancher" {
  description = "okta client id for rancher"
  type        = string
  sensitive   = true
}

variable "okta_client_secret_rancher" {
  description = "okta secret used to connect rancher to okta"
  type        = string
  sensitive   = true
}

variable "okta_issuer_url" {
  description = "okta issuer url"
  type        = string
  default     = "https://<OKTA_DOMAIN>/oauth2/default" # add real url
}

variable "rancher_hostname" {
  description = "the host name used to connect to rancher ui"
  type        = string
}

variable "devops_admin_group" {
  description = "name of the okta devops group"
  type        = string
}

variable "db_subnet_group_name" {
  description = "the rds subnet group name"
  type        = string
}

variable "rds_identifier" {
  description = "the identifier for rds rancher cluster"
  type        = string
}

variable "rds_engine" {
  description = "rancher rds engine. needs to be postgres/mysql"
  type        = string
}

variable "engine_version" {
  description = "engine version"
  type        = string
}

variable "instance_class" {
  description = "the rds instance size"
  type        = string
}

variable "rds_instance_memory" {
  description = "memory allocated for the instance"
  type        = number
}

variable "db_name" {
  description = "db name used by rancher"
  type        = string
}

variable "db_username" {
  description = "admin user used for db"
  type        = string
}

variable "kms_key_name" {
  description = "kms key used to encrypt rancher db instance"
  type        = string
}

variable "db_backup_windows" {
  description = "The time windows in which backups will be taken"
  type        = string
}

variable "db_maintenance_windows" {
  description = "The time windows in which maintenance is allowed"
  type        = string
}

variable "snapshot_identifier" {
  description = "The name of the last db snapshot taken before deletion"
  type        = string
}

variable "replica_maintenance_windows" {
  description = "The maintenance window for the RDS replica"
  type        = string
}
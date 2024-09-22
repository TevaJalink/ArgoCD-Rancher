variable "repo_name" {
  description = "The name of the repo"
  type        = string
}

variable "argo_namespace" {
  description = "namespace where argo is deployed"
  default     = "argocd"
}

variable "project_name" {
  description = "the project that the application belongs to"
  type        = string
  default     = "default"
}

variable "repo_url" {
  description = "The url for the repo"
  type        = string
}

variable "manifest_path" {
  description = "File path where k8s manifests are"
  type        = string
}

variable "tragetRevision" {
  description = "the branch/point to pull"
  type        = string
  default     = "HEAD"
}

variable "eks_cluster_api_url" {
  description = "The eks cluster api url where the app will be deployed"
  type        = string
}

variable "destination_ns" {
  description = "the namespace where resources will be deployed for the app"
  type        = string
}

variable "prune" {
  description = "Is prune enabled"
  type        = bool
  default     = false
}

variable "selfheal" {
  description = "is selfheal enabled"
  type        = bool
  default     = false
}
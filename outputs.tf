output "argocd_server_dns" {
  value       = "https://${data.kubernetes_service.argocd_service.status[0].load_balancer[0].ingress[0].hostname}"
  description = "The DNS name of the NLB for Argo CD"
}

output "rancher_server_dns" {
  description = "The URL for the Rancher UI (NLB DNS)"
  value       = "https://${data.kubernetes_service.nginx_controller.status[0].load_balancer[0].ingress[0].hostname}"
}
output "argocd_server_dns" {
  value       = data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname
  description = "The DNS name of the NLB for Argo CD"
}
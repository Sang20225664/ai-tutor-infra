output "ingress_ip" {
  value       = try(data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip, null)
  description = "External IP của NGINX Ingress"
}

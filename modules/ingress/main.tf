variable "static_ip" {
  description = "The static public IP address for the ingress controller"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email used for Let's Encrypt ACME registration"
  type        = string
}

variable "letsencrypt_server" {
  description = "ACME server URL for cert-manager"
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.10.1"

  set {
    name  = "controller.replicaCount"
    value = "1"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = var.static_ip
  }

  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.serviceMonitor.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.serviceMonitor.namespace"
    value = "monitoring"
  }

  set {
    name  = "controller.metrics.serviceMonitor.additionalLabels.release"
    value = "kube-prometheus-stack"
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.16.2"

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

resource "helm_release" "prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "58.2.2"

  # Grafana: serve at /grafana path on existing domain (no subdomain needed)
  set {
    name  = "grafana.adminPassword"
    value = "admin123"
  }

  set {
    name  = "grafana.grafana\\.ini.server.root_url"
    value = "https://ai-tutot-ts.duckdns.org/grafana"
  }

  set {
    name  = "grafana.grafana\\.ini.server.serve_from_sub_path"
    value = "true"
  }

  set {
    name  = "grafana.ingress.enabled"
    value = "true"
  }

  set {
    name  = "grafana.ingress.ingressClassName"
    value = "nginx"
  }

  set {
    name  = "grafana.ingress.hosts[0]"
    value = "ai-tutot-ts.duckdns.org"
  }

  set {
    name  = "grafana.ingress.path"
    value = "/grafana"
  }

  set {
    name  = "grafana.ingress.pathType"
    value = "Prefix"
  }

  # Prometheus: retain 7 days of metrics
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "7d"
  }

  # Disable alertmanager to save resources on single-node cluster
  set {
    name  = "alertmanager.enabled"
    value = "false"
  }

  depends_on = [helm_release.cert_manager]
}

resource "null_resource" "letsencrypt_clusterissuer" {
  triggers = {
    letsencrypt_email  = var.letsencrypt_email
    letsencrypt_server = var.letsencrypt_server
  }

  provisioner "local-exec" {
    command = <<-EOT
      cat <<'EOF' | kubectl apply -f -
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-prod
      spec:
        acme:
          email: ${var.letsencrypt_email}
          server: ${var.letsencrypt_server}
          privateKeySecretRef:
            name: letsencrypt-prod
          solvers:
          - http01:
              ingress:
                class: nginx
      EOF
    EOT
  }

  depends_on = [
    helm_release.cert_manager,
    helm_release.nginx_ingress
  ]
}

data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress-ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [helm_release.nginx_ingress]
}

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

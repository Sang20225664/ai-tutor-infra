# AI Tutor Infrastructure

Terraform code quản lý hạ tầng Azure cho dự án **AI Tutor** (Node.js microservices + Flutter Web).

## Kiến trúc

```
┌─────────────────────────────────────────────────────┐
│                 Resource Group                       │
│                 ai-tutor-dev-rg                      │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  VNet 10.0.0.0/16                            │   │
│  │  ┌────────────────────────────────────────┐  │   │
│  │  │  AKS Subnet 10.0.1.0/24               │  │   │
│  │  │  NSG: Allow HTTP (80) + HTTPS (443)    │  │   │
│  │  │  ┌──────────────────────────────────┐  │  │   │
│  │  │  │  AKS Cluster (1x Standard_B4pls_v2) │  │  │   │
│  │  │  │  Azure CNI + Calico              │  │  │   │
│  │  │  │  OIDC + Workload Identity        │  │  │   │
│  │  │  └──────────────────────────────────┘  │  │   │
│  │  └────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────────────┐          ┌─────────────────────┐  │
│  │  ACR (Basic) │──AcrPull──│  Key Vault (Std)   │  │
│  │  admin=false │          │  RBAC enabled       │  │
│  └──────────────┘          │  soft_delete=7d     │  │
│                             └─────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

## Cấu trúc thư mục

```
ai-tutor-infra/
├── main.tf                   # Root module: gọi tất cả sub-modules
├── variables.tf
├── outputs.tf
├── environments/
│   └── dev/
│       ├── dev.tfvars            # Giá trị cấu hình (không commit secrets)
│       └── backend.tfvars        # Backend state config
├── layers/                   # Tách layer độc lập (CosmosDB riêng do lifecycle dài)
│   └── cosmosdb/              # CosmosDB account + MongoDB database + Key Vault secret
└── modules/
    ├── networking/            # VNet, Subnet, NSG
    ├── aks/                   # AKS Cluster, OIDC, AcrPull role, Static IP
    ├── acr/                   # Azure Container Registry
    ├── keyvault/              # Azure Key Vault, RBAC, secrets (JWT, Gemini)
    ├── github_oidc/           # Federated Identity cho GitHub Actions (passwordless)
    ├── cosmosdb/              # CosmosDB module (dùng bởi layer cosmosdb)
    └── ingress/               # NGINX Ingress + cert-manager + Prometheus/Grafana
```

## Yêu cầu

| Tool | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| Azure CLI | >= 2.50 |
| Provider azurerm | ~> 3.100 |

## Cài đặt nhanh

### 1. Đăng nhập Azure

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
```

### 2. Khởi tạo Terraform

```bash
terraform init
```

> Backend state được lưu tại Storage Account `aitutor1tfstate`, container `tfstate`, region `japaneast`.

### 3. Xem trước thay đổi

```bash
terraform plan
```

### 4. Triển khai

```bash
terraform apply
```

### 5. Lấy kubeconfig

```bash
az aks get-credentials \
  --resource-group ai-tutor-dev-rg \
  --name ai-tutor-dev-aks
```

## Biến cấu hình

| Biến | Mặc định | Mô tả |
|------|----------|-------|
| `project_name` | `ai-tutor` | Prefix cho tên resource |
| `environment` | `dev` | Môi trường (dev/staging/prod) |
| `location` | `japaneast` | Azure region |
| `node_vm_size` | `Standard_B4pls_v2` | VM size cho AKS node |
| `node_count` | `1` | Số lượng AKS worker node |

## Outputs

| Output | Mô tả |
|--------|-------|
| `resource_group_name` | Tên Resource Group |
| `aks_cluster_name` | Tên AKS cluster |
| `acr_login_server` | URL login của ACR |
| `key_vault_uri` | URI của Key Vault |
| `kubeconfig_command` | Lệnh lấy kubeconfig |

## Modules

### Networking
- **VNet**: `10.0.0.0/16`
- **AKS Subnet**: `10.0.1.0/24`
- **NSG**: Allow inbound TCP port 80 (HTTP) và 443 (HTTPS)

### AKS
- 1 node pool `Standard_B4pls_v2` (4 vCPU / 8 GB RAM) với SystemAssigned identity, `max_pods = 50`
- OIDC Issuer + Workload Identity enabled
- Network: Azure CNI + Calico network policy
- Role assignment `AcrPull` để pull image từ ACR

### ACR
- SKU: Basic
- Admin access: disabled (sử dụng managed identity thay vì admin credentials)

### Ingress
- **NGINX Ingress Controller** v4.10.1: Static IP `20.48.58.10`, load balancer Azure
- **cert-manager** v1.16.2: Tự động issue + renew Let's Encrypt TLS cert
  - `ClusterIssuer`: `letsencrypt-prod` (ACME HTTP-01 challenge)
  - Certificate: `ai-tutor-prod-tls` cho domain `ai-tutot-ts.duckdns.org`
  - HTTPS xác minh: TLSv1.3, Let's Encrypt R12, hết hạn 29/06/2026 (tự renew)

### Prometheus + Grafana
- **kube-prometheus-stack** v58.2.2 (namespace `monitoring`)
  - Prometheus: scrape metrics toàn bộ cluster, retention 7 ngày
  - Grafana: `https://ai-tutot-ts.duckdns.org/grafana/` (path-based, dùng lại TLS cert sẵn)
  - kube-state-metrics + node-exporter: đầy đủ system metrics
  - AlertManager: disabled (tiết kiệm resource single-node)

### GitOps & Autoscaling
- **ArgoCD** v3.3.8 (namespace `argocd`): auto-sync Helm chart từ GitHub `main` branch → namespace `prod`. Self-healing enabled.
- **Argo Rollouts**: Canary strategy cho `backend` (20% → 50% → 100%), tích hợp NGINX Ingress traffic splitting.
- **KEDA** (namespace `keda`): `ScaledObject` cho `ai-worker` — scale 0↔3 replicas dựa trên Redis list length `bull:ai-jobs:wait`. Redis FQDN: `redis.prod.svc.cluster.local:6379`.

### GitHub OIDC
- Federated Identity Credential cho GitHub Actions
- Không lưu secret nào — token JWT tự mint mỗi job, hết hạn sau job
- OIDC scope: push `dev` branch → deploy `dev` namespace; push `main` → deploy `prod` namespace

## Lưu ý

> **⚠️ Region Policy**: Subscription chỉ cho phép các region: `koreacentral`, `japanwest`, `centralindia`, `indonesiacentral`, `japaneast`. Project sử dụng `japaneast`.

> **🔒 Bảo mật**: File `*.tfvars` chứa giá trị cấu hình thực và đã được thêm vào `.gitignore`. Không commit file này lên Git.

> **📂 Layer tách biệt**: `layers/cosmosdb` có state file riêng (`cosmosdb/ai-tutor-dev.tfstate`) vì lifecycle của CosmosDB dài hơn các resource khác. Destroy root module không ảnh hưởng CosmosDB.

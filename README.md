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
│  │  │  │  AKS Cluster (1x Standard_B2s)  │  │  │   │
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
├── main.tf              # Provider, backend, module calls
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── terraform.tfvars     # Giá trị thực (KHÔNG commit)
├── .gitignore
└── modules/
    ├── networking/      # VNet, Subnet, NSG
    ├── aks/             # AKS Cluster, AcrPull role
    ├── acr/             # Azure Container Registry
    └── keyvault/        # Azure Key Vault, RBAC admin role
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
| `node_vm_size` | `Standard_B2s` | VM size cho AKS node |
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
- 1 node pool `Standard_B2s` với SystemAssigned identity
- OIDC Issuer + Workload Identity enabled
- Network: Azure CNI + Calico network policy
- Role assignment `AcrPull` để pull image từ ACR

### ACR
- SKU: Basic
- Admin access: disabled (sử dụng managed identity thay vì admin credentials)

### Key Vault
- SKU: Standard
- Authorization: RBAC (không dùng access policy)
- Soft delete: 7 ngày
- Purge protection: disabled
- Role: Key Vault Administrator cho current user

## Lưu ý

> **⚠️ Region Policy**: Subscription chỉ cho phép các region: `koreacentral`, `japanwest`, `centralindia`, `indonesiacentral`, `japaneast`. Project sử dụng `japaneast`.

> **🔒 Bảo mật**: File `terraform.tfvars` chứa giá trị cấu hình thực và đã được thêm vào `.gitignore`. Không commit file này lên Git.

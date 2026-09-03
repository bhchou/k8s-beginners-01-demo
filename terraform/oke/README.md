 # OCI OKE with Terraform

使用 Terraform 在既有 OCI VCN 上建立 Oracle Kubernetes Engine (OKE) Lab 環境。

本範例延續前一個 IaC Lab 所建立的 OCI Network，不重新建立 VCN，而是在既有 VCN 上增加 OKE 所需的 Private Network、OKE Basic Cluster 與 Worker Node Pool。

> 本範例以教學與 Lab 為目的，部分 Network Security 設定刻意簡化。
> Production 環境請依實際需求與 OCI OKE 官方 Network Requirements 收斂 Security List / NSG。

---

## Architecture

既有 IaC Lab 已建立：

```text
demo-vcn
├─ Internet Gateway
└─ public-subnet
```

本 Terraform 在既有 `demo-vcn` 上增加：

```text
demo-vcn
│
├─ Existing resources
│  ├─ Internet Gateway
│  └─ public-subnet
│
└─ OKE resources
   ├─ NAT Gateway
   ├─ Service Gateway
   ├─ OKE Route Table
   │  ├─ 0.0.0.0/0
   │  │    └─ NAT Gateway
   │  │
   │  └─ All <Region> Services in Oracle Services Network
   │       └─ Service Gateway
   │
   ├─ OKE Security List
   └─ OKE Private Subnet
        ├─ Private Kubernetes API Endpoint
        └─ OKE Worker Nodes
```

OKE Cluster 使用：

- **OKE Basic Cluster**
- Private Kubernetes API Endpoint
- Flannel Overlay CNI
- 2 Worker Nodes
- Default Worker Shape: `VM.Standard.A1.Flex`
- Default Worker Architecture: `AARCH64`
- Default Worker Resources: `1 OCPU / 6 GB RAM` per node

Kubernetes version 與 Node Shape 可透過 Terraform variables 調整。

---

## Prerequisites

執行前需要：

- OCI Account
- OCI CLI
- Terraform
- kubectl
- OCI API Signing Key
- SSH Public Key
- 已存在的 OCI Compartment
- 已存在的 VCN

本 Lab 預期前一個 IaC Lab 已建立：

```text
demo-compartment
└─ demo-vcn
```

Terraform 會透過 OCI Data Source 查詢既有資源，而不是重新建立。

---

## Terraform Variables

請依環境設定 Terraform variables，請看`terraform.tfvars.template`的範例, 例如：

```hcl
tenancy_ocid     = "ocid1.tenancy..."
user_ocid        = "ocid1.user..."
fingerprint      = "..."
private_key_path = "~/.oci/oci_api_key.pem"

region           = "ap-osaka-1"

compartment_name = "demo-compartment"
vcn_name         = "demo-vcn"

k8s_name         = "demo-k8s"

k8s_pods_cidr     = "10.244.0.0/16"
k8s_services_cidr = "10.96.0.0/16"

node_ssh_public_key_path = "~/.ssh/id_ed25519.pub"
```

再存成 `terraform.tfvars`

**但不要將實際 credentials、Private Key 或包含敏感資訊的 `terraform.tfvars` commit 到 Git Repository。**

---

## Dynamic OKE Worker Image Selection

不要在 Terraform hard-code 舊的 OCI Worker Image OCID。

OKE 可透過 Node Pool Options API 回傳目前 Kubernetes Version 與 CPU Architecture 可使用的 Worker Images。

本範例使用：

```hcl
data "oci_containerengine_node_pool_option" "oke" {
  node_pool_option_id = "all"

  compartment_id        = local.compartment_id
  node_pool_k8s_version = var.k8s_version
  node_pool_os_arch     = var.node_arch
}
```

再從 OKE 支援的 Image Sources 中選擇 Worker Image。

這可以避免類似：

```text
Oracle-Linux-8.x-aarch64-2022...
```

這種多年後已經失效的 Image OCID 留在 Terraform configuration 中。

---

## Create OKE

先初始化 Terraform：

```bash
terraform init
```

檢查：

```bash
terraform fmt
terraform validate
```

確認變更：

```bash
terraform plan
```

建立：

```bash
terraform apply
```

實際 Lab 測試環境中，建立時間約為：

```text
OKE Basic Cluster     ~ 6 min 20 sec
OKE Node Pool         ~ 2 min
```

實際時間仍會受到 OCI Region、Compute Capacity 與 Service 狀態影響。

---

# Network Notes

## Why does OKE use a dedicated Private Subnet?

Worker Nodes 沒有配置 Public IP：

```text
OKE Private Subnet
└─ Worker Node
     └─ Private IP only
```

因此不能只將：

```text
0.0.0.0/0
    ↓
Internet Gateway
```

當成 Worker Node 的 Internet outbound path。

Private Worker Node 需要：

```text
Worker Node
    ↓
Private Subnet
    ↓
NAT Gateway
    ↓
Internet
```

OCI Services 則可透過：

```text
Worker Node
    ↓
Service Gateway
    ↓
Oracle Services Network
```

存取。

---

## Service Gateway Destination

Oracle Services Network 的 Service CIDR 名稱會依 Region 不同。

例如：

```text
Tokyo (ap-tokyo-1)
→ All NRT Services In Oracle Services Network

Osaka (ap-osaka-1)
→ All KIX Services In Oracle Services Network
```

因此 Terraform 不應 hard-code `NRT` 或 `KIX`。

本範例透過：

```hcl
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}
```

取得目前 Region 對應的 Oracle Services Network。

---

# Accessing the Private Kubernetes API

本 Lab 的 Kubernetes API Endpoint 不配置 Public IP。

```text
Local Machine
      │
      │ SSH Tunnel
      ▼
OCI Bastion
      │
      │ VCN Internal Network
      ▼
OKE Private API :6443
```

因此需要先建立 OCI Bastion Session，再透過 SSH Local Port Forwarding 存取 Kubernetes API。

例如將：

```text
127.0.0.1:6443
```

forward 到 OKE Private API Endpoint：

```text
<OKE Private IP>:6443
```

Bastion 不一定需要和 OKE 位於相同 Subnet。

只要位於同一 VCN，且 Security List / NSG 允許相關流量，即可透過 VCN internal routing 存取 OKE Private Endpoint。

---

## Create kubeconfig

取得 Cluster ID：

```bash
CLUSTER_ID=$(terraform output -raw cluster_id)
```

建立獨立 kubeconfig，例如：

```bash
oci ce cluster create-kubeconfig \
  --cluster-id "$CLUSTER_ID" \
  --file "$HOME/.kube/config-ipas" \
  --region ap-osaka-1 \
  --token-version 2.0.0 \
  --kube-endpoint PRIVATE_ENDPOINT \
  --config-file "$HOME/.oci/config_ipas"
```

使用獨立 kubeconfig：

```bash
export KUBECONFIG="$HOME/.kube/config-ipas"
```

確認：

```bash
kubectl config get-contexts
```

**請看下面的注意事項修改這個獨立config的值**

---

# 注意事項

## OKE的子網路路由與安全設定

### 狀況

原本 Worker Nodes 使用既有 Subnet。

該 Subnet：

```text
0.0.0.0/0
    ↓
Internet Gateway
```

但 Worker Node 只有 Private IP。

因此雖然 Compute Instance 可以建立並取得 Private IP，Worker Node 卻沒有適當的 outbound network path 完成 OKE bootstrap / registration。

### 修正

為 OKE 建立獨立 Private Subnet：

```text
OKE Private Subnet
├─ 0.0.0.0/0
│    └─ NAT Gateway
│
└─ Oracle Services Network
     └─ Service Gateway
```

修改後重新建立：

```text
OKE Cluster     SUCCESS
Node Pool       SUCCESS
Worker Nodes    Ready
```

---

## KUBECONFIG 調整 -- 使用 `Bastion` 轉發流量的狀況下

如果看到：

```text
tls: failed to verify certificate:
x509: certificate signed by unknown authority
```

先確認目前 kubectl 實際使用哪一個 kubeconfig：

```bash
echo "$KUBECONFIG"

kubectl config view --minify --raw
```

特別確認：

```yaml
clusters:
- cluster:
    certificate-authority-data: ...
    server: https://127.0.0.1:6443
```

如果曾經 destroy/recreate OKE Cluster，請勿繼續使用舊 Cluster 的 kubeconfig，因為新的 Cluster 會有不同的 Kubernetes CA。

重新產生 kubeconfig 即可。

---

## kubectl: `the server has asked for the client to provide credentials` : 使用非預設KUBECONFIG檔名的狀況下

可能看到：

```text
error: You must be logged in to the server
(the server has asked for the client to provide credentials)
```

OKE kubeconfig 使用 OCI CLI 動態產生 authentication token：

```yaml
users:
- user:
    exec:
      command: oci
      args:
      - ce
      - cluster
      - generate-token
      ...
```

如果 OCI credentials 不在預設：

```text
~/.oci/config
```

而是使用另一個 config，例如：

```text
~/.oci/config.ipas
```

則 kubeconfig 中的 `generate-token` 也必須使用相同 OCI config。

先測試：

```bash
oci ce cluster generate-token \
  --cluster-id <CLUSTER_OCID> \
  --region ap-osaka-1 \
  --config-file ~/.oci/config.ipas
```

如果可以正常取得 token，將 kubeconfig 的 exec args 加入：

```yaml
- --config-file
- /home/<user>/.oci/config.ipas
```

例如：

```yaml
users:
- name: user-xxxxx
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: oci
      args:
      - ce
      - cluster
      - generate-token
      - --cluster-id
      - ocid1.cluster...
      - --region
      - ap-osaka-1
      - --config-file
      - /home/<user>/.oci/config.ipas
```

建議使用 absolute path。

---

# Cleanup

Lab 結束後可刪除 Terraform 所管理的 OKE Resources：

```bash
terraform destroy
```

執行前請確認 Terraform State 中只包含本 Lab 預期刪除的資源。

既有 `demo-vcn` 等前一堂 IaC Lab 建立的資源是透過 Terraform Data Source 引用，不應由本 Terraform project 刪除。

---

## Security Notes

本 Lab 的目標是理解 Kubernetes / OKE，而不是建立 Production-grade OCI Network。

因此 Security List 採較簡化的設定，例如允許 VCN 內部流量。

Production 環境應另外考慮：

- Security List / NSG Least Privilege
- Kubernetes API Endpoint Access
- Worker Node Network Segmentation
- Kubernetes NetworkPolicy
- IAM / RBAC
- Secrets Management
- Container Image Security
- Logging / Monitoring
- Runtime Security

> **Managed Kubernetes ≠ Secure by Default**


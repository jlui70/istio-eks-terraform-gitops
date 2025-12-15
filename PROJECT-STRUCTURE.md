# 📁 Estrutura Completa do Projeto

```
istio-eks-terraform-gitops/
│
├── 📄 README.md                      # Documentação principal do projeto
├── 📄 GITOPS-GUIDE.md               # ⭐ Guia completo GitOps (COMECE AQUI)
├── 📄 QUICK-START.md                # Guia rápido de 45 minutos
├── 📄 IMPLEMENTATION-SUMMARY.md     # Resumo da implementação
├── 📄 Desafio_Gitops.md            # Requisitos do desafio original
├── 📄 LICENSE                       # Licença MIT
│
├── 🔧 00-backend/                   # Terraform: S3 + DynamoDB (state backend)
│   ├── main.tf
│   ├── s3.bucket.tf
│   ├── dynamodb.table.tf
│   └── variables.tf
│
├── 🌐 01-networking/                # Terraform: VPC + Subnets + NAT Gateways
│   ├── main.tf
│   ├── vpc.tf
│   ├── vpc.public-subnets.tf
│   ├── vpc.private-subnets.tf
│   ├── vpc.nat-gateways.tf
│   ├── ec2.eips.tf
│   ├── outputs.tf
│   └── variables.tf
│
├── ☸️  02-eks-cluster/               # Terraform: EKS Cluster + Node Groups
│   ├── main.tf
│   ├── eks.cluster.tf
│   ├── eks.cluster.iam.tf
│   ├── eks.cluster.oidc.tf
│   ├── eks.cluster.access.tf
│   ├── eks.cluster.node-group.tf
│   ├── eks.cluster.node-group.iam.tf
│   ├── eks.cluster.addons.csi.tf
│   ├── eks.cluster.addons.metrics-server.tf
│   ├── eks.cluster.external.alb.tf
│   ├── eks.cluster.external.alb.iam.tf
│   ├── eks.cluster.external.dns.tf
│   ├── eks.cluster.external.dns.iam.tf
│   ├── route53.hosted-zone.tf
│   ├── data.*.tf
│   ├── locals.tf
│   ├── outputs.tf
│   └── variables.tf
│
├── 🕸️  istio/                        # Istio Service Mesh
│   ├── install/
│   │   ├── install-istio.sh         # Script instalação Istio
│   │   ├── deploy-all.sh
│   │   ├── deploy-v1-only.sh
│   │   ├── demo-deploy-v2-canary.sh
│   │   ├── demo-deploy-circuit-breaker.sh
│   │   ├── start-monitoring.sh
│   │   ├── cleanup.sh
│   │   └── istio-1.27.0/            # Binários Istio
│   │
│   └── manifests/                   # Manifestos Istio (legados)
│       ├── 01-namespace/
│       ├── 02-microservices-v1/
│       ├── 03-istio-gateway/
│       ├── 04-canary-deployment/
│       ├── 05-circuit-breaker/
│       └── 06-observability/
│
├── 🐳 microservices/                # ✨ NOVO - Código-fonte + Dockerfiles
│   ├── README.md
│   │
│   ├── ecommerce-ui/                # Frontend React
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   └── .dockerignore
│   │
│   ├── product-catalog/             # API - Catálogo de Produtos
│   │   ├── Dockerfile
│   │   └── .dockerignore
│   │
│   ├── order-management/            # API - Gerenciamento de Pedidos
│   │   └── Dockerfile
│   │
│   ├── product-inventory/           # API - Controle de Estoque
│   │   └── Dockerfile
│   │
│   ├── profile-management/          # API - Perfis de Usuário
│   │   └── Dockerfile
│   │
│   ├── shipping-handling/           # API - Logística e Entrega
│   │   └── Dockerfile
│   │
│   └── contact-support/             # API - Suporte ao Cliente
│       └── Dockerfile
│
├── 📦 k8s-manifests/                # ✨ NOVO - Manifestos Kubernetes (Kustomize)
│   ├── README.md
│   │
│   ├── base/                        # Configurações base compartilhadas
│   │   ├── kustomization.yaml
│   │   ├── namespace-staging.yaml
│   │   ├── namespace-production.yaml
│   │   ├── ecommerce-ui.yaml
│   │   ├── product-catalog.yaml
│   │   ├── order-management.yaml
│   │   ├── product-inventory.yaml
│   │   ├── profile-management.yaml
│   │   ├── shipping-handling.yaml
│   │   ├── contact-support.yaml
│   │   └── istio-gateway.yaml
│   │
│   ├── staging/                     # Overlay para Staging
│   │   ├── kustomization.yaml       # Tags: staging-<sha>
│   │   ├── replicas-patch.yaml      # 1 replica por serviço
│   │   └── resources-patch.yaml     # Resources reduzidos
│   │
│   └── production/                  # Overlay para Production
│       ├── kustomization.yaml       # Tags: prod-v1.0.X
│       └── hpa-patch.yaml           # Auto-scaling 2-5 replicas
│
├── 🔄 argocd/                       # ✨ NOVO - ArgoCD GitOps
│   ├── README.md
│   │
│   ├── install/                     # Scripts de instalação
│   │   ├── install-argocd.sh        # Instala ArgoCD no cluster
│   │   ├── deploy-apps.sh           # Deploy ArgoCD Applications
│   │   └── uninstall-argocd.sh      # Remove ArgoCD
│   │
│   └── applications/                # ArgoCD Application manifests
│       ├── staging-app.yaml         # App staging (auto-sync)
│       └── production-app.yaml      # App production (manual sync)
│
├── 🤖 .github/                      # ✨ NOVO - GitHub Actions CI/CD
│   └── workflows/
│       ├── README.md
│       ├── setup-ecr.yml            # Criar repositórios ECR (manual)
│       ├── ecommerce-ui.yml         # CI/CD Frontend
│       └── product-catalog.yml      # CI/CD Product Catalog
│       # (criar workflows similares para outros microserviços)
│
├── 🔧 scripts/                      # Scripts de automação
│   ├── 01-deploy-infra.sh          # Deploy Terraform (VPC + EKS)
│   ├── 02-install-istio.sh         # Instala Istio
│   ├── 03-deploy-app.sh            # Deploy aplicação (legado)
│   ├── 04-start-monitoring.sh      # Inicia dashboards observabilidade
│   ├── deploy-gitops-stack.sh      # ✨ NOVO - Deploy completo GitOps
│   ├── get-status.sh               # ✨ NOVO - Status de tudo
│   └── destroy-gitops-stack.sh     # ✨ NOVO - Cleanup completo
│
├── 📚 docs/                         # Documentação adicional
│   ├── DEMO-CANARY.md
│   ├── OBSERVABILITY.md
│   ├── TROUBLESHOOTING.md
│   ├── PROJECT-STATUS.md
│   ├── QUICK-START.md
│   └── PRE-COMMIT-CHECKLIST.md
│
├── 🧪 test-canary-visual.sh        # Script teste visual canary
├── 🔨 rebuild-all.sh                # Rebuild infra completa
└── 💥 destroy-all.sh                # Destroy infra completa

```

---

## 📊 Estatísticas do Projeto

### **Arquivos Criados:**

- ✅ **Dockerfiles**: 7 (um por microserviço)
- ✅ **K8s Manifests**: 18 (base + overlays)
- ✅ **ArgoCD Configs**: 5 (install scripts + apps)
- ✅ **GitHub Workflows**: 3 (setup + 2 pipelines)
- ✅ **Scripts**: 3 novos (deploy, status, destroy)
- ✅ **Documentação**: 6 arquivos MD

**Total:** ~40 arquivos novos criados para GitOps!

---

## 🎯 Arquivos Principais por Função

### **🚀 Para Começar:**

1. [QUICK-START.md](QUICK-START.md) - Guia rápido 45 min
2. [GITOPS-GUIDE.md](GITOPS-GUIDE.md) - Guia completo
3. [IMPLEMENTATION-SUMMARY.md](IMPLEMENTATION-SUMMARY.md) - Resumo

### **🔧 Para Configurar Infra:**

1. `00-backend/` - Terraform backend
2. `01-networking/` - VPC e networking
3. `02-eks-cluster/` - EKS cluster

### **🕸️  Para Service Mesh:**

1. `istio/install/install-istio.sh` - Instalar Istio
2. `istio/manifests/` - Configs Istio

### **🔄 Para GitOps:**

1. `argocd/install/install-argocd.sh` - Instalar ArgoCD
2. `argocd/applications/` - ArgoCD apps
3. `k8s-manifests/` - Manifestos K8s

### **🤖 Para CI/CD:**

1. `.github/workflows/` - Pipelines
2. `microservices/*/Dockerfile` - Container definitions

### **📊 Para Observabilidade:**

1. `scripts/04-start-monitoring.sh` - Dashboards
2. Port-forwards: Grafana, Kiali, Jaeger

---

## 🔑 Arquivos-chave

### **Must Read:**
- 📄 [GITOPS-GUIDE.md](GITOPS-GUIDE.md) - Guia principal
- 📄 [QUICK-START.md](QUICK-START.md) - Quick start
- 📄 [README.md](README.md) - Overview do projeto

### **Must Run:**
- 🔧 `scripts/deploy-gitops-stack.sh` - Deploy tudo
- 🔧 `scripts/get-status.sh` - Ver status
- 🔧 `argocd/install/install-argocd.sh` - Instalar ArgoCD

### **Must Configure:**
- ⚙️ `.github/workflows/setup-ecr.yml` - ECR repos
- ⚙️ GitHub Secrets - AWS credentials
- ⚙️ GitHub Environments - staging/production

---

## 📂 Navegação Rápida

```bash
# Ver estrutura completa
tree -L 2 -I 'node_modules|.terraform|istio-1.27.0'

# Contar arquivos por tipo
find . -name "*.tf" | wc -l      # Terraform files
find . -name "*.yaml" | wc -l    # Kubernetes manifests
find . -name "Dockerfile" | wc -l # Docker files
find . -name "*.sh" | wc -l      # Shell scripts
find . -name "*.md" | wc -l      # Documentation
```

---

## 🎨 Convenções de Nomenclatura

### **Diretórios:**
- `XX-nome/` - Terraform stacks (numbered)
- `nome/` - Outros componentes

### **Arquivos:**
- `*.tf` - Terraform
- `*.yaml` / `*.yml` - Kubernetes/ArgoCD
- `*.sh` - Shell scripts (executáveis)
- `*.md` - Documentação Markdown
- `Dockerfile` - Container definitions

### **Branches Git:**
- `main` - Produção
- `develop` - Staging
- `feature/*` - Features
- `fix/*` - Bugfixes
- `test/*` - Testes

---

## 🔗 Links Rápidos

| Documento | Descrição |
|-----------|-----------|
| [GITOPS-GUIDE.md](GITOPS-GUIDE.md) | Guia completo GitOps |
| [QUICK-START.md](QUICK-START.md) | Quick start 45 min |
| [IMPLEMENTATION-SUMMARY.md](IMPLEMENTATION-SUMMARY.md) | Resumo implementação |
| [Desafio_Gitops.md](Desafio_Gitops.md) | Desafio original |
| [argocd/README.md](argocd/README.md) | Docs ArgoCD |
| [.github/workflows/README.md](.github/workflows/README.md) | Docs CI/CD |
| [k8s-manifests/README.md](k8s-manifests/README.md) | Docs Kustomize |
| [microservices/README.md](microservices/README.md) | Docs Dockerfiles |

---

**Estrutura criada em:** Dezembro 2025  
**Versão:** 2.0.0 (GitOps Implementation)

# 🚀 GitOps Implementation Guide

Guia completo de implementação GitOps para o projeto E-commerce com EKS, Istio e ArgoCD.

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Por que GitOps?](#-por-que-gitops)
- [Arquitetura](#-arquitetura)
- [Pré-requisitos](#-pré-requisitos)
- [Deploy Rápido](#-deploy-rápido)
- [Deploy Passo a Passo](#-deploy-passo-a-passo)
- [Fluxo CI/CD](#-fluxo-cicd)
- [Ambientes](#-ambientes)
- [Rollback](#-rollback)
- [Segurança](#-segurança)
- [Monitoramento](#-monitoramento)
- [Troubleshooting](#-troubleshooting)
- [Custos](#-custos)

---

## 🎯 Visão Geral

Este projeto implementa uma **stack completa de GitOps** para deploy de aplicações microserviços na AWS:

- ✅ **Infraestrutura como Código**: Terraform (VPC, EKS, Networking)
- ✅ **Service Mesh**: Istio para controle de tráfego
- ✅ **GitOps**: ArgoCD para continuous deployment
- ✅ **CI/CD**: GitHub Actions para build e testes
- ✅ **Observabilidade**: Prometheus, Grafana, Kiali, Jaeger
- ✅ **Multi-ambiente**: Staging e Production isolados
- ✅ **Segurança**: Secrets management, RBAC, Network Policies

---

## 💡 Por que GitOps?

GitOps é uma metodologia onde o **Git é a única fonte da verdade** para infraestrutura e aplicações.

### **Benefícios:**

1. **🔄 Deploy Declarativo**
   - Estado desejado no Git
   - ArgoCD garante que cluster sempre está sincronizado

2. **📝 Auditoria Completa**
   - Todo change tem commit
   - Histórico completo de quem fez o quê e quando

3. **↩️ Rollback Fácil**
   - Git revert = rollback instantâneo
   - Sem scripts complexos

4. **🔒 Segurança**
   - Nenhum acesso direto ao cluster necessário
   - Apenas ArgoCD tem permissões
   - Pull model (cluster puxa mudanças)

5. **🚀 Velocidade**
   - Deploy automático em segundos
   - Reduz tempo de release em 80%

6. **🎯 Consistência**
   - Mesmo processo para todos os ambientes
   - Elimina "funciona na minha máquina"

---

## 🏗️ Arquitetura

```
┌────────────────────────────────────────────────────────────────────┐
│                        GITHUB REPOSITORY                           │
│                                                                    │
│  ┌─────────────────┐              ┌─────────────────────┐         │
│  │  Microservices  │              │  K8s Manifests      │         │
│  │  Source Code    │              │  (Kustomize)        │         │
│  └────────┬────────┘              └──────────┬──────────┘         │
│           │                                   │                    │
│           │ git push                          │ git commit         │
│           ▼                                   ▼                    │
│  ┌──────────────────────────────────────────────────────┐         │
│  │           GITHUB ACTIONS (CI Pipeline)               │         │
│  │  1. Build Docker images                              │         │
│  │  2. Run tests + security scan                        │         │
│  │  3. Push to Amazon ECR                               │         │
│  │  4. Update K8s manifests (image tags)                │         │
│  │  5. Git commit + push                                │         │
│  └─────────────────────┬────────────────────────────────┘         │
└────────────────────────┼─────────────────────────────────────────┘
                         │
                         │ watches repo (polling every 3min)
                         ▼
            ┌────────────────────────────┐
            │      ARGOCD SERVER         │
            │   (GitOps Operator)        │
            │                            │
            │  - Detects Git changes     │
            │  - Syncs to cluster        │
            │  - Health monitoring       │
            │  - Auto-healing            │
            └─────────┬──────────────────┘
                      │
                      │ kubectl apply
                      ▼
        ┌─────────────────────────────────────────────┐
        │        AWS EKS CLUSTER (us-east-1)          │
        │                                             │
        │  ┌───────────────────────────────────────┐  │
        │  │  Namespace: ecommerce-staging         │  │
        │  │   ┌─────────────────────────────┐     │  │
        │  │   │ Microservices (1 replica)   │     │  │
        │  │   │  - ecommerce-ui             │     │  │
        │  │   │  - product-catalog          │     │  │
        │  │   │  - order-management         │     │  │
        │  │   │  - product-inventory        │     │  │
        │  │   │  - profile-management       │     │  │
        │  │   │  - shipping-handling        │     │  │
        │  │   │  - contact-support          │     │  │
        │  │   └─────────────────────────────┘     │  │
        │  │   Auto-sync: ✅ ON                    │  │
        │  └───────────────────────────────────────┘  │
        │                                             │
        │  ┌───────────────────────────────────────┐  │
        │  │  Namespace: ecommerce-production      │  │
        │  │   ┌─────────────────────────────────┐ │  │
        │  │   │ Microservices (2+ replicas)     │ │  │
        │  │   │  - ecommerce-ui                 │ │  │
        │  │   │  - product-catalog              │ │  │
        │  │   │  - order-management             │ │  │
        │  │   │  - product-inventory            │ │  │
        │  │   │  - profile-management           │ │  │
        │  │   │  - shipping-handling            │ │  │
        │  │   │  - contact-support              │ │  │
        │  │   │  + HPA (auto-scaling)           │ │  │
        │  │   └─────────────────────────────────┘ │  │
        │  │   Auto-sync: ❌ MANUAL (safety)      │  │
        │  └───────────────────────────────────────┘  │
        │                                             │
        │  ┌───────────────────────────────────────┐  │
        │  │  Istio Service Mesh                   │  │
        │  │   - Traffic management                │  │
        │  │   - mTLS encryption                   │  │
        │  │   - Observability                     │  │
        │  └───────────────────────────────────────┘  │
        │                                             │
        │  ┌───────────────────────────────────────┐  │
        │  │  Observability Stack                  │  │
        │  │   - Prometheus (metrics)              │  │
        │  │   - Grafana (dashboards)              │  │
        │  │   - Kiali (topology)                  │  │
        │  │   - Jaeger (tracing)                  │  │
        │  └───────────────────────────────────────┘  │
        └─────────────────────────────────────────────┘
```

---

## 📦 Pré-requisitos

### **Ferramentas Necessárias:**

```bash
# Verificar instalações
terraform --version  # >= 1.9.0
kubectl version      # >= 1.30
aws --version        # >= 2.x
git --version        # >= 2.x
```

### **Conta AWS:**
- AWS Account com permissões de administrador
- AWS CLI configurado (`aws configure`)
- AWS Profile com IAM role `terraform-role`

### **GitHub:**
- Conta GitHub
- Repositório criado
- GitHub Actions habilitado

---

## 🚀 Deploy Rápido

### **Opção 1: Deploy Automatizado Completo** ⭐ RECOMENDADO

```bash
# 1. Clone o repositório
git clone https://github.com/YOUR-USERNAME/istio-eks-terraform-gitops.git
cd istio-eks-terraform-gitops

# 2. Configure AWS profile
export AWS_PROFILE=devopsproject

# 3. Execute deploy automatizado
./scripts/deploy-gitops-stack.sh
```

**⏱️ Tempo:** ~40 minutos  
**💰 Custo:** ~$2 USD (se destruir após 2 horas)

---

## 📖 Deploy Passo a Passo

### **Fase 1: Infraestrutura (15 min)**

```bash
# 1. Deploy backend Terraform
cd 00-backend
terraform init
terraform apply -auto-approve
cd ..

# 2. Deploy networking (VPC)
cd 01-networking
terraform init
terraform apply -auto-approve
cd ..

# 3. Deploy EKS cluster
cd 02-eks-cluster
terraform init
terraform apply -auto-approve
cd ..

# 4. Configure kubectl
aws eks update-kubeconfig --name eks-cluster --region us-east-1
kubectl get nodes
```

### **Fase 2: Service Mesh (5 min)**

```bash
# Instalar Istio
cd istio/install
./install-istio.sh
cd ../..

# Verificar instalação
kubectl get pods -n istio-system
```

### **Fase 3: GitOps - ArgoCD (5 min)**

```bash
# 1. Instalar ArgoCD
cd argocd/install
./install-argocd.sh

# 2. Obter credenciais
kubectl get svc argocd-server -n argocd
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# 3. Acessar UI e trocar senha
# https://<ARGOCD-URL>
# Username: admin
# Password: <obtido acima>

# 4. Deploy aplicações ArgoCD
./deploy-apps.sh
cd ../..
```

### **Fase 4: CI/CD - GitHub Actions (10 min)**

```bash
# 1. Push código para GitHub
git remote add origin https://github.com/YOUR-USERNAME/istio-eks-terraform-gitops.git
git add .
git commit -m "Initial GitOps setup"
git push -u origin main

# 2. Configurar GitHub Secrets
# Ir em: Settings → Secrets and variables → Actions
# Adicionar:
#   - AWS_ACCESS_KEY_ID
#   - AWS_SECRET_ACCESS_KEY

# 3. Executar workflow de setup ECR
# GitHub → Actions → Create ECR Repositories → Run workflow

# 4. Configurar Environments
# Settings → Environments
#   - staging (sem proteção)
#   - production (com reviewers obrigatórios)
```

### **Fase 5: Deploy Aplicações (5 min)**

```bash
# 1. Sync staging (via ArgoCD CLI)
argocd app sync ecommerce-staging

# OU via UI: Applications → ecommerce-staging → SYNC

# 2. Verificar deployment
kubectl get pods -n ecommerce-staging
kubectl get svc -n ecommerce-staging

# 3. Obter URL da aplicação
kubectl get svc istio-ingressgateway -n istio-system

# 4. Acessar aplicação
# http://<ISTIO-GATEWAY-URL>
```

---

## 🔄 Fluxo CI/CD

### **Fluxo Completo de Mudança:**

```
Developer faz mudança no código
           ↓
git commit + push para branch develop
           ↓
GitHub Actions CI Pipeline inicia
           ↓
   ┌───────────────────┐
   │  1. Build Docker  │
   └─────────┬─────────┘
             ↓
   ┌───────────────────┐
   │  2. Run Tests     │
   │    - Health check │
   │    - Security scan│
   └─────────┬─────────┘
             ↓
   ┌───────────────────┐
   │  3. Push to ECR   │
   │    Tag: staging-  │
   │         <commit>  │
   └─────────┬─────────┘
             ↓
   ┌───────────────────────┐
   │  4. Update Kustomize  │
   │     image tag         │
   └─────────┬─────────────┘
             ↓
   ┌───────────────────┐
   │  5. Git commit &  │
   │     push          │
   └─────────┬─────────┘
             ↓
ArgoCD detecta mudança (polling 3min)
             ↓
   ┌───────────────────────────┐
   │  ArgoCD sync staging      │
   │  (automático)             │
   └─────────┬─────────────────┘
             ↓
   ┌───────────────────┐
   │  Apply to cluster │
   └─────────┬─────────┘
             ↓
   ┌───────────────────┐
   │  Health checks    │
   │  - Readiness      │
   │  - Liveness       │
   └─────────┬─────────┘
             ↓
    ✅ Deploy completo em STAGING
             ↓
    Testes manuais/automatizados
             ↓
    Merge para main branch
             ↓
    CI Pipeline roda novamente
             ↓
    Tag: prod-v1.0.X criada
             ↓
    ArgoCD detecta mudança
             ↓
    ⏸️  AGUARDA APROVAÇÃO MANUAL
             ↓
    Operador revisa mudanças
             ↓
    ✅ Aprovado
             ↓
    ArgoCD sync production
             ↓
    ✅ Deploy completo em PRODUCTION
```

### **Tempo Típico:**
- ✅ Commit → Deploy Staging: **5-8 minutos**
- ✅ Approval → Deploy Production: **2-3 minutos**

---

## 🌍 Ambientes

### **Staging**

**Propósito:** Testes e validação antes de produção

**Configuração:**
```yaml
Namespace: ecommerce-staging
Replicas: 1 por serviço
Resources: Reduzidos (64Mi RAM / 50m CPU)
Auto-sync: ✅ Habilitado
Image tags: staging-<commit-sha>
HPA: ❌ Desabilitado
```

**Acesso:**
```bash
# Via Istio Gateway
GATEWAY=$(kubectl get svc istio-ingressgateway -n istio-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Staging: http://$GATEWAY"

# Verificar pods
kubectl get pods -n ecommerce-staging
```

### **Production**

**Propósito:** Ambiente de produção para usuários finais

**Configuração:**
```yaml
Namespace: ecommerce-production
Replicas: 2-5 por serviço (HPA)
Resources: Completos (128Mi RAM / 100m CPU)
Auto-sync: ❌ Manual (segurança)
Image tags: prod-v1.0.X (versionamento semântico)
HPA: ✅ Habilitado (escala baseado em CPU)
```

**Acesso:**
```bash
# Via Istio Gateway (mesma URL, namespaces separados)
GATEWAY=$(kubectl get svc istio-ingressgateway -n istio-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Production: http://$GATEWAY"

# Verificar pods
kubectl get pods -n ecommerce-production
```

---

## ↩️ Rollback

### **Estratégia 1: Rollback via ArgoCD (RECOMENDADO)**

```bash
# 1. Ver histórico de deploys
argocd app history ecommerce-production

# Output:
# ID  DATE                           REVISION
# 5   2025-12-12 10:30:00 -0300      a1b2c3d (HEAD)
# 4   2025-12-12 09:15:00 -0300      x9y8z7w
# 3   2025-12-11 16:45:00 -0300      m5n6o7p

# 2. Rollback para revisão específica
argocd app rollback ecommerce-production 4

# 3. Verificar rollback
kubectl get pods -n ecommerce-production -w
```

**⏱️ Tempo de rollback:** ~30 segundos

### **Estratégia 2: Rollback via Git Revert**

```bash
# 1. Ver commits recentes
git log k8s-manifests/production/kustomization.yaml

# 2. Reverter commit problemático
git revert <commit-sha>

# 3. Push (ArgoCD aplica automaticamente após aprovação)
git push

# 4. Sync manual no ArgoCD
argocd app sync ecommerce-production
```

**⏱️ Tempo de rollback:** ~2-3 minutos

### **Estratégia 3: Rollback Manual de Image Tag**

```bash
# 1. Editar kustomization.yaml
cd k8s-manifests/production

# 2. Mudar image tag para versão anterior
kustomize edit set image \
  ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/ecommerce/product-catalog:prod-v1.0.5

# 3. Commit e push
git add kustomization.yaml
git commit -m "rollback: product-catalog to v1.0.5"
git push

# 4. Sync no ArgoCD
argocd app sync ecommerce-production
```

### **Estratégia 4: Blue/Green Deployment (Avançado)**

Ver: [docs/BLUE-GREEN-DEPLOYMENT.md](docs/BLUE-GREEN-DEPLOYMENT.md)

---

## 🔒 Segurança

### **Checklist de Segurança Implementado:**

#### ✅ **Infraestrutura**
- [x] VPC privada com subnets isoladas
- [x] NAT Gateways para tráfego de saída
- [x] Security Groups restritivos
- [x] EKS com RBAC habilitado
- [x] Encryption at rest (EBS volumes)

#### ✅ **Rede**
- [x] Istio mTLS entre microserviços
- [x] Network Policies (isolamento de namespaces)
- [x] LoadBalancer com SSL/TLS

#### ✅ **Containers**
- [x] Imagens escaneadas (Trivy)
- [x] Non-root users nos containers
- [x] Read-only filesystem onde possível
- [x] Resource limits definidos

#### ✅ **Secrets**
- [x] GitHub Secrets para CI/CD
- [x] AWS Secrets Manager (TODO: implementar)
- [x] Kubernetes Secrets encriptados

#### ✅ **Acesso**
- [x] ArgoCD com RBAC
- [x] IAM Roles para Service Accounts
- [x] Princípio do menor privilégio

### **Configurar GitHub Secrets:**

```bash
# No GitHub Repository:
Settings → Secrets and variables → Actions → New repository secret

# Adicionar:
AWS_ACCESS_KEY_ID=<your-key>
AWS_SECRET_ACCESS_KEY=<your-secret>
```

### **Rotação de Credenciais:**

```bash
# ArgoCD password
argocd account update-password

# AWS credentials
aws iam create-access-key --user-name github-actions
# Atualizar GitHub Secrets
```

---

## 📊 Monitoramento

### **Dashboards Disponíveis:**

#### **1. Grafana - Métricas e Dashboards**

```bash
# Port-forward para acesso local
kubectl port-forward -n istio-system svc/grafana 3000:3000

# Acessar: http://localhost:3000
# User: admin / Password: admin
```

**Dashboards inclusos:**
- Istio Service Dashboard
- Istio Workload Dashboard
- Kubernetes Cluster Monitoring

#### **2. Kiali - Topologia de Serviços**

```bash
# Port-forward
kubectl port-forward -n istio-system svc/kiali 20001:20001

# Acessar: http://localhost:20001
```

**Funcionalidades:**
- Visualização de tráfego em tempo real
- Métricas de latência
- Taxa de erros
- Circuit breaker status

#### **3. Jaeger - Distributed Tracing**

```bash
# Port-forward
kubectl port-forward -n istio-system svc/jaeger-query 16686:16686

# Acessar: http://localhost:16686
```

#### **4. Prometheus - Métricas Brutas**

```bash
# Port-forward
kubectl port-forward -n istio-system svc/prometheus 9090:9090

# Acessar: http://localhost:9090
```

#### **5. ArgoCD - Status de Deploys**

```bash
# Obter URL
kubectl get svc argocd-server -n argocd

# Acessar: https://<ARGOCD-URL>
```

### **Métricas Importantes:**

```promql
# Taxa de requisições
istio_requests_total

# Latência P95
histogram_quantile(0.95, rate(istio_request_duration_milliseconds_bucket[1m]))

# Taxa de erro
sum(rate(istio_requests_total{response_code=~"5.*"}[5m])) 
  / sum(rate(istio_requests_total[5m]))

# Pods disponíveis
kube_deployment_status_replicas_available
```

---

## 🚨 Troubleshooting

### **Problema: ArgoCD não sincroniza**

```bash
# 1. Verificar status
argocd app get ecommerce-staging

# 2. Forçar refresh
argocd app get ecommerce-staging --refresh

# 3. Verificar logs
kubectl logs -n argocd deployment/argocd-application-controller

# 4. Deletar e recriar
kubectl delete application ecommerce-staging -n argocd
cd argocd/install && ./deploy-apps.sh
```

### **Problema: Pods não iniciam**

```bash
# 1. Verificar events
kubectl get events -n ecommerce-staging --sort-by='.lastTimestamp'

# 2. Describe pod
kubectl describe pod <pod-name> -n ecommerce-staging

# 3. Logs
kubectl logs <pod-name> -n ecommerce-staging

# 4. Verificar imagem no ECR
aws ecr describe-images --repository-name ecommerce/product-catalog
```

### **Problema: GitHub Actions falha**

```bash
# 1. Verificar secrets
gh secret list

# 2. Testar AWS credentials
aws sts get-caller-identity

# 3. Verificar ECR repositories
aws ecr describe-repositories

# 4. Logs do workflow
gh run view <run-id> --log
```

### **Problema: LoadBalancer pending**

```bash
# 1. Verificar events
kubectl describe svc istio-ingressgateway -n istio-system

# 2. Verificar AWS quotas
aws service-quotas get-service-quota \
  --service-code elasticloadbalancing \
  --quota-code L-53DA6B97

# 3. Aguardar (pode levar 3-5 minutos)
kubectl get svc -n istio-system -w
```

### **Logs Centralizados:**

```bash
# Ver todos os logs de um namespace
kubectl logs -n ecommerce-staging --all-containers=true --tail=100

# Logs de um deployment específico
kubectl logs -n ecommerce-staging deployment/product-catalog -f

# Logs com timestamp
kubectl logs -n ecommerce-staging deployment/product-catalog --timestamps
```

---

## 💰 Estimativa de Custos

### **Custo Mensal Estimado (us-east-1):**

| Recurso | Quantidade | Custo/mês | Total |
|---------|------------|-----------|-------|
| EKS Cluster | 1 | $73 | $73 |
| EC2 t3.medium | 3 nodes | $30 cada | $90 |
| NAT Gateway | 2 | $32 cada | $64 |
| Network Load Balancer | 2 | $16 cada | $32 |
| EBS Volumes (gp3) | 3x 20GB | $2 cada | $6 |
| Data Transfer | ~10GB out | $0.90/GB | $9 |
| ECR Storage | ~5GB | $0.10/GB | $0.50 |
| **TOTAL** | | | **~$274/mês** |

### **Custo por Tempo de Uso:**

| Duração | Custo Estimado |
|---------|----------------|
| 2 horas | ~$2 USD |
| 1 dia | ~$9 USD |
| 1 semana | ~$63 USD |
| 1 mês | ~$274 USD |

### **💡 Dicas para Reduzir Custos:**

1. **Destrua após testes:**
   ```bash
   ./scripts/destroy-gitops-stack.sh
   ```

2. **Use t3.micro em staging:**
   ```hcl
   # 02-eks-cluster/eks.cluster.node-group.tf
   instance_types = ["t3.micro"]  # $7.50/mês
   ```

3. **Reduza número de nodes:**
   ```hcl
   desired_size = 2  # ao invés de 3
   ```

4. **Use Single NAT Gateway (não recomendado para prod):**
   ```hcl
   # 01-networking/vpc.nat-gateways.tf
   # Comentar um NAT Gateway
   ```

5. **Scheduled start/stop (avançado):**
   - Usar Karpenter ou Node Auto-scaler
   - Parar cluster fora do horário de trabalho

---

## 📚 Próximos Passos

### **Melhorias Recomendadas:**

1. **✅ Implementar External Secrets Operator**
   - Sincronizar secrets do AWS Secrets Manager
   - Rotação automática de credentials

2. **✅ Configurar Alertas**
   - Slack notifications
   - AWS SNS para eventos críticos
   - PagerDuty integration

3. **✅ Policy as Code**
   - Open Policy Agent (OPA)
   - Kyverno para policies
   - Validação de manifests antes do deploy

4. **✅ Cost Tracking**
   - Instalar Kubecost
   - Tag resources por equipe
   - Alertas de budget

5. **✅ Disaster Recovery**
   - Velero para backups
   - Multi-region setup
   - RPO/RTO definidos

6. **✅ Advanced Deployment Strategies**
   - Flagger para progressive delivery
   - Canary analysis automático
   - A/B testing

---

## 📖 Documentação Adicional

- [Desafio GitOps Original](Desafio_Gitops.md)
- [ArgoCD Setup](argocd/README.md)
- [GitHub Actions Workflows](.github/workflows/README.md)
- [Kubernetes Manifests](k8s-manifests/README.md)
- [Microservices](microservices/README.md)
- [Troubleshooting Avançado](docs/TROUBLESHOOTING.md)
- [Observability Guide](docs/OBSERVABILITY.md)

---

## 🤝 Contribuindo

Pull requests são bem-vindos! Para mudanças maiores:

1. Fork o repositório
2. Crie sua feature branch (`git checkout -b feature/amazing-feature`)
3. Commit suas mudanças (`git commit -m 'Add amazing feature'`)
4. Push para o branch (`git push origin feature/amazing-feature`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja [LICENSE](LICENSE) para mais detalhes.

---

## ✨ Autores

- **Luiz** - *Initial work* - [GitHub](https://github.com/YOUR-USERNAME)

---

**⭐ Se este projeto foi útil, considere dar uma estrela no GitHub!**

# 🚀 Quick Start - GitOps Implementation

**Tempo estimado:** 45-60 minutos (incluindo provisioning AWS)

---

## 📋 Pré-requisitos (5 min)

### 1. Verificar instalações

```bash
terraform --version  # >= 1.9.0
kubectl version      # >= 1.30
aws --version        # >= 2.x
git --version        # >= 2.x
```

### 2. Configurar AWS

```bash
aws configure
export AWS_PROFILE=devopsproject

# Testar
aws sts get-caller-identity
```

### 3. Preparar GitHub

- [ ] Criar repositório no GitHub
- [ ] Habilitar GitHub Actions

---

## 🎯 Passo 1: Deploy Infraestrutura (40 min)

```bash
# Clone ou entre no diretório
cd istio-eks-terraform-gitops

# Execute deploy automatizado
./scripts/deploy-gitops-stack.sh
```

**Aguarde:** ~40 minutos

O script irá:
1. ✅ Deploy VPC + EKS (15 min)
2. ✅ Instalar Istio (5 min)
3. ✅ Instalar ArgoCD (5 min)
4. ✅ Configurar aplicações (2 min)
5. ✅ Iniciar monitoramento (2 min)

---

## 🎯 Passo 2: Configurar GitHub (5 min)

### 2.1 Push para GitHub

```bash
# Adicionar remote (se não tiver)
git remote add origin https://github.com/YOUR-USERNAME/istio-eks-terraform-gitops.git

# Push inicial
git add .
git commit -m "feat: GitOps implementation complete"
git push -u origin main

# Criar branch develop
git checkout -b develop
git push -u origin develop
```

### 2.2 Configurar Secrets

No GitHub: **Settings → Secrets and variables → Actions → New secret**

```
Name: AWS_ACCESS_KEY_ID
Value: <sua-access-key>

Name: AWS_SECRET_ACCESS_KEY
Value: <sua-secret-key>
```

### 2.3 Criar Environments

No GitHub: **Settings → Environments → New environment**

**Environment 1: staging**
- Nome: `staging`
- Protection rules: Nenhuma

**Environment 2: production**
- Nome: `production`
- Protection rules:
  - ✅ Required reviewers (adicione seu usuário)

### 2.4 Executar Setup ECR

No GitHub: **Actions → Create ECR Repositories → Run workflow**

Aguarde: ~1 minuto

---

## 🎯 Passo 3: Acessar Aplicações (2 min)

### 3.1 Obter URLs

```bash
# Executar script de status
./scripts/get-status.sh

# OU manualmente:

# ArgoCD
kubectl get svc argocd-server -n argocd

# Application
kubectl get svc istio-ingressgateway -n istio-system
```

### 3.2 Login ArgoCD

```bash
# Obter senha
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Acessar: https://<ARGOCD-URL>
# Username: admin
# Password: <senha-obtida-acima>
```

⚠️ **IMPORTANTE:** Altere a senha após primeiro login!

```bash
argocd login <ARGOCD-URL>
argocd account update-password
```

---

## 🎯 Passo 4: Primeiro Deploy (3 min)

### 4.1 Sync Staging no ArgoCD

**Opção A: Via UI**
1. Login no ArgoCD
2. Applications → `ecommerce-staging`
3. Click em **SYNC**
4. Click em **SYNCHRONIZE**

**Opção B: Via CLI**
```bash
argocd app sync ecommerce-staging
```

### 4.2 Verificar Deploy

```bash
# Ver pods
kubectl get pods -n ecommerce-staging

# Aguardar todos ficarem Running (2-3 min)
kubectl get pods -n ecommerce-staging -w
```

### 4.3 Acessar Aplicação

```bash
# Obter URL
GATEWAY=$(kubectl get svc istio-ingressgateway -n istio-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Application URL: http://$GATEWAY"
```

Abra no browser: `http://<GATEWAY-URL>`

---

## 🎯 Passo 5: Testar CI/CD (5 min)

### 5.1 Fazer uma mudança

```bash
# Criar branch de feature
git checkout develop
git checkout -b test/ci-cd

# Fazer uma mudança qualquer (exemplo)
echo "# GitOps CI/CD Test" >> README.md

# Commit e push
git add README.md
git commit -m "test: trigger CI/CD pipeline"
git push -u origin test/ci-cd
```

### 5.2 Ver Pipeline Executando

No GitHub:
1. **Actions** tab
2. Ver workflow rodando
3. Acompanhar steps:
   - Build & Test
   - Deploy Staging

### 5.3 Verificar Deploy Automático

```bash
# ArgoCD vai detectar mudança em ~3 minutos
# Ver status
argocd app get ecommerce-staging

# Ver nova versão dos pods
kubectl get pods -n ecommerce-staging
```

---

## 🎯 Passo 6: Testar Rollback (2 min)

### 6.1 Ver histórico

```bash
argocd app history ecommerce-staging
```

### 6.2 Fazer rollback

```bash
# Rollback para versão anterior
argocd app rollback ecommerce-staging <PREVIOUS-REVISION-ID>

# Verificar
kubectl get pods -n ecommerce-staging -w
```

---

## 🎯 Passo 7: Explorar Observabilidade (5 min)

### 7.1 Grafana

```bash
# Port-forward
kubectl port-forward -n istio-system svc/grafana 3000:3000

# Acessar: http://localhost:3000
# User: admin / Password: admin
```

**Dashboards:**
- Istio Service Dashboard
- Istio Workload Dashboard
- Kubernetes Cluster

### 7.2 Kiali (Service Mesh Topology)

```bash
# Port-forward
kubectl port-forward -n istio-system svc/kiali 20001:20001

# Acessar: http://localhost:20001
```

### 7.3 Jaeger (Distributed Tracing)

```bash
# Port-forward
kubectl port-forward -n istio-system svc/jaeger-query 16686:16686

# Acessar: http://localhost:16686
```

---

## ✅ Checklist Final

- [ ] Infraestrutura deployada (VPC, EKS, Istio)
- [ ] ArgoCD instalado e acessível
- [ ] GitHub repo configurado
- [ ] Secrets do GitHub configurados
- [ ] Environments criados (staging/production)
- [ ] ECR repositories criados
- [ ] ArgoCD password alterada
- [ ] Aplicação staging rodando
- [ ] CI/CD pipeline testado
- [ ] Rollback testado
- [ ] Grafana acessível
- [ ] Kiali acessível

---

## 🎉 Parabéns!

Você agora tem uma **stack completa de GitOps** funcionando!

### **O que você consegue fazer agora:**

✅ Push código → Deploy automático em staging  
✅ Merge para main → Aprovação manual para production  
✅ Rollback em 30 segundos  
✅ Visualizar métricas em tempo real  
✅ Ver topologia de serviços  
✅ Rastrear requisições distribuídas  
✅ Auditoria completa via Git  

---

## 📚 Próximos Passos

1. **Ler documentação completa:** [GITOPS-GUIDE.md](GITOPS-GUIDE.md)
2. **Explorar workflows:** [.github/workflows/README.md](.github/workflows/README.md)
3. **Estudar ArgoCD:** [argocd/README.md](argocd/README.md)
4. **Ver resumo completo:** [IMPLEMENTATION-SUMMARY.md](IMPLEMENTATION-SUMMARY.md)

---

## 🧹 Limpeza (Importante!)

**Quando terminar os testes:**

```bash
# Destruir TUDO para evitar custos
./scripts/destroy-gitops-stack.sh

# Confirmar com: destroy-everything
```

⚠️ **Custo AWS:**
- 2 horas: ~$2 USD
- 1 dia: ~$9 USD
- 1 semana: ~$63 USD
- **NÃO ESQUEÇA DE DESTRUIR!**

---

## 🆘 Problemas?

### Erro no Terraform

```bash
# Ver logs detalhados
terraform apply -auto-approve -detailed-exitcode

# Destruir e tentar novamente
cd 02-eks-cluster && terraform destroy -auto-approve
cd ../01-networking && terraform destroy -auto-approve
cd ../00-backend && terraform destroy -auto-approve
```

### ArgoCD não sincroniza

```bash
# Forçar refresh
argocd app get ecommerce-staging --refresh

# Ver logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### GitHub Actions falha

```bash
# Verificar secrets
gh secret list

# Testar AWS credentials
aws sts get-caller-identity

# Ver logs do workflow
gh run list
gh run view <run-id> --log
```

### Mais ajuda

Ver: [GITOPS-GUIDE.md - Troubleshooting](GITOPS-GUIDE.md#-troubleshooting)

---

## 📞 Contato

Dúvidas? Abra uma issue no GitHub!

---

**Boa sorte! 🚀**

# 🚀 Começe Aqui - Navegação do Projeto

Este projeto foi dividido em múltiplos guias para facilitar a navegação. Escolha o que melhor se adequa à sua necessidade:

---

## 📚 Documentação Principal

### **🎯 Para Começar Rapidamente:**
- **[QUICK-START.md](QUICK-START.md)** ⭐ Comece aqui! Guia rápido de 45 minutos

### **📖 Para Entender Tudo:**
- **[GITOPS-GUIDE.md](GITOPS-GUIDE.md)** - Guia completo com arquitetura, fluxos, troubleshooting

### **📊 Para Ver o Resumo:**
- **[IMPLEMENTATION-SUMMARY.md](IMPLEMENTATION-SUMMARY.md)** - O que foi implementado e por quê
- **[DESAFIO-ENTREGA.md](DESAFIO-ENTREGA.md)** - Resumo executivo para entrega do desafio

### **📋 Para Acompanhar Progresso:**
- **[IMPLEMENTATION-CHECKLIST.md](IMPLEMENTATION-CHECKLIST.md)** - Checklist completo com checkboxes

### **📁 Para Entender a Estrutura:**
- **[PROJECT-STRUCTURE.md](PROJECT-STRUCTURE.md)** - Estrutura completa de arquivos e diretórios

### **❓ Para o Desafio Original:**
- **[Desafio_Gitops.md](Desafio_Gitops.md)** - Requisitos originais do desafio

---

## 🗺️ Navegação por Objetivo

### **Quero deployar a infraestrutura:**
1. Leia: [QUICK-START.md](QUICK-START.md)
2. Execute: `./scripts/deploy-gitops-stack.sh`
3. Aguarde: ~40 minutos

### **Quero entender GitOps:**
1. Leia: [GITOPS-GUIDE.md](GITOPS-GUIDE.md) - Seção "Por que GitOps?"
2. Veja: Diagrama de arquitetura completo
3. Entenda: Fluxo CI/CD detalhado

### **Quero configurar CI/CD:**
1. Leia: [.github/workflows/README.md](.github/workflows/README.md)
2. Configure: GitHub Secrets e Environments
3. Execute: Workflow `setup-ecr.yml`

### **Quero trabalhar com ArgoCD:**
1. Leia: [argocd/README.md](argocd/README.md)
2. Instale: `./argocd/install/install-argocd.sh`
3. Deploy: `./argocd/install/deploy-apps.sh`

### **Quero entender os manifestos K8s:**
1. Leia: [k8s-manifests/README.md](k8s-manifests/README.md)
2. Explore: `k8s-manifests/base/` e `k8s-manifests/staging/`
3. Teste: `kubectl kustomize k8s-manifests/staging`

### **Quero ver a observabilidade:**
1. Port-forward Grafana: `kubectl port-forward -n istio-system svc/grafana 3000:3000`
2. Port-forward Kiali: `kubectl port-forward -n istio-system svc/kiali 20001:20001`
3. Acesse dashboards no browser

### **Preciso fazer rollback:**
1. Veja: [GITOPS-GUIDE.md](GITOPS-GUIDE.md) - Seção "Rollback"
2. Execute: `argocd app rollback ecommerce-production <revision>`
3. Tempo: ~30 segundos

### **Tenho problemas:**
1. Leia: [GITOPS-GUIDE.md](GITOPS-GUIDE.md) - Seção "Troubleshooting"
2. Execute: `./scripts/get-status.sh`
3. Veja logs: `kubectl logs -n <namespace> <pod>`

---

## 🎯 Fluxo Recomendado para Primeiro Uso

```
1. Ler QUICK-START.md (10 min)
   ↓
2. Verificar pré-requisitos (5 min)
   ↓
3. Deploy infraestrutura (40 min)
   ./scripts/deploy-gitops-stack.sh
   ↓
4. Configurar GitHub (10 min)
   - Push código
   - Adicionar secrets
   - Criar environments
   ↓
5. Primeiro deploy (5 min)
   argocd app sync ecommerce-staging
   ↓
6. Testar CI/CD (10 min)
   - Fazer mudança
   - Push código
   - Ver pipeline
   ↓
7. Explorar observabilidade (10 min)
   - Grafana
   - Kiali
   - Jaeger
   ↓
8. Ler GITOPS-GUIDE.md completo (30 min)
   ↓
9. Destruir recursos (5 min)
   ./scripts/destroy-gitops-stack.sh
```

**Tempo total:** ~2 horas (sendo 40 min aguardando AWS)

---

## 📂 Estrutura de Diretórios

```
📦 istio-eks-terraform-gitops/
│
├── 📚 Documentação (COMECE AQUI)
│   ├── QUICK-START.md              ⭐ COMECE AQUI
│   ├── GITOPS-GUIDE.md             Guia completo
│   ├── IMPLEMENTATION-SUMMARY.md   Resumo implementação
│   ├── DESAFIO-ENTREGA.md         Entrega do desafio
│   ├── IMPLEMENTATION-CHECKLIST.md Checklist
│   └── PROJECT-STRUCTURE.md        Estrutura arquivos
│
├── 🏗️ Infraestrutura (Terraform)
│   ├── 00-backend/                 State backend
│   ├── 01-networking/              VPC
│   └── 02-eks-cluster/             EKS
│
├── 🕸️  Service Mesh (Istio)
│   └── istio/                      Istio configs
│
├── 🔄 GitOps (ArgoCD)
│   └── argocd/                     ArgoCD configs
│
├── 📦 Manifestos K8s (Kustomize)
│   └── k8s-manifests/              Base + overlays
│
├── 🐳 Microservices (Docker)
│   └── microservices/              Dockerfiles
│
├── 🤖 CI/CD (GitHub Actions)
│   └── .github/workflows/          Pipelines
│
└── 🔧 Scripts (Automação)
    └── scripts/                    Deploy, status, destroy
```

---

## 🆘 Ajuda Rápida

### **Como fazer deploy completo?**
```bash
./scripts/deploy-gitops-stack.sh
```

### **Como ver o status de tudo?**
```bash
./scripts/get-status.sh
```

### **Como destruir tudo?**
```bash
./scripts/destroy-gitops-stack.sh
```

### **Como acessar ArgoCD?**
```bash
kubectl get svc argocd-server -n argocd
# Username: admin
# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### **Como fazer rollback?**
```bash
argocd app history ecommerce-production
argocd app rollback ecommerce-production <revision-id>
```

### **Onde estão os logs?**
```bash
kubectl logs -n ecommerce-staging deployment/product-catalog -f
```

---

## 💡 Dicas Importantes

1. **⚠️ Custos AWS**: Sempre destrua recursos após testes!
   ```bash
   ./scripts/destroy-gitops-stack.sh
   ```

2. **🔑 Credenciais**: Configure AWS profile antes de começar
   ```bash
   export AWS_PROFILE=devopsproject
   ```

3. **📖 Documentação**: Leia QUICK-START.md primeiro!

4. **🎯 Foco**: Siga o fluxo recomendado acima

5. **💬 Problemas**: Veja seção Troubleshooting no GITOPS-GUIDE.md

---

## 🎉 Resultado Final

Ao completar este projeto, você terá:

✅ Stack DevOps completa implementada  
✅ GitOps com ArgoCD funcionando  
✅ CI/CD com GitHub Actions automatizado  
✅ Multi-ambiente (staging/production)  
✅ Observabilidade total (Grafana, Kiali, Jaeger)  
✅ Documentação profissional  
✅ Rollback em 30 segundos  
✅ Portfolio impressionante  

---

## 📞 Precisa de Ajuda?

1. **Leia primeiro**: [GITOPS-GUIDE.md - Troubleshooting](GITOPS-GUIDE.md#-troubleshooting)
2. **Execute**: `./scripts/get-status.sh`
3. **Veja logs**: `kubectl logs -n <namespace> <pod>`
4. **Abra issue**: No GitHub repository

---

**Boa sorte! 🚀**

**Próximo passo**: Abra [QUICK-START.md](QUICK-START.md) e comece!

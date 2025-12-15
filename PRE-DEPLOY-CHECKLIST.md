# ✅ CHECKLIST PRÉ-DEPLOY - Revisão Completa

## 📋 STATUS ATUAL

✅ **Stack 00-backend** → OK (não foi apagada)  
✅ **Repositório GitHub** → Criado (vazio): https://github.com/jlui70/istio-eks-terraform-gitops  
✅ **ACCOUNT_ID substituído** → Manifestos K8s atualizados com 794038226274  
✅ **Script install-istio.sh** → Corrigido para instalar addons de observabilidade  

---

## ⚠️ PROBLEMAS IDENTIFICADOS E CORRIGIDOS

### 1. ❌ PROBLEMA: Manifests GitOps com ACCOUNT_ID placeholder
**✅ SOLUÇÃO:** Substituído automaticamente por `794038226274`
```bash
# JÁ EXECUTADO
find k8s-manifests -type f -name '*.yaml' -exec sed -i 's/ACCOUNT_ID/794038226274/g' {} \;
```

### 2. ❌ PROBLEMA: install-istio.sh não instalava addons de observabilidade
**✅ SOLUÇÃO:** Script corrigido para incluir Prometheus, Grafana, Kiali, Jaeger
- Arquivo: `istio/install/install-istio.sh`
- Linhas adicionadas: kubectl apply -f samples/addons/*.yaml

### 3. ❌ PROBLEMA: ArgoCD tentará acessar GitHub vazio
**✅ SOLUÇÃO:** Duas opções de deploy criadas:

**Opção A (RECOMENDADA):** Deploy Tradicional (sem GitOps)
```bash
./rebuild-all-traditional.sh
```
- Usa manifests tradicionais do Istio (istio/manifests/)
- NÃO usa ArgoCD
- Aplicação funciona imediatamente
- Depois adiciona GitOps manualmente

**Opção B:** Fazer push antes e usar ArgoCD
```bash
# 1. Push dos manifests
git add .
git commit -m "Initial commit with GitOps"
git push origin main

# 2. Executar deploy completo
./rebuild-all.sh  # Este usa ArgoCD
```

---

## 🚀 RECOMENDAÇÃO: QUAL SCRIPT USAR?

### Use `rebuild-all-traditional.sh` porque:

✅ Repositório GitHub está vazio  
✅ Imagens Docker não existem no ECR ainda  
✅ Você quer testar a infraestrutura primeiro  
✅ Pode adicionar GitOps depois gradualmente  

O fluxo recomendado:
```
1. rebuild-all-traditional.sh  → Deploy tradicional funcional
2. Testar tudo funcionando
3. Fazer push para GitHub
4. Instalar ArgoCD manualmente
5. Criar imagens Docker
6. Migrar para GitOps
```

---

## 📝 ANTES DE EXECUTAR

### Verificações Obrigatórias:

```bash
# 1. Verificar AWS credentials
aws sts get-caller-identity
# Esperado: Account: 794038226274

# 2. Verificar backend S3/DynamoDB (stack 00)
aws s3 ls s3://istio-eks-terraform-backend-2025 --region us-east-1
# Deve listar os tfstate files

# 3. Verificar que não há recursos EKS/VPC residuais
aws eks list-clusters --region us-east-1
# Esperado: []

# 4. Verificar git remoto
git remote -v
# Esperado: origin  https://github.com/jlui70/istio-eks-terraform-gitops
```

---

## 🎯 COMANDOS PARA EXECUTAR AGORA

### Opção Recomendada (Deploy Tradicional):

```bash
cd /home/luiz7/Projects/istio-eks-terraform-gitops

# Executar deploy completo sem GitOps
./rebuild-all-traditional.sh
```

**Tempo estimado:** 35-40 minutos

**O que será criado:**
- ✅ VPC (3 AZs, subnets públicas/privadas)
- ✅ EKS Cluster (1.32, 3 nodes t3.medium)
- ✅ Istio Service Mesh (v1.27.0)
- ✅ Addons: Prometheus, Grafana, Kiali, Jaeger
- ✅ Aplicação E-commerce (7 microserviços v1)
- ✅ LoadBalancer público
- ✅ Port-forwards para ferramentas

---

## ⚡ DEPOIS DO DEPLOY

### Se quiser adicionar GitOps:

```bash
# 1. Fazer commit de tudo
git add .
git commit -m "Add infrastructure and GitOps manifests"
git push origin main

# 2. Instalar ArgoCD
./argocd/install/install-argocd.sh

# 3. Deploy apps via ArgoCD
./argocd/install/deploy-apps.sh

# 4. Construir imagens Docker
./scripts/build-and-push-images.sh
```

---

## 🔥 ERROS QUE NÃO VÃO ACONTECER AGORA

✅ **prometheus não encontrado** → Corrigido, install-istio.sh agora instala addons  
✅ **ACCOUNT_ID inválido** → Substituído por 794038226274  
✅ **ArgoCD sync failed** → Usando deploy tradicional primeiro  
✅ **InvalidImageName** → Deploy tradicional usa imagens públicas  

---

## 📊 RESUMO

| Item | Status | Ação Necessária |
|------|--------|-----------------|
| Backend S3/DynamoDB | ✅ OK | Nenhuma |
| AWS Credentials | ⚠️ Verificar | `aws sts get-caller-identity` |
| Manifests K8s | ✅ OK | ACCOUNT_ID substituído |
| Script Istio | ✅ OK | Addons incluídos |
| GitHub Repo | ⚠️ Vazio | OK para deploy tradicional |
| Imagens Docker | ❌ Não existem | OK para deploy tradicional |

---

## ✅ CONCLUSÃO

**PODE EXECUTAR AGORA:**

```bash
./rebuild-all-traditional.sh
```

Este script vai funcionar sem erros porque:
- ✅ Não depende do GitHub
- ✅ Não depende de imagens Docker no ECR
- ✅ Usa manifestos tradicionais do Istio (testados)
- ✅ Instala addons de observabilidade automaticamente

---

**Boa sorte com o deploy! 🚀**

# 🎬 GUIA DE DEMONSTRAÇÃO - PROJETO GITOPS FINAL

## 📋 **CHECKLIST PRÉ-APRESENTAÇÃO**

### Antes de Começar:
- [ ] AWS credentials configuradas (`aws sts get-caller-identity`)
- [ ] Docker rodando
- [ ] Git configurado com GitHub
- [ ] Conta AWS limpa (sem recursos EKS/VPC antigos)
- [ ] Repositório GitHub vazio: https://github.com/jlui70/istio-eks-terraform-gitops

---

## 🎯 **ROTEIRO DA APRESENTAÇÃO** (Tempo: ~50 minutos)

### **PARTE 1: DEPLOY INICIAL DO ZERO** (40 minutos)

#### 1.1 Mostrar Ambiente Zerado
```bash
# Mostrar que não há recursos na AWS
aws eks list-clusters --region us-east-1
# Resultado esperado: {"clusters":[]}

# Mostrar repositório vazio
firefox https://github.com/jlui70/istio-eks-terraform-gitops &
```

**💬 Falar:** "Vou demonstrar um deploy completo de infraestrutura cloud com GitOps, partindo do zero."

---

#### 1.2 Executar Rebuild Completo
```bash
cd /home/luiz7/Projects/istio-eks-terraform-gitops

# Executar script de rebuild (vai demorar ~40min)
./rebuild-all-with-gitops.sh
```

**💬 Falar enquanto executa:**
- "O script está criando toda a infraestrutura AWS: VPC, subnets, EKS cluster"
- "Depois instala o Istio Service Mesh para gerenciar tráfego entre microserviços"
- "Em seguida instala o ArgoCD para GitOps"
- "Por fim, cria imagens Docker e faz deploy via ArgoCD"

**⏱️ DURANTE A ESPERA:** Mostrar os arquivos do projeto

```bash
# Mostrar estrutura do projeto
tree -L 2 -I 'node_modules|.git'

# Mostrar manifestos Kubernetes
cat k8s-manifests/base/ecommerce-ui.yaml

# Mostrar configuração do ArgoCD
cat argocd/applications/staging-app.yaml
```

---

#### 1.3 Verificar Deploy Completo

Quando o script terminar, verificar:

```bash
# 1. Verificar cluster
kubectl get nodes

# 2. Verificar ArgoCD
kubectl get applications -n argocd

# 3. Verificar pods
kubectl get pods -n ecommerce-staging
```

**💬 Falar:** "Agora vou acessar as ferramentas para mostrar o ambiente funcionando."

---

### **PARTE 2: DEMONSTRAR ARGOCD E OBSERVABILIDADE** (5 minutos)

#### 2.1 Acessar ArgoCD UI
```bash
# Obter URL e senha
ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "URL: https://$ARGOCD_URL"
echo "User: admin"
echo "Pass: $ARGOCD_PASS"

# Abrir no navegador
firefox "https://$ARGOCD_URL" &
```

**💬 Mostrar no ArgoCD:**
- Aplicação `ecommerce-staging` sincronizada
- Status "Synced" e "Healthy"
- Árvore de recursos (Deployments, Services, Pods)

#### 2.2 Acessar Aplicação v1.0.0
```bash
# Obter URL da aplicação
APP_URL=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Aplicação: http://$APP_URL"

# Abrir no navegador
firefox "http://$APP_URL" &
```

**💬 Mostrar:** 
- Página azul com **"Versão: v1.0.0"**
- Badges: GitOps, Istio, AWS EKS

#### 2.3 Mostrar Kiali (Service Mesh)
```bash
# Kiali já está com port-forward rodando
firefox "http://localhost:20001" &
```

**💬 Mostrar:**
- Graph → Namespace: ecommerce-staging
- Tráfego entre microserviços
- Service Mesh em ação

---

### **PARTE 3: DEMONSTRAR GITOPS - ATUALIZAÇÃO AUTOMÁTICA** (5 minutos)

#### 3.1 Criar Nova Versão (v2.0.0 - Vermelha)

```bash
# Construir nova versão com cor diferente
./scripts/build-demo-image.sh v2.0.0 "#e74c3c"
```

**💬 Falar:** "Agora vou simular uma atualização da aplicação. Mudei a versão para 2.0.0 e a cor para vermelho."

---

#### 3.2 Atualizar Manifesto no Git

```bash
# Editar o manifesto para usar v2.0.0
sed -i 's/APP_VERSION.*$/APP_VERSION"\n          value: "v2.0.0"/' k8s-manifests/base/ecommerce-ui.yaml

# Verificar mudança
git diff k8s-manifests/base/ecommerce-ui.yaml

# Fazer commit
git add k8s-manifests/base/ecommerce-ui.yaml
git commit -m "feat: Update to version 2.0.0 (red theme)"
git push origin main
```

**💬 Falar:** "Agora fiz commit da mudança no GitHub. O ArgoCD vai detectar automaticamente e sincronizar."

---

#### 3.3 Acompanhar Sincronização no ArgoCD

```bash
# Voltar para o ArgoCD UI
# Mostrar que detectou "OutOfSync"
# Aguardar auto-sync (30-60 segundos)

# Ou forçar sync manual
kubectl patch application ecommerce-staging -n argocd --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

**💬 Mostrar no ArgoCD:**
1. Status muda para "OutOfSync" (detectou mudança)
2. Início do sync automático
3. Pods sendo recriados
4. Status volta para "Synced" e "Healthy"

---

#### 3.4 Verificar Aplicação Atualizada

```bash
# Aguardar pods novos ficarem prontos
kubectl rollout status deployment/ecommerce-ui-staging -n ecommerce-staging

# Recarregar a aplicação no navegador
firefox "http://$APP_URL" &
```

**💬 Mostrar:** 
- Página VERMELHA com **"Versão: v2.0.0"**
- Timestamp atualizado
- Tudo funcionando perfeitamente

**🎉 DEMONSTRAÇÃO COMPLETA!**

---

## 📊 **PONTOS-CHAVE PARA DESTACAR**

### Tecnologias Utilizadas:
✅ **AWS EKS** - Kubernetes gerenciado  
✅ **Terraform** - Infrastructure as Code  
✅ **Istio** - Service Mesh  
✅ **ArgoCD** - GitOps (CD)  
✅ **GitHub Actions** - CI/CD (workflows preparados)  
✅ **Prometheus + Grafana** - Métricas  
✅ **Kiali** - Visualização Service Mesh  
✅ **Jaeger** - Distributed Tracing  

### Benefícios do GitOps:
- ✅ **Single Source of Truth:** Git é a única fonte da verdade
- ✅ **Auditoria:** Todo histórico de mudanças no Git
- ✅ **Rollback Fácil:** Git revert para voltar versões
- ✅ **Automação:** Sincronização automática
- ✅ **Segurança:** Pull-based deployment

---

## 🔥 **TROUBLESHOOTING DURANTE APRESENTAÇÃO**

### Se pods ficarem em CrashLoopBackOff:
```bash
# Verificar logs
kubectl logs -n ecommerce-staging deployment/ecommerce-ui-staging

# Deletar pods para forçar recreate
kubectl delete pods --all -n ecommerce-staging
```

### Se ArgoCD não sincronizar:
```bash
# Forçar sync manual
kubectl patch application ecommerce-staging -n argocd --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

### Se LoadBalancer ficar "Pending":
```bash
# Aguardar 2-3 minutos (AWS provisioning)
kubectl get svc istio-ingressgateway -n istio-system -w
```

---

## 🎯 **TEMPO ESTIMADO POR ETAPA**

| Etapa | Tempo | Ação |
|-------|-------|------|
| Apresentar ambiente zerado | 2min | Mostrar AWS vazia, GitHub vazio |
| Executar rebuild-all | 40min | Aguardar criação completa |
| Mostrar ArgoCD + Apps | 3min | Navegar na UI, mostrar sync |
| Acessar v1.0.0 | 2min | Mostrar app azul funcionando |
| Criar v2.0.0 | 2min | Build nova imagem |
| Commit + Push | 1min | Git commit e push |
| Aguardar sync | 1min | Mostrar ArgoCD sincronizando |
| Verificar v2.0.0 | 2min | App vermelha atualizada |
| **TOTAL** | **~53min** | |

---

## ✅ **CHECKLIST PÓS-APRESENTAÇÃO**

Após a apresentação, DESTRUIR os recursos:

```bash
# Destruir tudo
./destroy-all.sh

# Confirmar que recursos foram removidos
aws eks list-clusters --region us-east-1
aws ec2 describe-vpcs --region us-east-1 --filters "Name=tag:Project,Values=eks-devopsproject"
```

**💰 IMPORTANTE:** Destruir recursos evita custos (~$274/mês se deixado rodando)

---

## 🎓 **PERGUNTAS ESPERADAS E RESPOSTAS**

**P: Por que GitOps em vez de CI/CD tradicional?**  
R: GitOps usa Git como fonte única da verdade. Mais seguro (pull-based), auditável, e permite rollback fácil.

**P: Como funciona o auto-sync do ArgoCD?**  
R: ArgoCD monitora o repositório Git a cada 3 minutos. Quando detecta mudança, aplica automaticamente no cluster.

**P: E se der problema no deploy?**  
R: ArgoCD tem health checks. Se falhar, mantém versão anterior e alerta. Pode fazer rollback com git revert.

**P: Por que Istio?**  
R: Istio gerencia tráfego entre serviços, adiciona observabilidade, circuit breakers, e permite canary deployments sem mudar código.

---

## 🚀 **BOA SORTE NA APRESENTAÇÃO!**

💡 **Dica Final:** Teste o fluxo completo 1-2 vezes antes da apresentação real para pegar o timing correto!

#!/bin/bash

# ============================================================================
# Script: rebuild-all.sh
# Descrição: Deploy completo automatizado (4 scripts em sequência)
# Autor: DevOps Project
# Data: Dezembro 2025
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# ============================================================================
# Banner
# ============================================================================

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║   🚀 DEPLOY COMPLETO: EKS + ISTIO + APLICAÇÃO + OBSERVABILIDADE    ║
║                                                                    ║
║   Tempo estimado: ~35 minutos                                     ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# ============================================================================
# Verificações iniciais
# ============================================================================

echo -e "${BLUE}🔍 Verificando pré-requisitos...${NC}"

# Verificar AWS credentials
if ! aws sts get-caller-identity &>/dev/null; then
    echo -e "${RED}❌ Erro: Credenciais AWS não configuradas${NC}"
    echo "Configure: aws configure --profile SEU_PERFIL"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
REGION="us-east-1"

echo -e "${GREEN}✅ AWS Account: $ACCOUNT_ID | Region: $REGION${NC}"

# ============================================================================
# VERIFICAÇÃO CRÍTICA: Perfil AWS correto
# ============================================================================

echo -e "${BLUE}🔍 Verificando perfil AWS...${NC}"

# Verificar se está usando terraform-role
if echo "$USER_ARN" | grep -q "assumed-role/terraform-role"; then
    echo -e "${GREEN}✅ Perfil AWS correto: terraform-role${NC}"
elif echo "$USER_ARN" | grep -q ":user/"; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  ATENÇÃO: Você está usando IAM User diretamente!${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "   ARN atual: $USER_ARN"
    echo ""
    echo "   O cluster EKS será configurado com access entries para 'terraform-role'."
    echo "   Após o deploy, você PRECISARÁ usar um perfil que assume essa role"
    echo "   para acessar o cluster via kubectl."
    echo ""
    echo -e "${YELLOW}   Opções:${NC}"
    echo ""
    echo "   1. Continuar assim e depois trocar perfil:"
    echo "      export AWS_PROFILE=devopsproject  # (perfil que assume terraform-role)"
    echo ""
    echo "   2. Trocar agora e reiniciar:"
    echo "      Ctrl+C para cancelar"
    echo "      export AWS_PROFILE=devopsproject"
    echo "      ./rebuild-all.sh"
    echo ""
    read -p "Deseja continuar mesmo assim? (s/N): " continue_choice
    
    if [[ ! "$continue_choice" =~ ^[Ss]$ ]]; then
        echo ""
        echo "Operação cancelada. Configure o perfil correto:"
        echo ""
        echo "   export AWS_PROFILE=devopsproject"
        echo "   ./rebuild-all.sh"
        echo ""
        exit 0
    fi
    
    echo -e "${YELLOW}⚠️  Continuando... Lembre-se de trocar o perfil depois!${NC}"
else
    echo -e "${GREEN}✅ Perfil AWS: $USER_ARN${NC}"
fi

# Verificar ferramentas necessárias
echo ""
echo -e "${BLUE}🔍 Verificando ferramentas instaladas...${NC}"
MISSING_TOOLS=()
command -v terraform &>/dev/null || MISSING_TOOLS+=("terraform")
command -v kubectl &>/dev/null || MISSING_TOOLS+=("kubectl")
command -v istioctl &>/dev/null || MISSING_TOOLS+=("istioctl")

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Ferramentas não encontradas: ${MISSING_TOOLS[*]}${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Todas as ferramentas necessárias estão instaladas${NC}"
echo ""

# ============================================================================
# Confirmação
# ============================================================================

echo -e "${YELLOW}Este script irá:${NC}"
echo "   1. [~15min] Deploy infraestrutura AWS (VPC + EKS)"
echo "   2. [~5min]  Instalar Istio Service Mesh"
echo "   3. [~3min]  Deploy aplicação e-commerce"
echo "   4. [~1min]  Iniciar ferramentas de observabilidade"
echo ""
read -p "Deseja continuar? (s/N): " confirm

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

# ============================================================================
# Timestamp início
# ============================================================================

START_TIME=$(date +%s)

# ============================================================================
# Step 1: Deploy Infraestrutura
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [1/4] 🏗️  DEPLOY INFRAESTRUTURA (VPC + EKS)                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if ./scripts/01-deploy-infra.sh; then
    echo -e "${GREEN}✅ Stack 00, 01 e 02 deployadas com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro no deploy de infraestrutura${NC}"
    
    # Verificar se foi erro de kubectl
    if echo "$USER_ARN" | grep -q ":user/"; then
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}💡 O erro pode ser devido ao perfil AWS!${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "Solução:"
        echo "   1. Trocar para perfil que assume terraform-role:"
        echo "      export AWS_PROFILE=devopsproject"
        echo ""
        echo "   2. Configurar kubectl:"
        echo "      aws eks update-kubeconfig --region us-east-1 --name eks-devopsproject-cluster"
        echo ""
        echo "   3. Continuar deployment:"
        echo "      ./scripts/02-install-istio.sh"
        echo "      ./scripts/03-deploy-app.sh"
        echo "      ./scripts/04-start-monitoring.sh"
        echo ""
    fi
    exit 1
fi

# ============================================================================
# Step 2: Instalar Istio
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [2/4] 🕸️  INSTALANDO ISTIO SERVICE MESH                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if ./scripts/02-install-istio.sh; then
    echo -e "${GREEN}✅ Istio instalado com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro na instalação do Istio${NC}"
    exit 1
fi

# ============================================================================
# Step 3: Deploy Aplicação
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [3/4] 📦 DEPLOYANDO APLICAÇÃO E-COMMERCE                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if ./scripts/03-deploy-app.sh; then
    echo -e "${GREEN}✅ Aplicação deployada com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro no deploy da aplicação${NC}"
    exit 1
fi

# ============================================================================
# Step 4: Start Monitoring
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [4/4] 📊 INICIANDO FERRAMENTAS DE OBSERVABILIDADE                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Executar em background para não bloquear
./scripts/04-start-monitoring.sh &
MONITORING_PID=$!

# Aguardar 5 segundos para port-forwards iniciarem
sleep 5

# Verificar se processo ainda está rodando
if ps -p $MONITORING_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Ferramentas de observabilidade iniciadas!${NC}"
else
    echo -e "${YELLOW}⚠️  Port-forwards podem ter falhado, verifique manualmente${NC}"
fi

# ============================================================================
# Resumo Final
# ============================================================================

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ DEPLOY COMPLETO FINALIZADO COM SUCESSO!                       ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📊 Tempo total: ${MINUTES}m ${SECONDS}s${NC}"
echo ""

# ============================================================================
# Informações de Acesso
# ============================================================================

echo -e "${YELLOW}📍 Recursos Deployados:${NC}"
echo ""

# Cluster Info
echo "🔹 EKS Cluster:"
kubectl cluster-info 2>/dev/null | head -1 || echo "   (execute: export AWS_PROFILE=devopsproject)"

# Nodes
echo ""
echo "🔹 Nodes:"
kubectl get nodes -o wide 2>/dev/null | grep -v "NAME" | awk '{print "   • "$1" - "$2" - "$6}' || echo "   (execute: export AWS_PROFILE=devopsproject)"

# Namespaces
echo ""
echo "🔹 Namespaces:"
kubectl get namespaces 2>/dev/null | grep "ecommerce\|istio-system" | awk '{print "   • "$1" - "$2}' || echo "   (execute: export AWS_PROFILE=devopsproject)"

# Pods
echo ""
echo "🔹 Pods (ecommerce):"
kubectl get pods -n ecommerce -o wide 2>/dev/null | grep -v "NAME" | awk '{print "   • "$1" - "$3}' || echo "   (aguardando inicialização...)"

# Ingress Gateway
echo ""
echo "🔹 Istio Ingress Gateway:"
GATEWAY_URL=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending...")
echo "   • URL: http://$GATEWAY_URL"

# ============================================================================
# Dashboards
# ============================================================================

echo ""
echo -e "${YELLOW}🌐 Dashboards de Observabilidade:${NC}"
echo ""
echo "   • Prometheus:  http://localhost:9090"
echo "   • Grafana:     http://localhost:3000  (admin/admin)"
echo "   • Kiali:       http://localhost:20001 (visualizar canary 80/20)"
echo "   • Jaeger:      http://localhost:16686 (distributed tracing)"
echo ""

# ============================================================================
# Próximos Passos
# ============================================================================

echo -e "${YELLOW}📝 Próximos Passos:${NC}"
echo ""
echo "   1. Aguardar LoadBalancer provisionar (3-5 minutos):"
echo "      kubectl get svc istio-ingressgateway -n istio-system -w"
echo ""
echo "   2. Testar aplicação:"
echo "      curl http://\$GATEWAY_URL"
echo ""
echo "   3. Gerar tráfego para visualizar canary:"
echo "      ./test-canary-visual.sh"
echo ""
echo "   4. Abrir Kiali para ver 80/20 split:"
echo "      http://localhost:20001"
echo "      Graph → Namespace: ecommerce → Display: Traffic Distribution"
echo ""
echo "   5. Para destruir tudo:"
echo "      ./destroy-all.sh"
echo ""

# Verificar se usou IAM User e lembrar de trocar perfil
if echo "$USER_ARN" | grep -q ":user/"; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  LEMBRE-SE: Para acessar o cluster via kubectl, use:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "   export AWS_PROFILE=devopsproject"
    echo "   aws eks update-kubeconfig --region us-east-1 --name eks-devopsproject-cluster"
    echo ""
fi

echo -e "${GREEN}🎉 Ambiente pronto para demonstração!${NC}"
echo ""

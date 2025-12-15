#!/bin/bash

# ============================================================================
# Script: rebuild-all-traditional.sh
# Descrição: Deploy completo SEM GitOps (usa manifests tradicionais do Istio)
# Uso: Para primeiro deploy quando GitHub ainda está vazio
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║   🚀 DEPLOY TRADICIONAL: EKS + ISTIO + APP + OBSERVABILIDADE       ║
║                                                                    ║
║   Tempo estimado: ~35 minutos                                     ║
║   Modo: SEM GitOps (deploy direto via kubectl)                    ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificações iniciais
echo -e "${BLUE}🔍 Verificando pré-requisitos...${NC}"

if ! aws sts get-caller-identity &>/dev/null; then
    echo -e "${RED}❌ Erro: Credenciais AWS não configuradas${NC}"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ AWS Account: $ACCOUNT_ID${NC}"

# Confirmação
echo ""
echo -e "${YELLOW}Este script irá executar:${NC}"
echo "   1. [~15min] Deploy infraestrutura (VPC + EKS)"
echo "   2. [~5min]  Instalar Istio + Addons Observabilidade"
echo "   3. [~3min]  Deploy aplicação E-commerce (v1)"
echo "   4. [~1min]  Iniciar ferramentas de monitoramento"
echo ""
read -p "Deseja continuar? (s/N): " confirm

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

START_TIME=$(date +%s)

# Step 1: Deploy Infraestrutura
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [1/4] 🏗️  DEPLOY INFRAESTRUTURA                                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if ./scripts/01-deploy-infra.sh; then
    echo -e "${GREEN}✅ Infraestrutura deployada!${NC}"
else
    echo -e "${RED}❌ Erro no deploy de infraestrutura${NC}"
    exit 1
fi

# Step 2: Instalar Istio (com addons já incluídos)
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [2/4] 🕸️  INSTALANDO ISTIO + OBSERVABILIDADE                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if ./scripts/02-install-istio.sh; then
    echo -e "${GREEN}✅ Istio e addons instalados!${NC}"
else
    echo -e "${RED}❌ Erro na instalação do Istio${NC}"
    exit 1
fi

# Step 3: Deploy Aplicação
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [3/4] 📦 DEPLOYANDO APLICAÇÃO                                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if ./scripts/03-deploy-app.sh; then
    echo -e "${GREEN}✅ Aplicação deployada!${NC}"
else
    echo -e "${RED}❌ Erro no deploy da aplicação${NC}"
    exit 1
fi

# Step 4: Start Monitoring (já está rodando port-forwards)
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [4/4] 📊 INICIANDO MONITORAMENTO                                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

./scripts/04-start-monitoring.sh &
MONITORING_PID=$!
sleep 5

if ps -p $MONITORING_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Port-forwards iniciados!${NC}"
else
    echo -e "${YELLOW}⚠️  Port-forwards podem ter falhado${NC}"
fi

# Resumo Final
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ DEPLOY COMPLETO FINALIZADO!                                   ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 Tempo total: ${MINUTES}m ${SECONDS}s${NC}"
echo ""

# URLs de acesso
GATEWAY_URL=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending...")

echo -e "${YELLOW}🌐 URLs de Acesso:${NC}"
echo ""
echo "  🌐 Aplicação:   http://$GATEWAY_URL"
echo "  📊 Prometheus:  http://localhost:9090"
echo "  📈 Grafana:     http://localhost:3000"
echo "  🕸️  Kiali:      http://localhost:20001"
echo "  🔍 Jaeger:      http://localhost:16686"
echo ""

echo -e "${YELLOW}📝 Próximos Passos (GitOps):${NC}"
echo ""
echo "  1. Fazer commit e push dos manifestos GitOps:"
echo "     git add k8s-manifests/ argocd/ microservices/ .github/"
echo "     git commit -m 'Add GitOps manifests'"
echo "     git push origin main"
echo ""
echo "  2. Instalar ArgoCD:"
echo "     ./argocd/install/install-argocd.sh"
echo ""
echo "  3. Deploy das aplicações via ArgoCD:"
echo "     ./argocd/install/deploy-apps.sh"
echo ""
echo "  4. Construir imagens Docker:"
echo "     ./scripts/build-and-push-images.sh"
echo ""

echo -e "${GREEN}🎉 Ambiente tradicional pronto!${NC}"
echo ""

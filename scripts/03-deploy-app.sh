#!/bin/bash

# ============================================================================
# Script: 03-deploy-app.sh
# Descrição: Deploy da aplicação E-Commerce com Canary Deployment
# Autor: DevOps Project
# Data: Dezembro 2025
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║   🚀 DEPLOY DA APLICAÇÃO E-COMMERCE                                ║"
echo "║                                                                    ║"
echo "║   Fase 3: Microserviços + Canary Deployment (80/20)               ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}▶ Executando deploy da aplicação...${NC}"

cd "$PROJECT_ROOT/istio/install"
chmod +x deploy-all.sh
./deploy-all.sh

cd "$PROJECT_ROOT"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ APLICAÇÃO DEPLOYADA COM SUCESSO!                              ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📊 Microserviços deployados:${NC}"
echo "  • Frontend (React) ✅"
echo "  • Product Catalog v1 (80%) ✅"
echo "  • Product Catalog v2 (20% Canary) ✅"
echo "  • MongoDB Product Catalog ✅"
echo "  • Istio Gateway configurado ✅"
echo ""
echo -e "${YELLOW}🎯 Próximo passo:${NC}"
echo "  ./scripts/04-start-monitoring.sh"
echo ""

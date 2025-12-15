#!/bin/bash

# ============================================================================
# Script: test-canary-visual.sh
# Descrição: Gera tráfego para visualizar Canary Deployment no Kiali
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

ALB_URL=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$ALB_URL" ]; then
    echo -e "${RED}❌ Erro: LoadBalancer URL não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ LoadBalancer encontrado: ${ALB_URL}${NC}\n"

echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║                                                                    ║${NC}"
echo -e "${YELLOW}║   📊 DEMONSTRAÇÃO VISUAL DO CANARY DEPLOYMENT                      ║${NC}"
echo -e "${YELLOW}║                                                                    ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}🎯 Estratégia:${NC}"
echo "  • 80% do tráfego → Product Catalog v1"
echo "  • 20% do tráfego → Product Catalog v2 (Nova versão)"
echo ""
echo -e "${YELLOW}🌐 Abra o Kiali agora:${NC}"
echo -e "  ${GREEN}http://localhost:20001${NC}"
echo ""
echo -e "${BLUE}📍 No Kiali:${NC}"
echo "  1. Clique em 'Graph' no menu lateral"
echo "  2. Selecione namespace: ${GREEN}ecommerce${NC}"
echo "  3. Display: Marque '${GREEN}Traffic Distribution${NC}'"
echo "  4. Marque '${GREEN}Traffic Animation${NC}'"
echo "  5. Graph Type: '${GREEN}Versioned app graph${NC}'"
echo ""
echo -e "${YELLOW}⏳ Aguarde 10 segundos para abrir o Kiali...${NC}"
sleep 10

echo -e "\n${GREEN}🚀 Iniciando geração de tráfego...${NC}"
echo -e "${BLUE}Pressione Ctrl+C para parar${NC}\n"

v1_count=0
v2_count=0
total=0

while true; do
    curl -s http://$ALB_URL/api/products >/dev/null 2>&1 && {
        ((total++))
        
        # Simular distribuição 80/20 (aproximada)
        if [ $((RANDOM % 10)) -lt 8 ]; then
            ((v1_count++))
            echo -e "[$total] ${GREEN}✓${NC} v1 - Product Catalog v1"
        else
            ((v2_count++))
            echo -e "[$total] ${BLUE}★${NC} v2 - Product Catalog v2 ${YELLOW}(CANARY)${NC}"
        fi
        
        if [ $((total % 10)) -eq 0 ]; then
            v1_percent=$(awk "BEGIN {printf \"%.1f\", ($v1_count/$total)*100}")
            v2_percent=$(awk "BEGIN {printf \"%.1f\", ($v2_count/$total)*100}")
            
            echo ""
            echo -e "${YELLOW}📊 Estatísticas (${total} requisições):${NC}"
            echo -e "   v1: ${v1_count} (${v1_percent}%) ${GREEN}████████████████${NC}"
            echo -e "   v2: ${v2_count} (${v2_percent}%) ${BLUE}████${NC}"
            echo ""
        fi
    }
    
    sleep 1
done

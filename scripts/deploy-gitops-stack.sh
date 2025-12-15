#!/bin/bash

##############################################################################
# Script: Deploy Complete GitOps Stack
# Description: Automated deployment of infrastructure + Istio + ArgoCD + Apps
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================================================"
echo -e "${BLUE}       GitOps Complete Stack Deployment${NC}"
echo "================================================================"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}terraform not found${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl not found${NC}"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo -e "${RED}aws cli not found${NC}"; exit 1; }
echo -e "${GREEN}✓ All prerequisites found${NC}"
echo ""

# Step 1: Deploy Infrastructure
echo "================================================================"
echo -e "${BLUE}Step 1: Deploying Infrastructure (VPC + EKS)${NC}"
echo "================================================================"
./scripts/01-deploy-infra.sh
echo ""

# Step 2: Install Istio
echo "================================================================"
echo -e "${BLUE}Step 2: Installing Istio Service Mesh${NC}"
echo "================================================================"
./scripts/02-install-istio.sh
echo ""

# Step 3: Install ArgoCD
echo "================================================================"
echo -e "${BLUE}Step 3: Installing ArgoCD${NC}"
echo "================================================================"
cd argocd/install
./install-argocd.sh
cd ../..
echo ""

# Step 4: Deploy ArgoCD Applications
echo "================================================================"
echo -e "${BLUE}Step 4: Deploying ArgoCD Applications${NC}"
echo "================================================================"
cd argocd/install
./deploy-apps.sh
cd ../..
echo ""

# Step 5: Start Monitoring
echo "================================================================"
echo -e "${BLUE}Step 5: Starting Observability Stack${NC}"
echo "================================================================"
./scripts/04-start-monitoring.sh
echo ""

# Get endpoints
echo "================================================================"
echo -e "${GREEN}Deployment Complete!${NC}"
echo "================================================================"
echo ""
echo "📊 Access Points:"
echo ""

# Istio Gateway
ISTIO_GATEWAY=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")
echo "  🌐 Application (Staging): http://$ISTIO_GATEWAY"
echo "  🌐 Application (Production): http://$ISTIO_GATEWAY"
echo ""

# ArgoCD
ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "N/A")
echo "  🔧 ArgoCD UI: https://$ARGOCD_SERVER"
echo "     Username: admin"
echo "     Password: $ARGOCD_PASSWORD"
echo ""

# Grafana
echo "  📈 Grafana: http://localhost:3000 (after port-forward)"
echo "     kubectl port-forward -n istio-system svc/grafana 3000:3000"
echo ""

# Kiali
echo "  🕸️  Kiali: http://localhost:20001 (after port-forward)"
echo "     kubectl port-forward -n istio-system svc/kiali 20001:20001"
echo ""

echo "================================================================"
echo -e "${YELLOW}Next Steps:${NC}"
echo "================================================================"
echo ""
echo "1. Access ArgoCD UI and change admin password"
echo "2. Sync staging application:"
echo "   argocd app sync ecommerce-staging"
echo ""
echo "3. Setup GitHub Actions secrets:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo ""
echo "4. Run ECR setup workflow on GitHub Actions"
echo ""
echo "5. Push code changes to trigger CI/CD pipeline"
echo ""
echo "================================================================"

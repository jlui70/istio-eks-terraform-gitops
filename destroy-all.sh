#!/bin/bash

# ============================================================================
# Script: destroy-all.sh
# Descrição: Destroy completo de toda a infraestrutura
# Autor: DevOps Project
# Data: Dezembro 2025
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# ============================================================================
# Verificações iniciais
# ============================================================================

echo -e "${BLUE}🔍 Verificando AWS credentials...${NC}"
if ! aws sts get-caller-identity &>/dev/null; then
    echo -e "${RED}❌ Erro: Credenciais AWS não configuradas${NC}"
    echo "Configure: aws configure --profile SEU_PERFIL"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
echo -e "${GREEN}✅ AWS Account: $ACCOUNT_ID | Region: $REGION${NC}"

# ============================================================================
# Confirmação
# ============================================================================

echo -e "${RED}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║   ⚠️  DESTRUIR TODA A INFRAESTRUTURA                               ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}⚠️  Este script irá destruir:${NC}"
echo "   • Namespace ecommerce (aplicação)"
echo "   • Istio Service Mesh"
echo "   • EKS Cluster + Node Group"
echo "   • VPC + Subnets + NAT Gateways"
echo "   • (Opcional) S3 Backend + DynamoDB"
echo ""
read -p "Tem certeza que deseja continuar? (s/N): " confirm

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

# ============================================================================
# Step 1: Deletar aplicação do Kubernetes
# ============================================================================

echo -e "\n${YELLOW}[1/5] 🗑️  Deletando aplicação do Kubernetes...${NC}"

# Parar port-forwards antes
pkill -f 'kubectl port-forward' 2>/dev/null || true

# Deletar ArgoCD namespace (GitOps)
if kubectl get namespace argocd &>/dev/null; then
    kubectl delete namespace argocd --timeout=5m
    echo -e "${GREEN}✅ Namespace argocd deletado${NC}"
else
    echo -e "${BLUE}ℹ️  Namespace argocd já não existe${NC}"
fi

# Deletar namespaces da aplicação
for ns in ecommerce ecommerce-staging ecommerce-production; do
    if kubectl get namespace $ns &>/dev/null; then
        kubectl delete namespace $ns --timeout=5m
        echo -e "${GREEN}✅ Namespace $ns deletado${NC}"
    else
        echo -e "${BLUE}ℹ️  Namespace $ns já não existe${NC}"
    fi
done

# ============================================================================
# Step 2: Deletar Istio
# ============================================================================

echo -e "\n${YELLOW}[2/5] 🗑️  Removendo Istio...${NC}"

# Verificar se istioctl está instalado
if command -v istioctl &>/dev/null; then
    istioctl uninstall --purge -y 2>/dev/null || true
    echo -e "${GREEN}✅ Istio uninstall executado${NC}"
else
    echo -e "${BLUE}ℹ️  istioctl não encontrado, deletando via kubectl${NC}"
fi

# Deletar namespace istio-system
if kubectl get namespace istio-system &>/dev/null; then
    kubectl delete namespace istio-system --timeout=5m
    echo -e "${GREEN}✅ Namespace istio-system deletado${NC}"
else
    echo -e "${BLUE}ℹ️  Namespace istio-system já não existe${NC}"
fi

# Aguardar LoadBalancers serem removidos
echo -e "${BLUE}⏳ Aguardando remoção de LoadBalancers (até 2 minutos)...${NC}"
sleep 30

LB_COUNT=$(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[?VpcId!=`null`]' --output json 2>/dev/null | grep -c "LoadBalancerArn" || echo "0")
if [ "$LB_COUNT" -gt "0" ]; then
    echo -e "${YELLOW}⚠️  Ainda existem $LB_COUNT LoadBalancer(s). Aguardando mais 90s...${NC}"
    sleep 90
fi

echo -e "${GREEN}✅ Istio removido${NC}"

# ============================================================================
# Step 3: Destruir Stack 02 (EKS Cluster)
# ============================================================================

echo -e "\n${YELLOW}[3/5] 🗑️  Destruindo Stack 02 (EKS Cluster)...${NC}"
cd "$PROJECT_ROOT/02-eks-cluster"

CLUSTER_NAME="eks-devopsproject-cluster"

# Verificar se cluster existe
if aws eks describe-cluster --name $CLUSTER_NAME --region $REGION &>/dev/null; then
    
    # Tentar destroy via Terraform
    if terraform destroy -auto-approve; then
        echo -e "${GREEN}✅ Stack 02 destruída via Terraform${NC}"
    else
        echo -e "${YELLOW}⚠️  Terraform destroy falhou, tentando via AWS CLI...${NC}"
        
        # Deletar node group via CLI
        NODEGROUP=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME --region $REGION --query 'nodegroups[0]' --output text 2>/dev/null || echo "")
        
        if [ -n "$NODEGROUP" ] && [ "$NODEGROUP" != "None" ]; then
            echo "Deletando node group: $NODEGROUP"
            aws eks delete-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODEGROUP --region $REGION
            echo "Aguardando node group ser deletado (pode demorar 5-10 minutos)..."
            aws eks wait nodegroup-deleted --cluster-name $CLUSTER_NAME --nodegroup-name $NODEGROUP --region $REGION
            echo -e "${GREEN}✅ Node group deletado${NC}"
        fi
        
        # Deletar cluster
        echo "Deletando cluster: $CLUSTER_NAME"
        aws eks delete-cluster --name $CLUSTER_NAME --region $REGION
        echo "Aguardando cluster ser deletado (pode demorar 5-10 minutos)..."
        aws eks wait cluster-deleted --name $CLUSTER_NAME --region $REGION
        echo -e "${GREEN}✅ Cluster deletado${NC}"
        
        # Limpar state do Terraform
        terraform destroy -auto-approve 2>/dev/null || true
        echo -e "${GREEN}✅ Stack 02 destruída via AWS CLI${NC}"
    fi
else
    echo -e "${BLUE}ℹ️  Cluster EKS já não existe${NC}"
    # Tentar limpar state mesmo assim
    terraform destroy -auto-approve 2>/dev/null || true
fi

# ============================================================================
# Step 4: Destruir Stack 01 (Networking)
# ============================================================================

echo -e "\n${YELLOW}[4/5] 🗑️  Destruindo Stack 01 (Networking)...${NC}"
cd "$PROJECT_ROOT/01-networking"

# Verificar se existem NAT Gateways órfãos
echo -e "${BLUE}🔍 Verificando NAT Gateways...${NC}"
NAT_IDS=$(aws ec2 describe-nat-gateways \
    --region $REGION \
    --filter "Name=state,Values=available" \
    --query 'NatGateways[?Tags[?Key==`Project` && Value==`eks-devopsproject`]].NatGatewayId' \
    --output text 2>/dev/null || echo "")

if [ -n "$NAT_IDS" ]; then
    echo -e "${YELLOW}⚠️  Deletando NAT Gateways órfãos via AWS CLI...${NC}"
    for nat_id in $NAT_IDS; do
        echo "Deletando NAT Gateway: $nat_id"
        aws ec2 delete-nat-gateway --nat-gateway-id $nat_id --region $REGION || true
    done
    echo "Aguardando NAT Gateways serem deletados (60s)..."
    sleep 60
fi

# Destroy via Terraform
if terraform destroy -auto-approve; then
    echo -e "${GREEN}✅ Stack 01 destruída${NC}"
else
    echo -e "${RED}❌ Erro ao destruir Stack 01${NC}"
    echo -e "${YELLOW}Tente novamente: cd 01-networking && terraform destroy${NC}"
    exit 1
fi

# ============================================================================
# Step 5: Destruir Stack 00 (Backend) - OPCIONAL
# ============================================================================

echo -e "\n${YELLOW}[5/5] 🗑️  Backend (S3 + DynamoDB)...${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE: Destruir o backend remove o Terraform state!${NC}"
echo "   Você NÃO poderá fazer 'terraform destroy' posteriormente."
echo "   Apenas destrua se não precisar mais do projeto."
echo ""
read -p "Deseja destruir o Backend? (s/N): " destroy_backend

if [[ "$destroy_backend" =~ ^[Ss]$ ]]; then
    echo -e "\n${YELLOW}Destruindo Stack 00 (Backend)...${NC}"
    cd "$PROJECT_ROOT/00-backend"
    
    # Esvaziar bucket S3 antes de deletar
    BUCKET_NAME="eks-devopsproject-state-files-${ACCOUNT_ID}"
    if aws s3 ls "s3://${BUCKET_NAME}" &>/dev/null; then
        echo "Esvaziando bucket S3: $BUCKET_NAME"
        aws s3 rm "s3://${BUCKET_NAME}" --recursive
    fi
    
    # Destroy backend
    if terraform destroy -auto-approve; then
        echo -e "${GREEN}✅ Stack 00 destruída${NC}"
        
        # Limpar arquivos de state local
        cd "$PROJECT_ROOT"
        find . -name "terraform.tfstate*" -type f -delete
        find . -name ".terraform.lock.hcl" -type f -delete
        echo -e "${GREEN}✅ Arquivos de state local removidos${NC}"
    else
        echo -e "${RED}❌ Erro ao destruir Stack 00${NC}"
    fi
else
    echo -e "${BLUE}ℹ️  Backend preservado (S3 + DynamoDB mantidos)${NC}"
    echo -e "${YELLOW}   Para redeploy: basta executar ./scripts/01-deploy-infra.sh${NC}"
fi

# ============================================================================
# Resumo Final
# ============================================================================

cd "$PROJECT_ROOT"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ INFRAESTRUTURA DESTRUÍDA COM SUCESSO!                         ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ ! "$destroy_backend" =~ ^[Ss]$ ]]; then
    echo -e "${BLUE}📝 Backend preservado. Para redeploy:${NC}"
    echo ""
    echo "   cd /home/luiz7/Projects/istio-eks-terraform-complete"
    echo "   ./scripts/01-deploy-infra.sh"
    echo "   ./scripts/02-install-istio.sh"
    echo "   ./scripts/03-deploy-app.sh"
    echo "   ./scripts/04-start-monitoring.sh"
    echo ""
else
    echo -e "${BLUE}📝 Backend destruído. Para redeploy completo:${NC}"
    echo ""
    echo "   cd /home/luiz7/Projects/istio-eks-terraform-complete"
    echo "   ./scripts/01-deploy-infra.sh  # Recriará backend automaticamente"
    echo "   ./scripts/02-install-istio.sh"
    echo "   ./scripts/03-deploy-app.sh"
    echo "   ./scripts/04-start-monitoring.sh"
    echo ""
fi

echo -e "${GREEN}✅ Processo concluído!${NC}"

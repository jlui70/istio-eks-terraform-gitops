#!/bin/bash

# Script para construir imagens Docker demonstráveis com HTML versionado
# Versão para DEMONSTRAÇÃO com mudanças visíveis

set -e

AWS_ACCOUNT_ID=794038226274
AWS_REGION="us-east-1"
ECR_BASE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce"

echo "🎨 Criando imagens demonstráveis para GitOps..."
echo "Versão: $1 (padrão: v1.0.0)"

VERSION="${1:-v1.0.0}"
COLOR="${2:-blue}"

# Login no ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Criar imagem do ecommerce-ui com HTML versionado
echo "📦 Construindo ecommerce-ui ${VERSION}..."

docker build -t ${ECR_BASE}/ecommerce-ui:${VERSION} \
  -t ${ECR_BASE}/ecommerce-ui:staging-latest - <<EOF
FROM nginx:alpine

# Criar HTML com versão e cor personalizadas
RUN cat > /usr/share/nginx/html/index.html <<'HTML'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>E-Commerce - ${VERSION}</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, ${COLOR} 0%, #2c3e50 100%);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .container {
            text-align: center;
            padding: 40px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
        }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .version {
            font-size: 2em;
            font-weight: bold;
            color: #f39c12;
            margin: 20px 0;
            padding: 20px;
            background: rgba(0,0,0,0.3);
            border-radius: 10px;
        }
        .badge {
            display: inline-block;
            padding: 10px 20px;
            background: #27ae60;
            border-radius: 25px;
            margin: 10px;
            font-weight: bold;
        }
        .info {
            margin-top: 30px;
            font-size: 1.1em;
            line-height: 1.6;
        }
        .timestamp {
            margin-top: 20px;
            font-size: 0.9em;
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛒 E-Commerce Platform</h1>
        <div class="version">
            Versão: ${VERSION}
        </div>
        <div class="badge">✅ GitOps Ativo</div>
        <div class="badge">🚀 Istio Service Mesh</div>
        <div class="badge">☁️ AWS EKS</div>
        <div class="info">
            <p><strong>🎯 Microserviços:</strong> 7 serviços rodando</p>
            <p><strong>📊 Observabilidade:</strong> Prometheus + Grafana + Kiali + Jaeger</p>
            <p><strong>🔄 CI/CD:</strong> ArgoCD + GitHub Actions</p>
        </div>
        <div class="timestamp">
            Atualizado em: $(date '+%Y-%m-%d %H:%M:%S')
        </div>
    </div>
</body>
</html>
HTML

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

echo "📤 Enviando para ECR..."
docker push ${ECR_BASE}/ecommerce-ui:${VERSION}
docker push ${ECR_BASE}/ecommerce-ui:staging-latest

echo "✅ Imagem ${VERSION} criada e enviada!"
echo ""
echo "Para testar localmente:"
echo "  docker run -p 8080:80 ${ECR_BASE}/ecommerce-ui:${VERSION}"
echo ""

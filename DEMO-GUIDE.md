# 🎭 Guia Completo de Demonstração

Este guia mostra como realizar uma apresentação profissional do projeto, demonstrando **progressivamente** as funcionalidades do Istio Service Mesh.

---

## 📋 Pré-requisitos

Antes de iniciar a demonstração, certifique-se de que:

1. ✅ Infraestrutura deployada: `./rebuild-all.sh`
2. ✅ Monitoring ativo: `./scripts/04-start-monitoring.sh`
3. ✅ Dashboards abertos:
   - Kiali: http://localhost:20001
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3000
   - Jaeger: http://localhost:16686

---

## 🎬 Cenário 1: Aplicação Estável (100% v1)

### Objetivo
Demonstrar a aplicação funcionando perfeitamente com apenas uma versão.

### Estado Inicial
```bash
# Após ./rebuild-all.sh, você terá:
✅ product-catalog v1 (100% do tráfego)
✅ Sem Canary deployment
✅ Sem Circuit Breaker
```

### Demonstração

**1. Verificar pods rodando:**
```bash
kubectl get pods -n ecommerce
```

**Resultado esperado:**
```
NAME                                READY   STATUS    RESTARTS   AGE
ecommerce-ui-xxx                    2/2     Running   0          5m
product-catalog-xxx                 2/2     Running   0          5m
mongodb-product-catalog-xxx         2/2     Running   0          5m
```

**2. Gerar tráfego:**
```bash
./test-canary-visual.sh
```

**3. Visualizar no Kiali:**
- Acesse: http://localhost:20001
- Graph → Namespace: `ecommerce`
- Display: `Traffic Distribution`

**Resultado esperado:**
```
┌─────────────┐
│ ecommerce-ui│
└─────┬───────┘
      │
      │ 100% v1
      ▼
┌─────────────────┐
│product-catalog  │ (verde - saudável)
│     v1          │
└─────────────────┘
```

**4. Verificar métricas no Prometheus:**
```promql
# Query 1: Ver todas as requisições
istio_requests_total{destination_service_namespace="ecommerce"}

# Query 2: Confirmar 100% em v1
sum by (destination_version) (
  istio_requests_total{destination_service_namespace="ecommerce"}
)s
**✅ Demonstração 1 completa!**

---

## 🎬 Cenário 2: Canary Deployment (80% v1 / 20% v2)

### Objetivo
Demonstrar deploy gradual de uma nova versão (Canary pattern).

### Executar Demo

```bash
./istio/install/demo-deploy-v2-canary.sh
```

### Demonstração

**1. Verificar pods após deploy:**
```bash
kubectl get pods -n ecommerce -l app=product-catalog
```

**Resultado esperado:**
```
NAME                                 READY   STATUS    RESTARTS   AGE
product-catalog-xxx                  2/2     Running   0          15m  ← v1
product-catalog-v2-xxx               2/2     Running   0          1m   ← v2 (Canary)
```

**2. Gerar tráfego para ver distribuição:**
```bash
./test-canary-visual.sh
```

**3. Visualizar Canary no Kiali:**

**Resultado esperado:**
```
┌─────────────┐
│ ecommerce-ui│
└─────┬───────┘
      │
      ├─────── 80% ─────▶ product-catalog v1 (verde)
      │
      └─────── 20% ─────▶ product-catalog v2 (verde)
```

**4. Verificar distribuição no Prometheus:**
```promql
# Tráfego por versão
sum by (destination_service_name, destination_version) (
  istio_requests_total{destination_service_namespace="ecommerce"}
)
```

**Resultado esperado:**
```
product-catalog v1: 80%
product-catalog v2: 20%
```

**5. Ver latência p99:**
```promql
histogram_quantile(0.99,
  sum(rate(istio_request_duration_milliseconds_bucket{
    destination_service_namespace="ecommerce"
  }[5m])) by (le, destination_service_name)
)
```

**✅ Demonstração 2 completa!**

---

## 🎬 Cenário 3: Circuit Breaker em Ação

### Objetivo
Demonstrar resiliência: quando v2 falha, circuit breaker redireciona 100% para v1.

### Executar Demo

```bash
./istio/install/demo-deploy-circuit-breaker.sh
```

### Demonstração

**1. Verificar deploy do order-management v2:**
```bash
kubectl get pods -n ecommerce -l app=order-management
```

**Resultado esperado:**
```
NAME                                  READY   STATUS    RESTARTS   AGE
order-management-v2-xxx               2/2     Running   0          1m   ← v2 (com bug)
```

**2. FASE 1: Provocar o erro**

```bash
# Gerar tráfego INTENSO (vai começar a dar erro!)
./test-canary-visual.sh
```

**No Kiali, você verá:**
```
┌─────────────┐
│ ecommerce-ui│
└─────┬───────┘
      │
      │ ERROS! (vermelho)
      ▼
┌──────────────────┐
│order-management  │ (vermelho - 500 errors)
│      v2          │
└──────────────────┘
```

**3. FASE 2: Circuit Breaker detecta e faz TRIP**

Continue gerando tráfego. Em 30-60 segundos, o Istio detecta os erros e ativa o circuit breaker.

**No Kiali:**
```
Circuit Breaker ATIVADO ⚡
Tráfego redirecionado 100% para v1

┌─────────────┐
│ ecommerce-ui│
└─────┬───────┘
      │
      │ 100% v1 (fallback)
      ▼
┌──────────────────┐
│order-management  │ (verde - saudável)
│      v1          │
└──────────────────┘
```

**4. FASE 3: Verificar logs do erro**

```bash
kubectl logs -n ecommerce -l app=order-management,version=v2 --tail=50
```

**Resultado esperado:**
```
[ERROR] Simulated failure in order-management v2
[ERROR] Returning 500 Internal Server Error
```

**5. FASE 4: Aplicação volta ao normal**

Continue gerando tráfego com `./test-canary-visual.sh`

**No Kiali:**
- ✅ Todas conexões verdes
- ✅ Tráfego 100% em v1
- ✅ Aplicação funcionando perfeitamente

**✅ Demonstração 3 completa!**

---

## 📊 Dashboards Recomendados

### Kiali (Topologia)
- **URL**: http://localhost:20001
- **Use para**: Visualizar fluxo de tráfego em tempo real
- **Dicas**:
  - Display → Traffic Distribution
  - Ativar "Traffic Animation"
  - Ver % de tráfego em cada versão

### Prometheus (Métricas)
- **URL**: http://localhost:9090
- **Use para**: Validar distribuição de tráfego
- **Queries úteis**:
  ```promql
  # Distribuição por versão
  sum by (destination_version) (istio_requests_total{destination_service_namespace="ecommerce"})
  
  # Taxa de requisições
  rate(istio_requests_total{destination_service_namespace="ecommerce"}[5m])
  
  # Códigos de resposta
  sum by (response_code) (istio_requests_total{destination_service_namespace="ecommerce"})
  ```

### Grafana (Dashboards)
- **URL**: http://localhost:3000
- **Use para**: Visualizações bonitas para apresentações
- **Dashboards**:
  - Istio Service Dashboard
  - Istio Workload Dashboard

### Jaeger (Distributed Tracing)
- **URL**: http://localhost:16686
- **Use para**: Rastreamento de requisições end-to-end
- **Dicas**:
  - Service: `ecommerce-ui`
  - Ver latência de cada hop

---

## 🎯 Roteiro Completo de Apresentação

### Tempo estimado: 15-20 minutos

**1. Introdução (2 min)**
- Explicar arquitetura (EKS + Istio)
- Mostrar stack de observabilidade
- Objetivos da demo

**2. Cenário 1 - Baseline (3 min)**
- Deploy inicial (v1 apenas)
- Gerar tráfego
- Mostrar no Kiali: fluxo saudável
- Métricas no Prometheus

**3. Cenário 2 - Canary (5 min)**
- Executar `demo-deploy-v2-canary.sh`
- Explicar: "Nova versão vai receber 20% do tráfego"
- Gerar tráfego
- Mostrar no Kiali: split 80/20
- Prometheus: confirmar distribuição

**4. Cenário 3 - Circuit Breaker (7 min)**
- Executar `demo-deploy-circuit-breaker.sh`
- Explicar: "v2 tem um bug proposital"
- Gerar tráfego → ver erros no Kiali
- Aguardar circuit breaker ativar
- Mostrar fallback 100% v1
- Ver logs do erro
- Aplicação volta ao normal

**5. Conclusão (2 min)**
- Recap dos patterns demonstrados:
  - ✅ Service Mesh (Istio)
  - ✅ Canary Deployment
  - ✅ Circuit Breaker (resiliência)
  - ✅ Observabilidade completa
- Mostrar stack completa (Prometheus/Grafana/Kiali/Jaeger)

---

## 🔧 Troubleshooting

### Pods não sobem
```bash
kubectl describe pod <pod-name> -n ecommerce
kubectl logs <pod-name> -n ecommerce -c istio-proxy
```

### Kiali não mostra tráfego
```bash
# Verificar se está gerando tráfego
./test-canary-visual.sh

# Verificar injeção do sidecar
kubectl get pods -n ecommerce -o jsonpath='{.items[*].spec.containers[*].name}'
# Deve mostrar: app + istio-proxy
```

### Circuit Breaker não ativa
```bash
# Gerar MUITO tráfego
for i in {1..1000}; do ./test-canary-visual.sh; done

# Verificar regras do Istio
kubectl get destinationrule -n ecommerce -o yaml
```

---

## 📚 Referências

- [Istio Documentation](https://istio.io/latest/docs/)
- [Canary Deployments](https://istio.io/latest/docs/concepts/traffic-management/#canary-deployments)
- [Circuit Breaking](https://istio.io/latest/docs/tasks/traffic-management/circuit-breaking/)

---

## 🎬 SCRIPTS DE DEMONSTRAÇÃO

| Script | Descrição | Quando usar |
|--------|-----------|-------------|
| `rebuild-all.sh` | Deploy completo do zero | Início da apresentação |
| `./scripts/04-start-monitoring.sh` | Inicia dashboards | Após rebuild |
| `./test-canary-visual.sh` | Gera tráfego para visualização | Durante toda a demo |
| `./istio/install/demo-deploy-v2-canary.sh` | Demo Canary 80/20 | Cenário 2 |
| `./istio/install/demo-deploy-circuit-breaker.sh` | Demo Circuit Breaker | Cenário 3 |

---

**✨ Boa apresentação!**

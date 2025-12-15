# Desafio Técnico – Gitops - DevOps Project

---

## 🎯 Proposta do Desafio

Missão: construir um pipeline de deploy seguro, escalável e eficiente, que permita a publicação de aplicações em ambientes de **staging e produção**, seguindo boas práticas de infraestrutura, automação e segurança, visto que todos nossos dados são tratados como sensíveis.

Este desafio simula exatamente a rotina do time de DevOps da Devops Project, garantindo que o deploy seja estável, documentado e confiável, tanto em staging quanto em produção.

Construir um ambiente de deploy seguro, estável e inclusivo.

---

## 📝 Sobre a aplicação

Crie um repositório contendo a aplicação Ecommerce (rota `/status`) e um Dockerfile configurado. 

A partir disso, você poderá adaptar ou propor melhorias na estrutura de CI/CD para otimizar o processo de deploy.

---

### 📋 **Itens obrigatórios:**

- ✅ **Setup de ambientes:**
    
    🔸 **Staging e produção**, ambos na AWS, utilizando:
    
    - Docker
    - GitHub Actions
    - AWS (EC2, Lightsail, ECS ou serviço equivalente)

- ✅ **Deploy da aplicação ecoomerce:**
    
    🔸 Uma aplicação e-commerce completa com microserviços hospedada nos ambientes.

    🔸## 🛍️ Microserviços Incluídos

    1. **ecommerce-ui**: Frontend React da aplicação
    2. **product-catalog**: Catálogo de produtos com API REST
    3. **order-management**: Gerenciamento de pedidos
    4. **product-inventory**: Controle de estoque
    5. **profile-management**: Perfis de usuário
    6. **shipping-handling**: Logística e entrega  
    7. **contact-support**: Suporte ao cliente
    8. **mongodb**: Banco de dados para persistência
    
        
- ✅ **Pipeline CI/CD completo:**
    
    🔸 Utilizando GitHub Actions, contendo:
    
    - Build da imagem
    - Testes (mínimo validação do container)
    - Deploy automatizado para staging e produção
    - Steps claros, com validação antes do deploy

- ✅ **Segurança como pilar:**
    
    🔸 Gerenciamento seguro de secrets (via GitHub Secrets ou AWS Secrets Manager)
    
    🔸 Configuração de CORS se aplicável
    
    🔸 Uso obrigatório de HTTPS/TLS no ambiente
    
    🔸 Políticas de acesso restritivas nos ambientes (princípio do menor privilégio)
    
- ✅ **Observabilidade:**
    
    🔸 Logs acessíveis da aplicação e do deploy
    
    🔸 Proposta ou implementação de monitoramento básico (Grafana - Prometheus)
    
- ✅ **Documentação obrigatória:**
    
    🔸 README contendo:
    
    - Setup dos ambientes
    - Fluxo de CI/CD (com desenho se possível)
    - Registro dos erros encontrados e decisões tomadas
    - Processo de rollback
    - Checklist de segurança aplicado

- ✅ **Rollback funcional:**
    
    🔸 Descreva no README como executar rollback de forma segura.
    
    🔸 Sugestões: Deploy Blue/Green, revert de imagem Docker, ou rollback manual documentado.
    
- 🟨 **(Bônus recomendado - ganha pontos extras no desafio):**
        
    🔸 Implementação de alertas via Slack e AWS SNS    

---

## 🧩 Como irá fazer:

1. Realizar o setup dos ambientes de **staging** e **produção**, usando:
    - Docker
    - AWS
    - GitHub Actions
2. Aplicar um **deploy completo da aplicação E-commerce** (em um repositório no GitHub).
3. Documentar todas as etapas do processo: ex: erros encontrados, decisões técnicas, melhorias propostas e o que achar pertinente para uma boa compreensão do projeto.
4. Documentar como seria feito o **rollback** da aplicação em caso de falha no deploy.

---

## 📅 Entrega

<aside>
📁

- Um breve texto contando por que é importante implementar gipops nos projetos DevOps.
- Link dos ambientes de staging e produção
- Link do repositório no GitHub (público)
</aside>

---

## 🏗️ **Critérios de Aceite**

| Item | Obrigatório | Observações |
| --- | --- | --- |
| Deploy funcional (staging e produção) | ✅ | Ambientes separados, funcionando corretamente. |
| Docker + GitHub Actions + AWS | ✅ | Configuração robusta e replicável. |
| Pipeline CI/CD completo com validações | ✅ | Inclui lint, testes (mínimos), build e deploy. |
| Segurança aplicada (secrets, HTTPS, acesso) | ✅ | Demonstra responsabilidade com ambientes sensíveis. |
| Observabilidade (logs) | ✅ | Logs do deploy e da aplicação configurados. |
| Documentação clara no README | ✅ | Fluxo do pipeline, ambientes, rollback, checklist de segurança. |
| Monitoramento e alertas básicos | ✅ | Fortemente recomendado (Grafana, Slack, etc.) |
| Rollback documentado e funcional | ✅ | Pode ser via Docker, GitHub Actions, AWS ou estratégia sugerida. |

---
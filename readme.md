# Assessment - Infraestrutura Kubernetes com Terraform

## Pré-requisitos
- Azure CLI
- Terraform
- kubectl
- Conta Azure com permissões adequadas

## Como executar

### 1. Preparação do ambiente
```bash
az login
git clone <seu-repositorio>
cd <seu-repositorio>
```

### 2. Provisionar a infraestrutura
```bash
terraform init
terraform plan
terraform apply
```

### 3. Deploy da aplicação
```bash
az aks get-credentials --resource-group rg-assessment-app --name aks-assessment
kubectl apply -f kubernetes-deployment.yaml
```

### 4. Validação
Para verificar se a aplicação está funcionando corretamente:

1. Verificar se o pod está rodando:
```bash
kubectl get pods -n assessment-app
```

2. Verificar o serviço e obter o IP público:
```bash
kubectl get svc -n assessment-app
```

3. Testar a aplicação:
```bash
curl http://<IP-DO-SERVICO>:80
```

## Arquitetura

A solução inclui:
- AKS (Azure Kubernetes Service)
- Azure Key Vault
- Azure Database for PostgreSQL
- Namespace dedicado para a aplicação

## Segurança
- A aplicação tem acesso ao Key Vault através de Managed Identity
- Banco de dados configurado com SSL
- Secrets gerenciados via Key Vault

## Manutenção
Para atualizar a infraestrutura:
```bash
terraform plan
terraform apply
```

Para remover a infraestrutura:
```bash
terraform destroy
```
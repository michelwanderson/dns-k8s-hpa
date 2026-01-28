# DNS BIND no Kubernetes com HPA e Observabilidade

Este projeto implementa um servidor DNS autoritativo utilizando BIND9 em um cluster Kubernetes. A arquitetura utiliza StatefulSets para gerenciamento dos Pods, ConfigMaps para configurações e zonas DNS, e Horizontal Pod Autoscaler (HPA) para escalabilidade automática baseada no uso de CPU. O projeto também inclui uma camada de observabilidade com Prometheus e Grafana.

## Estrutura do Projeto

O projeto está organizado em diretórios correspondentes aos namespaces (`dns-a`, `dns-b`), contendo os manifestos necessários:

- **namespaces.yaml**: Define os namespaces `dns-a` e `dns-b`.
- **dns-a/**:
  - `configmap-bind.yaml`: Configuração principal do BIND (`named.conf`).
  - `configmap-zone.yaml`: Arquivo de zona para o domínio `meudominio.com`.
  - `statefulset-bind.yaml`: Definição do workload (StatefulSet) com imagem `bind9:9.18`.
  - `service-dns.yaml`: Serviço NodePort expondo a porta 53 (UDP/TCP) na porta externa **30053**.
  - `hpa.yaml`: Configuração de autoscaling (Min: 2, Max: 8 réplicas) com target de 20% de CPU.
- **observability/**: Contém os recursos para monitoramento (Prometheus e Grafana).

## Pré-requisitos

- Cluster Kubernetes em execução.
- `kubectl` configurado.
- `metrics-server` instalado no cluster (essencial para o funcionamento do HPA).

## Instalação

1. **Criar os Namespaces**
   ```bash
   kubectl apply -f namespaces.yaml
   ```

2. **Implantar a Observabilidade**
   Aplique os manifestos da pasta `observability` (Prometheus e Grafana):
   ```bash
   kubectl apply -f observability/
   ```

3. **Implantar o Ambiente DNS (Exemplo: dns-a)**
   Aplique as configurações, zonas, serviço e o StatefulSet:
   ```bash
   kubectl apply -f dns-a/configmap-bind.yaml
   kubectl apply -f dns-a/configmap-zone.yaml
   kubectl apply -f dns-a/service-dns.yaml
   kubectl apply -f dns-a/statefulset-bind.yaml
   ```

4. **Aplicar o HPA**
   ```bash
   kubectl apply -f dns-a/hpa.yaml
   ```

## Como Testar

O serviço DNS está exposto via NodePort na porta **30053**. Você pode testar a resolução de nomes utilizando o `dig`.

Substitua `<NODE_IP>` pelo IP de um dos nós do seu cluster (ou `127.0.0.1` se estiver local/Docker Desktop).

```bash
dig @<NODE_IP> -p 30053 www.meudominio.com
```

**Resposta Esperada:**
Deve retornar o IP `10.10.10.10` configurado na zona.

## Monitoramento e Autoscaling

O monitoramento é realizado via Prometheus (coleta de métricas) e Grafana (visualização). O StatefulSet do BIND possui um container sidecar (`bind-exporter`) que expõe as métricas na porta 9119.

### Acessando o Grafana
O Grafana está exposto via NodePort na porta **30050**.
- **URL**: `http://<NODE_IP>:30050`
- **Login**: `admin` / `admin123`

### Acessando o Prometheus
Para acessar o Prometheus, utilize o port-forward:
```bash
kubectl port-forward -n observability deploy/prometheus 9090:9090
```
Acesse em: `http://localhost:9090`

### Verificando o HPA
Para verificar o status do HPA e o número de réplicas:

```bash
kubectl get hpa -n dns-a
kubectl get pods -n dns-a
```

O HPA está configurado para escalar horizontalmente quando a utilização média de CPU ultrapassar 20%.

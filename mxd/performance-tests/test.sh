

helm install otel-collector-cluster open-telemetry/opentelemetry-collector --values <path where you saved the chart>

function send_trace_data {
  local collector_ip="100.64.1.70"  # Replace with the IP of your OpenTelemetry Collector service
  local port="4317"
  local endpoint="http://${collector_ip}:${port}/v1/traces"
  local trace_data="$1"
  curl -X POST -H "Content-Type: application/json" -d "$trace_data" "$endpoint" >/dev/null 2>&1
}


function init_trace {
  local size=$1
  local trace_data="{\"event\": \"Init\", \"size\": \"$size\", \"timestamp\": \"$(date +%s)\"}"
  send_trace_data "$trace_data"
}

helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.5.3
kubectl get pods -n cert-manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.3/cert-manager.crds.yaml
helm install jaeger jaegertracing/jaeger-operator
kubectl apply -f jaeger-instance.yaml
#!/bin/bash

# HTTP Request function to send trace data to OpenTelemetry Collector
function send_trace_data {
  local collector_ip="100.64.1.70"  # Replace with the IP of your OpenTelemetry Collector service
  local port="4317"
  local endpoint="http://${collector_ip}:${port}/v1/traces"
  local trace_data="$1"
  curl -X POST -H "Content-Type: application/json" -d "$trace_data" "$endpoint" >/dev/null 2>&1
}

# Initialize trace data
function init_trace {
  local size=$1
  local trace_data="{\"event\": \"Init\", \"size\": \"$size\", \"timestamp\": \"$(date +%s)\"}"
  send_trace_data "$trace_data"
}

# Copy trace data when tests are ready
function copy_trace_data_when_tests_ready {
  local pod_name=$1
  local trace_data="{\"event\": \"TestsReady\", \"pod_name\": \"$pod_name\", \"timestamp\": \"$(date +%s)\"}"
  send_trace_data "$trace_data"
}

# Cleanup trace data
function cleanup_trace {
  local trace_data="{\"event\": \"Cleanup\", \"timestamp\": \"$(date +%s)\"}"
  send_trace_data "$trace_data"
}

# List of all available t-shirt sizes
MODE=("M")
LOG_MESSAGE="Test Completed"
POD_NAME="mxd-performance-test"
GENERATED_OUTPUT_FILE="/opt/apache-jmeter-5.5/mxd-performance-evaluation/output.tar"
GENERATED_OUTPUT_SLIM_FILE="/opt/apache-jmeter-5.5/mxd-performance-evaluation/output_slim.tar"
TERRAFORM_CHDIR="/Users/artser/eclipse-tractusx_tutorial-resources/mxd/"
LOGFILE="sml_script_$(date +%d-%m-%YT%H-%M-%S).logs"
IS_DEBUG=true

# Functions

# Prints informational messages
function info {
  echo -e "$(date +%d-%m-%Y) $(date +%H:%M:%S) \033[32m INFO \033[0m $@"
}

# Prints debug messages
function debug {
  if [[ $IS_DEBUG == true ]]; then
    echo -e "$(date +%d-%m-%Y) $(date +%H:%M:%S) \033[33m DEBUG \033[0m $@"
  fi
}

# Prints error messages and exits with error code
function error_exit {
  echo -e "$(date +%d-%m-%Y) $(date +%H:%M:%S) \033[31m ERROR \033[0m $@"
  exit 1
}

# Initializes the test
function init {
  local size=$1
  info "Testing $size t-shirt size"
  init_trace "$size"  # Send trace data
  kubectl create configmap special-config --from-literal=JMETER_SCRIPT="" --from-literal=T_SHIRT_SIZE="-q $size" | debug || error_exit "Failed to create configmap"
  info "Init terraform"
  terraform -chdir="$TERRAFORM_CHDIR" init >> "$LOGFILE" || error_exit "Failed to initialize Terraform"
  info "Apply terraform"
  terraform -chdir="$TERRAFORM_CHDIR" apply -auto-approve  >> "$LOGFILE"
  info "Start the performance-test container"
  kubectl apply -f performance-test.yaml | debug || error_exit "Failed to start performance-test container"
  info "Waiting for container ready state"
  kubectl wait --for=condition=ready "pod/$POD_NAME" | debug || error_exit "Container failed to reach ready state"
}

# Copies output file when tests are ready
function copyFileWhenTestsReady {
  local pod_name=$1
  info "Waiting for the tests to finish ..."
  while true; do
    logs=$(kubectl logs --tail=5 "$pod_name" 2>/dev/null)
    if echo "$logs" | grep -q "$LOG_MESSAGE"; then
      info "Log message found in the logs."
      copy_trace_data_when_tests_ready "$pod_name"  # Send trace data
      kubectl cp --retries=-1 "${pod_name}:${GENERATED_OUTPUT_FILE}" "output_${char}.tar" | debug || error_exit "Failed to copy output file"
      info "Test Report downloaded with name output_${char}.tar"
      kubectl cp --retries=-1 "${pod_name}:${GENERATED_OUTPUT_SLIM_FILE}" "output_slim_${char}" | debug || error_exit "Failed to copy output slim file"
      info "Test Report downloaded with name output_slim_${char}.tar"
      break
    else
      echo "Waiting for log message" | debug
      sleep 5
    fi
  done
}

# Cleans up resources
function cleanup {
  info "Destroying terraform"
  cleanup_trace  # Send trace data
  terraform -chdir="$TERRAFORM_CHDIR" destroy -auto-approve >> "$LOGFILE" || error_exit "Failed to destroy Terraform"
  info "Destroying pod"
  kubectl delete pod "$POD_NAME" | debug || error_exit "Failed to delete pod"
  info "Destroying configmap"
  kubectl delete configmap special-config | debug || error_exit "Failed to delete configmap"
  info "Waiting for the pod to be deleted"
  kubectl wait --for=delete "pod/$POD_NAME" || error_exit "Failed to wait for pod deletion"
  info "Execution finished."
  exit 0
}

# Execute cleanup when CONTROL+C is invoked
trap "cleanup" INT

# Main loop
for char in "${MODE[@]}"; do
  init "$char"
  copyFileWhenTestsReady "$POD_NAME"
  cleanup
done

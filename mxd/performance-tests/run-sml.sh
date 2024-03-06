#!/bin/bash

# Function to display help information
function display_help {
    echo "Options:"
    echo "  -f  Set the the path to file/folder with experiment files (default: \"test-configurations/small_experiment.properties\")"
    echo "  -l  Set the log message which indicates the finish of test execution (default: \"Test Completed\")"
    echo "  -p  Set the pod name (default: \"mxd-performance-test\")"
    echo "  -g  Set the generated output file path (default: \"/opt/apache-jmeter-5.5/mxd-performance-evaluation/output.tar\")"
    echo "  -s  Set the generated output_slim file path (default: \"/opt/apache-jmeter-5.5/mxd-performance-evaluation/output_slim.tar\")"
    echo "  -t  Set the Terraform directory (default: \"/Users/ciprian/IdeaProjects/tutorial-resources/mxd/\")"
    echo "  -c  Set the destination name name of experiment properties file when mounting on the pod (default: \"custom_experiment.properties\")"
    echo "  -o  Set the terraform log file name (default: \"sml_script_[current_datetime].logs\")"
    echo "  -d  Enable debug mode (default: true)"
    echo "  -m  Enable monitoring mode (default: false)"
    exit 0
}

PROVIDED_PATH="test-configurations/small_experiment.properties"
LOG_MESSAGE="Test Completed"
POD_NAME="mxd-performance-test"
GENERATED_OUTPUT_FILE="/opt/apache-jmeter-5.5/mxd-performance-evaluation/output.tar"
GENERATED_OUTPUT_SLIM_FILE="/opt/apache-jmeter-5.5/mxd-performance-evaluation/output_slim.tar"
TERRAFORM_CHDIR="/Users/ciprian/IdeaProjects/tutorial-resources/mxd/"
CUSTOM_PROPERTIES="custom_experiment.properties"
LOGFILE="sml_script_$(date +%d-%m-%YT%H-%M-%S).logs"
IS_DEBUG=true
IS_MONITORING_ENABLED=false
extension=".properties"

# Parse command-line options
while getopts "f:l:p:g:s:t:c:o:d:" opt; do
    case $opt in
        f) PROVIDED_PATH=$OPTARG;;
        l) LOG_MESSAGE=$OPTARG;;
        p) POD_NAME=$OPTARG;;
        g) GENERATED_OUTPUT_FILE=$OPTARG;;
        s) GENERATED_OUTPUT_SLIM_FILE=$OPTARG;;
        t) TERRAFORM_CHDIR=$OPTARG;;
        c) CUSTOM_PROPERTIES=$OPTARG;;
        o) LOGFILE=$OPTARG;;
        d) IS_DEBUG=$OPTARG;;
        m) IS_MONITORING_ENABLED=$OPTARG;;
        \?) echo "Invalid option: -$OPTARG" >&2; display_help exit 1;;
    esac
done

# Prints informational messages
function info {
  echo -e "$(date +%d-%m-%Y) $(date +%H:%M:%S) \033[32m INFO  \033[0m $@"
}

# Prints debug messages
function debug {
  read IN
  if [[ $IS_DEBUG == true ]]; then
    echo -e "$(date +%d-%m-%Y) $(date +%H:%M:%S) \033[33m DEBUG \033[0m $IN"
  fi
}

# Prints error messages and exits with error code
function error_exit {
  echo -e "$(date +%d-%m-%Y) $(date +%H:%M:%S) \033[31m ERROR \033[0m $@"
  #cleanup
  #exit 1
}

# Initializes the test
function init {
  if [[ $IS_MONITORING_ENABLED == true ]]; then
      info "monitoring enabled"

    # Add Helm repositories
    helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
    helm repo add jetstack https://charts.jetstack.io
    helm repo update

    # Check if cert-manager is already installed
    if ! kubectl get namespace cert-manager &>/dev/null; then
        # Install cert-manager
        kubectl create namespace cert-manager
        helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.5.3
        kubectl get pods -n cert-manager
        kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.3/cert-manager.crds.yaml
    else
        info "cert-manager is already installed"
    fi

    # Install Jaeger
    helm install jaeger jaegertracing/jaeger-operator
    kubectl apply -f jaeger-instance.yaml

    # Install Open Telemetry Collector
    helm upgrade --install otel-collector-cluster open-telemetry/opentelemetry-collector --values otel-collector-values.yaml
  fi

  local experiment_file=$1
  info "Adding ${experiment_file} on pod using custom-property configmap"
  kubectl create configmap custom-property --from-file="${CUSTOM_PROPERTIES}"="${experiment_file}"  | debug || error_exit "Failed to create configmap with name custom-property"
  info "Init terraform"
  terraform -chdir="$TERRAFORM_CHDIR" init >> "$LOGFILE" || error_exit "Failed to initialize Terraform"
  info "Apply terraform"
  terraform -chdir="$TERRAFORM_CHDIR" apply -auto-approve  >> "$LOGFILE" || error_exit "Failed to apply Terraform"
  info "Start the performance-test container"
  kubectl apply -f performance-test.yaml | debug || error_exit "Failed to start performance-test container"
  info "Waiting for container ready state"
  kubectl wait --for=condition=ready "pod/$POD_NAME" | debug || error_exit "Container failed to reach ready state"
}

# Copies output file when tests are ready
function copyFileWhenTestsReady {
  local experiment_file=$1
  info "Waiting for the tests to finish ..."
  while true; do
    logs=$(kubectl logs --tail=5 "$POD_NAME" 2>/dev/null)
    if echo "$logs" | grep -q "$LOG_MESSAGE"; then
      info "Log message found in the logs."
      kubectl cp --retries=-1 "${POD_NAME}:${GENERATED_OUTPUT_FILE}" "${experiment_file}.tar"
      info "Test Report downloaded with name output_${experiment_file}.tar"
      kubectl cp --retries=-1 "${POD_NAME}:${GENERATED_OUTPUT_SLIM_FILE}" "${experiment_file}_slim.tar"
      info "Test Report downloaded with name output_${experiment_file}_slim.tar"
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
  terraform -chdir="$TERRAFORM_CHDIR" destroy -auto-approve >> "$LOGFILE" || error_exit "Failed to destroy Terraform"
  info "Destroying pod"
  kubectl delete pod "$POD_NAME" | debug || error_exit "Failed to delete pod"
  info "Destroying configmap"
  kubectl delete configmap custom-property | debug || error_exit "Failed to delete configmap custom-property"
  info "Waiting for the pod to be deleted"
  kubectl wait --for=delete "pod/$POD_NAME"
  info "Execution finished."
}

# Cleans up resources and exit
function cleanup_and_exit {
  cleanup
  exit 0
}

function startForSingleFile {
  local experiment_file=$1
  info Start experiment for file $experiment_file

  init "$experiment_file"
  copyFileWhenTestsReady "$experiment_file"
  cleanup
}

function startForDirectory {
  local folder_path=$1
  # Use an array to store the all properties file in provided folder
  local files_array=()

  # Populate the array using a loop
  while IFS= read -r -d '' file; do
      files_array+=("$file")
  done < <(find "$folder_path" -type f -name "*$extension" -print0)

  # Show detected files
  for file in "${files_array[@]}"; do
      info "Detected following properties file: $file"
  done

  # Start test for one file at a time
  for file in "${files_array[@]}"; do
      startForSingleFile "$file"
  done
}

function main {
  if [ -e "$PROVIDED_PATH" ]; then
      if [ -f "$PROVIDED_PATH" ]; then
          info "$PROVIDED_PATH is a file."
          startForSingleFile "$PROVIDED_PATH"
      elif [ -d "$PROVIDED_PATH" ]; then
          info "$PROVIDED_PATH is a directory."
          startForDirectory "$PROVIDED_PATH"
      else
          info "$PROVIDED_PATH exists but is neither a file nor a directory."
      fi
  else
      info "$PROVIDED_PATH does not exist."
  fi
}

# Execute cleanup when CONTROL+C is invoked
trap cleanup_and_exit INT

# Script entry point
main
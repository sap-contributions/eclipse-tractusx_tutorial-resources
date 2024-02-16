#!/bin/bash

# Function to display help information
function display_help {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -m MODE      Set t-shirt size(s) as a coma-separated list (e.g., \"S,M,L,C\")"
    echo "               C - custom property file provided with -c param will be used"
    echo "               S-small, M-medium, L-large"
    echo "               Default S"
    echo "  -l LOG_MSG   Set the log message which indicates the finis of test execution (default: \"Test Completed\")"
    echo "  -p POD_NAME  Set the pod name (default: \"mxd-performance-test\")"
    echo "  -g OUTPUT    Set the generated output file (default: \"/opt/apache-jmeter-5.5/mxd-performance-evaluation/output.tar\")"
    echo "  -t TERRAFORM Set the Terraform directory (default: \"/Users/ciprian/IdeaProjects/tutorial-resources/mxd/\")"
    echo "  -c CUSTOM    Set the custom properties file (default: \"custom_experiment.properties\")"
    echo "  -o LOG_FILE  Set the log file name (default: \"sml_script_[current_datetime].logs\")"
    echo "  -d DEBUG     Enable debug mode (default: true)"
    echo "  -help        Display this help message"
    exit 0
}

# List of all available t-shirt sizes
#MODE=("S" "M" "L")
MODE=("S")
LOG_MESSAGE="Test Completed"
POD_NAME="mxd-performance-test"
GENERATED_OUTPUT_FILE="/opt/apache-jmeter-5.5/mxd-performance-evaluation/output.tar"
TERRAFORM_CHDIR="/Users/ciprian/IdeaProjects/tutorial-resources/mxd/"
CUSTOM_PROPERTIES="custom_experiment.properties"
LOGFILE="sml_script_$(date +%d-%m-%YT%H-%M-%S).logs"
IS_DEBUG=true

# Parse command-line options
while getopts "m:l:p:g:t:c:o:d:h:" opt; do
    case $opt in
        m)
            IFS=',' read -ra MODE <<< "$OPTARG"
            ;;
        l) LOG_MESSAGE=$OPTARG;;
        p) POD_NAME=$OPTARG;;
        g) GENERATED_OUTPUT_FILE=$OPTARG;;
        t) TERRAFORM_CHDIR=$OPTARG;;
        c) CUSTOM_PROPERTIES=$OPTARG;;
        o) LOGFILE=$OPTARG;;
        d) IS_DEBUG=$OPTARG;;
        h) display_help;;
        \?) echo "Invalid option: -$OPTARG" >&2; display_help exit 1;;
    esac
done

# Parse command-line options
while getopts "m:l:p:g:t:c:o:d:" opt; do
    case $opt in
        m)
            IFS=',' read -ra MODE <<< "$OPTARG"
            ;;
        l) LOG_MESSAGE=$OPTARG;;
        p) POD_NAME=$OPTARG;;
        g) GENERATED_OUTPUT_FILE=$OPTARG;;
        t) TERRAFORM_CHDIR=$OPTARG;;
        c) CUSTOM_PROPERTIES=$OPTARG;;
        o) LOGFILE=$OPTARG;;
        d) IS_DEBUG=$OPTARG;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
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
  read IN
  echo -e "$(date +%d-%m-%Y) $(date +%H:%M:%S) \033[31m ERROR \033[0m $@ original error: $IN"
  exit 1
}

# Initializes the test
function init {
  local size=$1
  info "Testing $size t-shirt size"
  kubectl create configmap special-config --from-literal=JMETER_SCRIPT="" --from-literal=T_SHIRT_SIZE="$size" | debug || error_exit "Failed to create special-config configmap"
  kubectl create configmap custom-property --from-file=custom_experiment.properties=$CUSTOM_PROPERTIES  | debug || error_exit "Failed to create configmap custom-property"
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
  local size=$1
  info "Waiting for the tests to finish ..."
  while true; do
    logs=$(kubectl logs --tail=5 "$POD_NAME" 2>/dev/null)
    if echo "$logs" | grep -q "$LOG_MESSAGE"; then
      info "Log message found in the logs."
      kubectl cp --retries=-1 "${POD_NAME}:${GENERATED_OUTPUT_FILE}" "output_${size}.tar" | debug || error_exit "Failed to copy output file"
      info "Test Report downloaded with name output_${size}.tar"
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
  kubectl delete configmap special-config | debug || error_exit "Failed to delete configmap special-config"
  info "Destroying configmap"
  kubectl delete configmap custom-property | debug || error_exit "Failed to delete configmap custom-property"
  info "Waiting for the pod to be deleted"
  kubectl wait --for=delete "pod/$POD_NAME"
  info "Execution finished."
  exit 0
}

# Execute cleanup when CONTROL+C is invoked
trap "cleanup" INT

# Main loop
for char in "${MODE[@]}"; do
  init "$char"
  copyFileWhenTestsReady "$char"
  cleanup
done
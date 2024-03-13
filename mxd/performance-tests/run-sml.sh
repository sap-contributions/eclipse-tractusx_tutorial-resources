#!/bin/bash

# Function to display help information
function display_help {
    echo "Options:"
    echo "  -f  Set the path to file/folder with experiment files (default: \"test-configurations/small_experiment.properties\")"
    echo "  -l  Set the log message which indicates the finish of test execution (default: \"Test Completed\")"
    echo "  -p  Set the pod name (default: \"mxd-performance-test\")"
    echo "  -g  Set the generated output file path (default: \"/opt/apache-jmeter-5.5/mxd-performance-evaluation/output.tar\")"
    echo "  -s  Set the generated output_slim file path (default: \"/opt/apache-jmeter-5.5/mxd-performance-evaluation/output_slim.tar\")"
    echo "  -t  Set the Terraform directory (default: \"/Users/ciprian/IdeaProjects/tutorial-resources/mxd/\")"
    echo "  -c  Set the destination name name of experiment properties file when mounting on the pod (default: \"custom_experiment.properties\")"
    echo "  -o  Set the terraform log file name (default: \"sml_script_[current_datetime].logs\")"
    echo "  -d  Enable debug mode (default: true)"
    echo "  -x  Test pod context (cluster used to host test pod) (default: kind-mxd)"
    echo "  -y  Environment context (cluster used to host full blown MXD environment)  (default: shoot--edc-lpt--mxd)"
    exit 0
}

PROVIDED_PATH="test-configurations/small_experiment.properties"
LOG_MESSAGE="Test Completed"
POD_NAME="mxd-performance-test"
GENERATED_OUTPUT_FILE="/opt/apache-jmeter-5.5/mxd-performance-evaluation/output.tar"
GENERATED_OUTPUT_SLIM_FILE="/opt/apache-jmeter-5.5/mxd-performance-evaluation/output_slim.tar"
TERRAFORM_CHDIR="$(dirname "$0")/.."
CUSTOM_PROPERTIES="custom_experiment.properties"
LOGFILE="sml_script_$(date +%d-%m-%YT%H-%M-%S).logs"
IS_DEBUG=true
extension=".properties"
TEST_POD_CONTEXT="kind-mxd"
TEST_ENVIRONMENT_CONTEXT="shoot--edc-lpt--mxd"

# Parse command-line options
while getopts "f:l:p:g:s:t:c:o:d:x:y:" opt; do
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
        x) TEST_POD_CONTEXT=$OPTARG;;
        y) TEST_ENVIRONMENT_CONTEXT=$OPTARG;;
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
  cleanup
  exit 1
}

# Initializes the test
function init {
  local experiment_file=$1
  info "Adding ${experiment_file} on pod using custom-property configmap"

  kubectl create configmap custom-property \
    --from-file="run_experiment.sh"="mxd-performance-evaluation/run_experiment.sh" \
    --from-file="setup.jmx"="mxd-performance-evaluation/setup.jmx" \
    --from-file="measurement_interval.jmx"="mxd-performance-evaluation/measurement_interval.jmx" \
    --from-file="custom_experiment.properties"="test-configurations/small_experiment.properties" \
    --context="shoot--ciprian--test-cluster"  | debug || error_exit "Failed to create configmap with name custom-property"

  info "Init terraform"
  terraform -chdir="$TERRAFORM_CHDIR" init >> "$LOGFILE" || error_exit "Failed to initialize Terraform"
  info "Deploy Prometheus"
  kubectl create namespace monitoring --context="${TEST_ENVIRONMENT_CONTEXT}"
  kubectl apply -f prometheus --context="${TEST_ENVIRONMENT_CONTEXT}" | debug || error_exit "Failed to deploy Prometheus"
  info "Apply terraform"
  terraform -chdir="$TERRAFORM_CHDIR" apply -auto-approve  >> "$LOGFILE" || error_exit "Failed to apply Terraform"

  kubectl apply -f performance-test.yaml --context="${TEST_POD_CONTEXT}"

  info "Waiting for test pod ready state"
  kubectl wait --for=condition=ready "pod/$POD_NAME" --context="${TEST_POD_CONTEXT}"  | debug || error_exit "Test pod failed to reach ready state"
}

# Copies output file when tests are ready
function copyFileWhenTestsReady {
  local experiment_file=$1
  info "Waiting for the tests to finish ..."
  while true; do
    logs=$(kubectl logs --tail=5 "$POD_NAME" --context="${TEST_POD_CONTEXT}" 2>/dev/null)
    if echo "$logs" | grep -q "$LOG_MESSAGE"; then
      info "Log message found in the logs."
      kubectl cp --retries=-1 "${POD_NAME}:${GENERATED_OUTPUT_FILE}" "${experiment_file}.tar" --context="${TEST_POD_CONTEXT}"
      info "Test Report downloaded with name output_${experiment_file}.tar"
      kubectl cp --retries=-1 "${POD_NAME}:${GENERATED_OUTPUT_SLIM_FILE}" "${experiment_file}_slim.tar" --context="${TEST_POD_CONTEXT}"
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
  info "Destroying test pod"
  kubectl delete pod "$POD_NAME" --context="${TEST_POD_CONTEXT}" | debug || error_exit "Failed to delete test pod"
  info "Destroying configmap"
  kubectl delete configmap custom-property --context="${TEST_POD_CONTEXT}" | debug || error_exit "Failed to delete configmap custom-property"
  info "Destroying Prometheus"
  kubectl delete -f prometheus --context="${TEST_ENVIRONMENT_CONTEXT}" | debug || error_exit "Failed to delete Prometheus"
  kubectl delete namespace monitoring --context="${TEST_ENVIRONMENT_CONTEXT}"
  info "Waiting for the test pod to be deleted"
  kubectl wait --for=delete "pod/$POD_NAME" --context="${TEST_POD_CONTEXT}"
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
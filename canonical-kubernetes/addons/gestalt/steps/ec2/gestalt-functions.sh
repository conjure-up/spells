check_for_required_environment_variables() {
  retval=0

  for e in $@; do
    if [ -z "${!e}" ]; then
      echo "Required environment variable \"$e\" not defined."
      retval=1
    fi
  done

  if [ $retval -ne 0 ]; then
    echo "One or more required environment variables not defined, aborting."
    exit 1
  else
    echo "All required environment variables found."
  fi
}

check_for_required_tools() {
  echo "Checking for required tools..."

  for t in $@; do
    which $t >/dev/null 2>&1 ; echo "'$t' not found, aborting." && exit 1
    echo "OK - Required tool '$t' found."
  done
}

deploy_gestalt() {

  local pod="gestalt-cdk-install"
  local gestalt_cdk_install_image="galacticfog/gestalt-cdk-install:release-1.2.0"

  check_for_required_environment_variables \
    GESTALT_EXTERNAL_GATEWAY_DNSNAME \
    GESTALT_EXTERNAL_GATEWAY_PROTOCOL

  echo "Iniating deployment of Gestalt Platform..."

  # Get Kubeconfig data
  KUBECONFIG_DATA="$(kubectl config view --raw | base64 | tr -d '\n')"

  cat > $(scriptPath)/gestalt-cdk-install.yaml <<EOF
# This is a pod w/ restartPolicy=Never so that the installer only runs once.
apiVersion: v1
kind: Pod
metadata:
  name: $pod
  labels:
    gestalt-app: cdk-install
spec:
  restartPolicy: Never
  containers:
  - name: $pod
    image: "$gestalt_cdk_install_image"
    imagePullPolicy: Always
    # 'deploy' arg signals deployment of gestalt platform
    args: ["deploy"]
    env:
    - name: CONTAINER_IMAGE_RELEASE_TAG
      value: kube-1.0.0
    - name: EXTERNAL_GATEWAY_DNSNAME
      value: "$GESTALT_EXTERNAL_GATEWAY_DNSNAME"
    - name: EXTERNAL_GATEWAY_PROTOCOL
      value: "$GESTALT_EXTERNAL_GATEWAY_PROTOCOL"
    - name: KUBECONFIG_DATA
      value: "$KUBECONFIG_DATA"
    - name: GESTALT_INSTALL_MODE
      value: "$GESTALT_INSTALL_MODE"
EOF

  # Invoke Installer
  kubectl create -f $(scriptPath)/gestalt-cdk-install.yaml
}


wait_for_service() {
  echo "Waiting for services to start..."

  local name=$1
  local tries=100

  for i in `seq 1 $tries`; do

    response=$(
      $KUBECTL get services --all-namespaces -ojson | \
        jq ".items[] | select(.metadata.name ==\"$name\")"
    )

    if [ -z "$response" ]; then
      secs=30
      echo "Service '$name' not found yet, waiting $secs seconds... (attempt $i of $tries)"
      sleep $secs
    else
      echo "Found service '$name'."
      return 0
    fi
  done
  echo "Service '$name' didn't start, aborting."
  exit 1
}

get_service_nodeport() {

  local svc=$1
  local portName=$2

  echo "Querying for Service '$svc' NodePort named '$portName'..."

  local svcdef=$( $KUBECTL get services --all-namespaces -ojson | \
    jq " .items[] | select(.metadata.name ==\"$svc\")" )

  [ -z "$svcdef" ] && echo "Service '$svc' not found, aborting." && exit 1

  local nodeport=$(
    echo "$svcdef" | jq ".spec.ports[] | select(.name==\"$portName\" ) | .nodePort"
  )
  [ -z "$nodeport" ] && echo "Service '$svc' NodePort not found, aborting." && exit 1

  echo "Service '$svc' NodePort found: $nodeport"

  SERVICE_NODEPORT=$nodeport

  echo "Done."
}

run() {
  SECONDS=0
  echo "[Running '$@']"

  # Run function
  $@

  echo "['$@' finished in $SECONDS seconds]"
  echo ""
}

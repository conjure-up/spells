#!/bin/bash
# Addon Installer for Galactic Fog Gestalt Platfor on top of CDK and Ceph
# for Storage.

set -eux
. $CONJURE_UP_SPELLSDIR/sdk/common.sh
. "$(dirname "$0")/gestalt-functions.sh"
. "$(dirname "$0")/gestalt-aws-functions.sh"
. "$(dirname "$0")/deploy-config.rc"

precheck
run get_kubeconfig
run check_kube_cluster
run predeploy
run deploy_gestalt
run postdeploy

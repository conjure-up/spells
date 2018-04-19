#!/bin/bash

set -eux

. "$CONJURE_UP_SPELLSDIR/sdk/common.sh"

function re_install_helm() {

    PATH="$PATH:$HOME/bin"
    KUBECTL=$(getKey "kubectl.dest")

    echo "Forcing reinstall of Helm .."
    if [[ $(uname -s) = "Darwin" ]]; then
        platform="darwin"
    else
        platform="linux"
    fi
    helm_repo="https://storage.googleapis.com/kubernetes-helm"
    helm_file="helm-$HELM_VERSION-$platform-amd64.tar.gz"

    work_dir="$(mktemp -d)"
    rm -f "$HOME/bin/helm" "$HOME/bin/.helm"  # clear potentially different version
    mkdir -p "$HOME/bin"

    echo "Installing Helm CLI"
    curl -fsSL -o "$work_dir/$helm_file" "$helm_repo/$helm_file"
    tar -C "$work_dir" -zxvf "$work_dir/$helm_file" 1>&2
    mv "$work_dir/$platform-amd64/helm" "$HOME/bin/helm"
    chmod +x "$HOME/bin/helm"

    # --wait is introduced in helm version v2.8.0
    #    $HOME/bin/helm init --wait
    # But helm init --wait gives "context limit exceeded " error
    # THe problem is fixed in in v2.8.2
    # The while loop can be replaced with a  helm init --wait and the tiller will
    # also be ready. Till we certify with helm v2.8.2, we will use the current logic

    echo "Waiting for helm to finish initialization ..."

    init_count=1
    while ! helm init --upgrade; do
        if [[ "$init_count" -gt 30 ]]; then
            echo "Helm is not yet ready...Please check with your system Administrator"
            exit 1
        fi
        echo "Still waiting for helm initialization, init_count=$init_count"
        ((init_count=init_count+1))
        sleep 30
    done

    echo "Waiting for tiller pods"
    wait_count=1

    while ! "$KUBECTL" -n kube-system get po | grep -q 'tiller.*Running'; do
        if [[ "$wait_count" -gt 120 ]]; then
            echo "Tiller pods not ready"
            exit 1
        fi
        echo "Waiting for tiller pods ($wait_count/120)"
        ((wait_count=wait_count+1))
        sleep 30
    done
    echo "Tiller pods running"

    rm -rf "$work_dir"

    # Successful helm -init --upgrade does not guarantee that tiller pod
    # is ready
    setKey "helm.installed.$CONJURE_UP_SESSION_ID" true
    echo "Helm ReInstall Done. "

}

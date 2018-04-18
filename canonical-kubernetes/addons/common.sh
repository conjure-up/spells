#!/bin/bash

set -eux

. "$CONJURE_UP_SPELLSDIR/sdk/common.sh"

function install_helm() {
    PATH="$PATH:$HOME/bin"

    if [[ $(uname -s) = "Darwin" ]]; then
        platform="darwin"
    else
        platform="linux"
    fi
    helm_repo="https://storage.googleapis.com/kubernetes-helm"
    helm_file="helm-$HELM_VERSION-$platform-amd64.tar.gz"

    # only install and init Helm once per deployment
    if [[ "$(getKey "helm.installed.$CONJURE_UP_SESSION_ID")" != "true" ]]; then
        work_dir="$(mktemp -d)"

        rm -f "$HOME/bin/helm" "$HOME/bin/.helm"  # clear potentially different version
        mkdir -p "$HOME/bin"

        echo "Installing Helm CLI"
        curl -fsSL -o "$work_dir/$helm_file" "$helm_repo/$helm_file"
        tar -C "$work_dir" -zxvf "$work_dir/$helm_file" 1>&2
        mv "$work_dir/$platform-amd64/helm" "$HOME/bin/helm"

        echo "Deploying and initializing Helm"
        init_count=1
        while ! helm init --upgrade; do
            if [[ "$init_count" -gt 5 ]]; then
                echo "Helm init failed"
                exit 1
            fi
            echo "Deploying and initializing Helm ($init_count/5)"
            ((init_count=init_count+1))
            sleep 5
        done

        echo "Waiting for tiller pods"
        wait_count=1
        while ! kubectl -n kube-system get po | grep -q 'tiller.*Running'; do
            if [[ "$wait_count" -gt 10 ]]; then
                echo "Tiller pods not ready"
                exit 1
            fi
            echo "Waiting for tiller pods ($wait_count/10)"
            ((wait_count=wait_count+1))
            sleep 30
        done
        echo "Tiller pods running"

        rm -rf "$work_dir"

        setKey "helm.installed.$CONJURE_UP_SESSION_ID" true
    fi
}

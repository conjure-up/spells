#!/bin/bash

set -eux

. "$CONJURE_UP_SPELLSDIR/sdk/common.sh"

function install_helm() {
    if [[ $(uname -s) = "Darwin" ]]; then
        platform="darwin"
    else
        platform="linux"
    fi
    helm_repo="https://storage.googleapis.com/kubernetes-helm"
    helm_file="helm-$HELM_VERSION-$platform-amd64.tar.gz"

    if [[ "$(getKey "helm.installed.$CONJURE_UP_SESSION_ID")" != "true" ]]; then
        work_dir="$(mktemp -d)"

        rm -f "$HOME/bin/helm" "$HOME/bin/.helm"  # clear potentially different version

        echo "Installing Helm CLI"
        curl -fsSL -o "$work_dir/$helm_file" "$helm_repo/$helm_file"
        tar -C "$work_dir" -zxvf "$work_dir/$helm_file"
        mv "$work_dir/$platform-amd64/helm" "$HOME/bin/.helm"
        chmod +x "$HOME/bin/.helm"
        cp "$CONJURE_UP_SPELLSDIR/$CONJURE_UP_SPELL/addons/helm/helm-wrapper.sh" "$HOME/bin/helm"
        chmod +x "$HOME/bin/helm"

        init_count=0
        while ! helm init --upgrade; do
            if [[ "$init_count" -gt 5 ]]; then
                break
            fi
            ((init_count=init_count+1))
            sleep 5
        done

        rm -rf "$work_dir"

        setKey "helm.installed.$CONJURE_UP_SESSION_ID" true
    fi
    # always update the default config to the latest install
    echo "$HOME/.kube/config.$JUJU_MODEL" > "$HOME/.kube/config.conjure-up.default"
}

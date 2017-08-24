#!/bin/bash

set -eux

. "$CONJURE_UP_SPELLSDIR/sdk/common.sh"

function install_helm() {
    if [[ "$(getKey helm.installed)" != "true" ]]; then
        WORK_DIR="$(mktemp -d)"

        echo "Installing Helm CLI"
        curl -fsSL -o "$WORK_DIR/helm-stable.tar.gz" "https://storage.googleapis.com/kubernetes-helm/helm-$HELM_VERSION-linux-amd64.tar.gz"
        tar -C "$WORK_DIR" -zxvf "$WORK_DIR/helm-stable.tar.gz"
        mv "$WORK_DIR/linux-amd64/helm" "$HOME/bin/.helm"
        chmod +x "$HOME/bin/.helm"
        mv "$CONJURE_UP_SPELLSDIR/$CONJURE_UP_SPELL/helm-wrapper.sh" "$HOME/bin/helm"
        chmod +x "$HOME/bin/helm"

        init_count=0
        while ! helm init --upgrade; do
            if [[ "$init_count" -gt 5 ]]; then
                break
            fi
            ((init_count=init_count+1))
            sleep 5
        done

        rm -rf "$WORK_DIR"

        setKey helm.installed true
    fi
    # always update the default config to the latest install
    echo "$HOME/.kube/config.$JUJU_MODEL" > "$HOME/.kube/config.conjure-up.default"
}

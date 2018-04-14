#!/bin/bash

set -eux

. "$CONJURE_UP_SPELLSDIR/sdk/common.sh"

function re_install_helm() {

	echo "Forcing reinstall of Helm .."
	WORK_DIR="$(mktemp -d)"

	echo "Force Re-Installing Helm CLI"
	curl -fsSL -o "$WORK_DIR/helm-stable.tar.gz" "https://storage.googleapis.com/kubernetes-helm/helm-$HELM_VERSION-linux-amd64.tar.gz"
	tar -C "$WORK_DIR" -zxvf "$WORK_DIR/helm-stable.tar.gz"
	rm -rf $HOME/bin/.helm
	rm -f $HOME/bin/helm
	mv "$WORK_DIR/linux-amd64/helm" "$HOME/bin/.helm"
	chmod +x "$HOME/bin/.helm"
	cp "$CONJURE_UP_SPELLSDIR/$CONJURE_UP_SPELL/addons/helm/helm-wrapper.sh" "$HOME/bin/helm"
	chmod +x "$HOME/bin/helm"

	rm -rf "$WORK_DIR"

	# --wait is introduced in helm version v2.8.0 
	#	$HOME/bin/helm init --wait
	# But helm init --wait gives "context limit exceeded " error
	# Once the wait problem is fixed (likely in v2.8.2)
	# The while loop can be replaced with a  helm init --wait followed by
	# helm init --upgrade


	echo "Waiting for helm to finish initialization ..."
	sleep 120
	init_count=1
	while ! $HOME/bin/helm init --upgrade; do
		echo "Waiting for tiller pod, init_count=$init_count"
		if [[ "$init_count" -gt 120 ]]; then
			echo "Helm is not yet ready...Please check with your system Administrator"
			break
		fi
		((init_count=init_count+1))
		sleep 10
	done


	# Successful helm -init --upgrade does not gaurantee that tiller pod
	# is ready
        setKey helm.installed true
        # always update the default config to the latest install
        echo "$HOME/.kube/config.$JUJU_MODEL" > "$HOME/.kube/config.conjure-up.default"
        echo "Helm ReInstall Done. "

}

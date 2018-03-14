#!/bin/bash

export KUBECONFIG="${KUBECONFIG:-$(cat "$HOME/.kube/config.conjure-up.default")}"
"$HOME/bin/.helm" "$@"

#!/bin/bash
set -x
cache="192.168.122.11"
echo conjure-up --apt-proxy http://${cache}:3142 --apt-https-proxy http://${cache}:3142 $(dirname $0) localhost

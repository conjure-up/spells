#!/bin/bash
set -x
conjure-up --apt-proxy http://$(hostname):3142 --apt-https-proxy http://$(hostname):3142 $(dirname $0) localhost

#!/bin/bash
set -x
conjure-up --apt-proxy http://ubuntu:3142 --apt-https-proxy http://ubuntu:3142 .

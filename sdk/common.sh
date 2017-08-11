#!/bin/bash
# loggers
#
# Arguments:
# $1: logger name, ie. openstack, bigdata
# $@: rest of log message
debug() {
    name=$CONJURE_UP_SPELL
    logger -t "conjure-up/$name" "[DEBUG] ($JUJU_CONTROLLER:$JUJU_MODEL)" "$@"
}

info() {
    name=$CONJURE_UP_SPELL
    logger -t "conjure-up/$name" "[INFO] ($JUJU_CONTROLLER:$JUJU_MODEL)" "$@"
}

log() {
    if [[ $- == *i* ]]; then
        printf "\e[32m\e[1m[info]\e[0m %s\n" "$@"
    else
        printf "[info] %s\n" "$@"
    fi
}

testLog() {
    if [[ $- == *i* ]];then
        printf "\e[33m\e[1m[test]\e[0m %s\n" "$@"
    else
        printf "[test] %s\n" "$@"
    fi
}

# Gets current juju state for machine
#
# Arguments:
# $1: service name
#
# Returns:
# machine status
agentState()
{
    juju status -m "$JUJU_CONTROLLER:$JUJU_MODEL" --format json | jq ".machines[\"$1\"][\"juju-status\"][\"current\"]"
}

# Gets current workload state for service
#
# Arguments:
# $1: service name
# $2: unit number
#
# Returns:
# unit status
agentStateUnit()
{
    juju status -m "$JUJU_CONTROLLER:$JUJU_MODEL" --format json | jq ".applications[\"$1\"][\"units\"][\"$1/$2\"][\"workload-status\"][\"current\"]"
}

# Gets current leader of a service
#
# Arguments:
# $1: service name
#
# Returns:
# unit leader
getLeader()
{
    py_script="
import sys
import yaml

leader_yaml=yaml.load(sys.stdin)
for leader in leader_yaml:
    if leader['Stdout'].strip() == 'True':
        print(leader['UnitId'])
"

    juju run -m "$JUJU_CONTROLLER:$JUJU_MODEL" --application "$1" is-leader --format yaml | env python3 -c "$py_script"
}

# Exports the variables required for communicating with your cloud.
#
# Arguments:
# $1: username
# $2: password
# $3: tenant name
# $4: keystone auth url
# $5: region name
configOpenrc()
{
    export OS_USERNAME=$1
    export OS_PASSWORD=$2
    export OS_TENANT_NAME=$3
    export OS_AUTH_URL=$4
    export OS_REGION_NAME=$5
}

# Get public address of unit
#
# Arguments:
# $1: service
#
# Returns:
# IP Address of unit
unitAddress()
{
    py_script="
import sys
import yaml

status_yaml=yaml.load(sys.stdin)
unit = status_yaml['applications']['$1']['units']
units = list(unit.keys())
print(unit[units[0]]['public-address'])
"
    juju status -m "$JUJU_CONTROLLER:$JUJU_MODEL" "$1" --format yaml | env python3 -c "$py_script"
}

# Get workload status of unit
#
# Arguments:
# $1: service
# $2: unit number
#
# Returns:
# String of status
unitStatus()
{
    juju status -m "$JUJU_CONTROLLER:$JUJU_MODEL" --format json | jq -r ".applications[\"$1\"][\"units\"][\"$1/$2\"][\"workload-status\"][\"current\"]"
}

# Get juju status of unit
#
# Arguments:
# $1: service
# $2: unit number
#
# Returns:
# String of status
unitJujuStatus()
{
    juju status -m "$JUJU_CONTROLLER:$JUJU_MODEL" --format json | jq -r ".applications[\"$1\"][\"units\"][\"$1/$2\"][\"juju-status\"][\"current\"]"
}


# Get machine for unit, ie 0/lxc/1
#
# Arguments:
# 1: service
# 2: unit number
#
# Returns:
# machine identifier
unitMachine()
{
    juju status -m "$JUJU_CONTROLLER:$JUJU_MODEL" --format json | jq -r ".applications[\"$1\"][\"units\"][\"$1/$2\"][\"machine\"]"
}

# Safely expands tilde paths
#
# Arguments:
# $1: tilde like path ~/test/moo.sh
expandPath() {
  case $1 in
    ~[+-]*)
      local content content_q
      printf -v content_q '%q' "${1:2}"
      eval "content=${1:0:2}${content_q}"
      printf '%s\n' "$content"
      ;;
    ~*)
      local content content_q
      printf -v content_q '%q' "${1:1}"
      eval "content=~${content_q}"
      printf '%s\n' "$content"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

# Grabs current directory housing script ($0)
#
# Arguments:
# $0: current script
scriptPath() {
    env python3 -c "import os,sys; print(os.path.dirname(os.path.abspath(\"$0\")))"
}

# call the right redis-cli (mainly to ease dev testing)
#
# All arguments will be passed through to redis-cli
redis-cli() {
    local conjure_redis_cli
    local system_redis_cli
    local cli

    conjure_redis_cli=$(which conjure-up.redis-cli || true)
    system_redis_cli=$(which redis-cli || true)

    if [ "$conjure_redis_cli" = "/snap/bin/conjure-up.redis-cli" ]; then
       cli="$conjure_redis_cli"
    else
        cli="$system_redis_cli"
    fi
    "$cli" "$@"
}

# sets a redis namespace result for a step
#
# Arguments:
# $1: result message
setResult()
{
    redis-cli set "conjure-up.$CONJURE_UP_SPELL.$CONJURE_UP_STEP.result" "$1"
}

# autoincrements a file as to not overwrite existing ones
#
# Arguments:
# $1: path to file
autoincrFile()
{
    name="$1"
    if [[ -e "$name" ]] ; then
        i=0
        while [[ -e "$name-$i" ]] ; do
            let i++
        done
        printf "$name-$i"
    fi
}

# uuidgen printing first 3 characters
genHash()
{
    local sha
    sha=$(uuidgen | cut -d- -f1)
    printf "${sha:0:3}"
}

#!/bin/bash

: "${CLOUD:=nocloud}"
: "${JUJU_CONTROLLER:=nocloud}"
: "${JUJU_MODEL:=nocloud}"
: "${JUJU_PROVIDERTYPE:=nocloud}"

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

# Gets list of units of an application
#
# Arguments:
# $1: application name
#
# Returns:
# list of units
applicationUnits()
{
    juju status --format=json | jq ".applications[\"$1\"].units | keys | .[]" | sed 's/"//g'
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

# Waits for machine to start
#
# Arguments:
# machine: machine number
waitForMachine()
{
    for machine; do
        while [ "$(agentState $machine)" != started ]; do
            sleep 5
        done
    done
}

# Waits for service to start
#
# Arguments:
# service: service name
waitForService()
{

    for service; do
        while [ "$(agentStateUnit "$service" 0)" != active ]; do
            sleep 5
        done
    done
}

# Parses result into json output
#
# Arguments:
# $1: return message
# $2: return code
# $3: true/false
exposeResult()
{
    printf '{"message": "%s", "returnCode": %d, "isComplete": %s}' "$1" "$2" "$3"
    exit 0
}

# Checks an array of applications for an error flag
#
# Arguments:
# $1: array of applications
checkUnitsForErrors() {
    applications=$1
    for i in "${applications[@]}"
    do
        if [ $(unitStatus "$i" 0) = "error" ]; then
            debug "$i, gave a charm error."
            exposeResult "Error with $i, please check juju status" 1 "false"
        fi
    done
}

# Checks an array of applications for an active flag
#
# Arguments:
# $1: array of applications
checkUnitsForActive() {
    applications=$1
    for i in "${applications[@]}"
    do
        debug "Checking agent state of $i: $(unitStatus $i 0)"
        if [ $(unitStatus "$i" 0) != "active" ]; then
            exposeResult "$i not quite ready yet" 0 "false"
        fi
    done
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

# sets the result for the current spell, step, and phase
#
# Arguments:
# $1: result message
setResult()
{
    setStepKey "$CONJURE_UP_PHASE.result" "$1"
}

# sets a state key/value namespaced to the current step
#
# Arguments:
# $1: KEY
# $2: VALUE
setStepKey()
{
  setKey "$CONJURE_UP_STEP.$1" "$2"
}

# gets a state key/value namespaced to the current step
#
# Arguments:
# $1: KEY
getStepKey()
{
    getKey "$CONJURE_UP_STEP.$1"
}

# sets a state key/value namespaced to the current spell
#
# Arguments:
# $1: KEY
# $2: VALUE
setKey()
{
    kv-cli "$KV_DB" set "conjure-up.$CONJURE_UP_SPELL.$1" "$2"
}

# gets a state key/value namespaced by the current spell
#
# Arguments:
# $1: KEY
getKey()
{
    kv-cli "$KV_DB" get "conjure-up.$CONJURE_UP_SPELL.$1" || echo "None"
}

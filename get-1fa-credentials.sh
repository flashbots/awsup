#!/usr/bin/env bash

set -e -o pipefail

# Log the attempt
TS=$( date +'%Y-%m-%dT%H:%M:%S%z' )
PID=$$
ARG=$( ps -ww -o args= -p "${PID}" )
PARG=$( ps -ww -o args= -p "${PPID}" )
PPPID=$( ps -o ppid= -p "${PPID}" )
PPARG=$( ps -ww -o args= -p "${PPPID}" )
PPPPID=$( ps -o ppid= -p "${PPPID}" )
PPPARG=$( ps -ww -o args= -p "${PPPPID}" )
printf '{ "ts": "%s", "grandgrandparent": { "pid": %s, "command": "%s" }, "grandparent": { "pid": %s, "command": "%s" }, "parent": { "pid": %s, "command": "%s" }, "self": { "pid": %s, "command": "%s" } }\n' \
    "${TS}" \
    "${PPPPID}" "${PPPARG}" \
    "${PPPID}" "${PPARG}" \
    "${PPID}" "${PARG}" \
    "${PID}" "${ARG}" \
  >> "${HOME}/.aws/get-1fa-credentials.log"

pwd=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. "${pwd}/lib.sh"

get_1fa_token

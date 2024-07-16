#!/usr/bin/env bash

set -e -o pipefail

pwd=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "${pwd}/lib.sh"

AWS_SESSION_TOKEN=$( get_2fa_token )
EXPIRATION=$( printf "%s" "${AWS_SESSION_TOKEN}" | jq -r ".Expiration" )
NOW=$( date -u +"%Y-%m-%dT%H:%M:%S%z" )

if [[ -n "${DEBUG}" ]]; then
  echo "AWS_SESSION_TOKEN: ${AWS_SESSION_TOKEN}" >> "${HOME}/.aws/debug.log"
  echo "EXPIRATION: ${EXPIRATION}" >> "${HOME}/.aws/debug.log"
  echo "NOW: ${NOW}" >> "${HOME}/.aws/debug.log"
fi

# Log the attempt
PID=$$
ARG=$( ps -ww -o args= -p "${PID}" )
PARG=$( ps -ww -o args= -p "${PPID}" | tr '"' '\"' )
PPPID=$( ps -o ppid= -p "${PPID}" )
PPARG=$( ps -ww -o args= -p "${PPPID}" | tr '"' '\"' )
PPPPID=$( ps -o ppid= -p "${PPPID}" )
PPPARG=$( ps -ww -o args= -p "${PPPPID}" | tr '"' '\"' )
printf '{ "ts": "%s", "expiration": "%s", "grandgrandparent": { "pid": %s, "command": "%s" }, "grandparent": { "pid": %s, "command": "%s" }, "parent": { "pid": %s, "command": "%s" }, "self": { "pid": %s, "command": "%s" } }\n' \
    "${NOW}" \
    "${EXPIRATION}" \
    "${PPPPID}" "${PPPARG}" \
    "${PPPID}" "${PPARG}" \
    "${PPID}" "${PARG}" \
    "${PID}" "${ARG}" \
  >> "${HOME}/.aws/get-2fa-credentials.log"

if [[ "${NOW}" > "${EXPIRATION}" ]]; then
  if [[ -n "${DEBUG}" ]]; then
    echo "Logging in..." >> "${HOME}/.aws/debug.log"
  fi

  "${pwd}/helper.sh" --login
  AWS_SESSION_TOKEN=$( get_2fa_token )
fi

printf "%s" "${AWS_SESSION_TOKEN}"

#!/usr/bin/env bash

set -e -o pipefail

# Log the login attempt
TS=$( date +'%Y-%m-%dT%H:%M:%S%z' )
PID=$$
ARG=$( ps -ww -o args= -p $PID )
PARG=$( ps -ww -o args= -p $PPID )
PPPID=$( ps -o ppid= -p $PPID )
PPARG=$( ps -ww -o args= -p $PPPID )
PPPPID=$( ps -o ppid= -p $PPPID )
PPPARG=$( ps -ww -o args= -p $PPPPID )
printf '{ "ts": "%s", "grandgrandparent": { "pid": %s, "command": "%s" }, "grandparent": { "pid": %s, "command": "%s" }, "parent": { "pid": %s, "command": "%s" }, "self": { "pid": %s, "command": "%s" } }\n' \
    "${TS}" \
    "${PPPPID}" "${PPPARG}" \
    "${PPPID}" "${PPARG}" \
    "${PPID}" "${PARG}" \
    "${PID}" "${ARG}" \
  >> ${HOME}/.aws/login.log

. ${HOME}/.aws/lib.sh

set_lock

if [[ -z "$1" ]]; then
  echo "🚫 No argument provided."
  get_help_message
  delete_lock
else
  case "$1" in
  --custom-config|-c)
      if [[ -z "$2" ]]; then
        echo "🚫 Usage: --custom-config <url_or_path>"
        delete_lock
      else
        save_custom_config "$2"
        delete_lock
      fi
      ;;
  --delete-lock|-d)
      delete_lock
      ;;
  --help|-h)
      get_help_message
      delete_lock
      ;;
  --login|-l)
      save_2fa_token $( request_2fa_token )
      delete_lock
      ;;
  --setup|-s)
      save_setup
      delete_lock
      ;;
  *)
      echo "🚫 Argument not supported: $1"
      delete_lock
      ;;
  esac
fi

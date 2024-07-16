AWS_HELPER_PROFILE="${HOME}/.profile"

function get_1fa_token() {
  case "${AWS_HELPER_VAULT_ENGINE}" in
    osxkeychain)
      get_1fa_token_osxkeychain
      ;;
    file)
      get_1fa_token_file
      ;;
    *)
      echo "🚫 Invalid vault engine: ${AWS_HELPER_VAULT_ENGINE}" >&2
      exit 1
      ;;
  esac
}

function get_1fa_token_osxkeychain() {
  security find-generic-password \
    -l "${AWS_HELPER_USER_ARN}" \
    -a "${AWS_HELPER_USER_ARN}" \
    -s "${AWS_HELPER_USER_ARN}" \
    -w
}

function get_1fa_token_file() {
  cat "${HOME}/.aws/1fa_token" | jq -r ".\"${AWS_HELPER_USER_ARN}\""
}

function get_2fa_token() {
  case "${AWS_HELPER_VAULT_ENGINE}" in
    osxkeychain)
      get_2fa_token_osxkeychain
      ;;
    file)
      get_2fa_token_file
      ;;
    *)
      echo "🚫 Invalid vault engine: ${AWS_HELPER_VAULT_ENGINE}" >&2
      exit 1
      ;;
  esac
}

function get_2fa_token_osxkeychain() {
  security find-generic-password \
    -l "${AWS_HELPER_MFA_DEVICE_ARN}" \
    -a "${AWS_HELPER_MFA_DEVICE_ARN}" \
    -s "${AWS_HELPER_MFA_DEVICE_ARN}" \
    -w
}

function get_2fa_token_file() {
  cat "${HOME}/.aws/2fa_token" | jq -r ".\"${AWS_HELPER_MFA_DEVICE_ARN}\""
}

function save_1fa_token() {
  if [[ -n "${DEBUG}" ]]; then
    echo "New AWS_HELPER_CREDENTIALS" >> "${HOME}/.aws/debug.log"
  fi

  case "${AWS_HELPER_VAULT_ENGINE}" in
    osxkeychain)
      save_1fa_token_osxkeychain "$1" "$2"
      ;;
    file)
      save_1fa_token_file "$1" "$2"
      ;;
    *)
      echo "🚫 Invalid vault engine: ${AWS_HELPER_VAULT_ENGINE}" >&2
      exit 1
      ;;
  esac
}

function save_1fa_token_osxkeychain() {
  local AWS_HELPER_USER_ARN="$1"
  local AWS_HELPER_CREDENTIALS="$2"

  security delete-generic-password \
      -l "${AWS_HELPER_USER_ARN}" \
      -a "${AWS_HELPER_USER_ARN}" \
      -s "${AWS_HELPER_USER_ARN}" \
    > /dev/null 2>&1 || true

  security add-generic-password \
      -l "${AWS_HELPER_USER_ARN}" \
      -a "${AWS_HELPER_USER_ARN}" \
      -s "${AWS_HELPER_USER_ARN}" \
      -w "${AWS_HELPER_CREDENTIALS}" \
    > /dev/null 2>&1 || true
}

function save_1fa_token_file() {
  local AWS_HELPER_USER_ARN="$1"
  local AWS_HELPER_CREDENTIALS="$2"

  echo "{\"${AWS_HELPER_USER_ARN}\": ${AWS_HELPER_CREDENTIALS}}" > "${HOME}/.aws/1fa_token"
}

function save_2fa_token() {
  if [[ -n "${DEBUG}" ]]; then
    echo "New AWS_HELPER_SESSION_TOKEN: $1" >> "${HOME}/.aws/debug.log"
  fi

  case "${AWS_HELPER_VAULT_ENGINE}" in
    osxkeychain)
      save_2fa_token_osxkeychain "$1"
      ;;
    file)
      save_2fa_token_file "$1"
      ;;
    *)
      echo "🚫 Invalid vault engine: ${AWS_HELPER_VAULT_ENGINE}" >&2
      exit 1
      ;;
  esac
}

function save_2fa_token_osxkeychain() {
  local AWS_HELPER_SESSION_TOKEN="$1"

  if [[ -z "${DEBUG}" ]]; then
    security delete-generic-password \
        -l "${AWS_HELPER_MFA_DEVICE_ARN}" \
        -a "${AWS_HELPER_MFA_DEVICE_ARN}" \
        -s "${AWS_HELPER_MFA_DEVICE_ARN}" \
      > /dev/null 2>&1 || true

    security add-generic-password \
        -l "${AWS_HELPER_MFA_DEVICE_ARN}" \
        -a "${AWS_HELPER_MFA_DEVICE_ARN}" \
        -s "${AWS_HELPER_MFA_DEVICE_ARN}" \
        -w "${AWS_HELPER_SESSION_TOKEN}" \
      > /dev/null 2>&1 || true
  else
    security delete-generic-password \
        -l "${AWS_HELPER_MFA_DEVICE_ARN}" \
        -a "${AWS_HELPER_MFA_DEVICE_ARN}" \
        -s "${AWS_HELPER_MFA_DEVICE_ARN}" \
      >> "${HOME}/.aws/debug.log" 2>&1 || true

    security add-generic-password \
        -l "${AWS_HELPER_MFA_DEVICE_ARN}" \
        -a "${AWS_HELPER_MFA_DEVICE_ARN}" \
        -s "${AWS_HELPER_MFA_DEVICE_ARN}" \
        -w "${AWS_HELPER_SESSION_TOKEN}" \
      >> "${HOME}/.aws/debug.log"
    fi
}

function save_2fa_token_file() {
  local AWS_HELPER_SESSION_TOKEN="$1"
  echo "{\"${AWS_HELPER_MFA_DEVICE_ARN}\": ${AWS_HELPER_SESSION_TOKEN}}" > "${HOME}/.aws/2fa_token"
}

function get_2fa_otp_manual() {
  local PIN
  while true; do
    PIN="$( get_prompt_private_string "🔑 Enter one-time password for \`${AWS_HELPER_MFA_DEVICE_ARN}\`:" )"
    if [[ "${PIN}" =~ ^[0-9]{6}$ ]]; then
      break
    else
      printf "%s " "🚫 Invalid input. Please enter a 6-digit number." >/dev/tty
      printf "\n" >/dev/tty
    fi
  done
  printf "%s" "${PIN}"
}

function request_2fa_token() {
  local PIN

  echo "🔄 Logging into AWS..." >&2

  # Check if Yubikey or 1password are available
  if ykman=$( which ykman ); then
    if [ -z "$( $ykman list )" ]; then
      echo "🔑 Please insert your yubikey and hit <ENTER>..." >&2
      read
    fi
    PIN=$( $ykman oath accounts code --single ${AWS_HELPER_MFA_DEVICE_ARN} )
  elif op=$(which op); then
    if [ -n "${AWS_HELPER_OP_ITEM}" ]; then
      PIN=$( $op item get ${AWS_HELPER_OP_ITEM} --otp )
    fi
  else
    PIN=$( get_2fa_otp_manual )
  fi

  echo "🔄 Requesting session token from AWS API..." >&2

  if ! AWS_HELPER_SESSION_TOKEN=$( aws \
        --profile 1fa \
      sts get-session-token \
        --serial-number "${AWS_HELPER_MFA_DEVICE_ARN}" \
        --duration-seconds 3600 \
        --token-code "${PIN}" \
    | jq -r -c ".Credentials + { \"Version\": 1 }"
  ); then
    echo "🚫 Failed to retrieve AWS session token" >&2
    exit 1
  fi

  echo "✅ Done." >&2

  printf "${AWS_HELPER_SESSION_TOKEN}"
}

function save_custom_config() {
  local AWS_CONFIG_SOURCE="$1"
  local AWS_CONFIG_DEST="${HOME}/.aws/config"

  if [[ -f "${AWS_CONFIG_SOURCE}" ]]; then
    cp "${AWS_CONFIG_SOURCE}" "${AWS_CONFIG_DEST}"
  elif [[ "${AWS_CONFIG_SOURCE}" =~ ^http ]]; then
    if command -v curl >/dev/null 2>&1; then
      curl -sL -o "${AWS_CONFIG_DEST}" "${AWS_CONFIG_SOURCE}"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "${AWS_CONFIG_DEST}" "${AWS_CONFIG_SOURCE}"
    else
        echo "🚫 Neither curl nor wget are available. Please install one of these and try again."
        exit 1
    fi
  else
    echo "🚫 Invalid config source: ${AWS_CONFIG_SOURCE}" >&2
    exit 1
  fi
}

function get_prompt_string() {
  printf "%s " "🔑 $1" >/dev/tty
  read -r CHOICE </dev/tty
  printf "%s" "${CHOICE}"
}

function get_prompt_private_string() {
    local prompt="$1"
    printf "%s" "🔑 $prompt" >/dev/tty
    read -rs CHOICE </dev/tty
    printf "\n" >/dev/tty
    printf "%s" "${CHOICE}"
}

function get_prompt_bool() {
  printf "%s " "🔑 $1 [y/N]" >/dev/tty
  read -r CHOICE </dev/tty
  case "${CHOICE}" in
    y|Y ) return 0;;
    * ) return 1;;
  esac
}

function set_profile_env() {
  local KEY="$1"
  local VALUE="$2"

  if grep -q "^export ${KEY}=" "${AWS_HELPER_PROFILE}"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s|^export ${KEY}=.*|export ${KEY}=${VALUE}|" "${AWS_HELPER_PROFILE}"
    else
      sed -i "s|^export ${KEY}=.*|export ${KEY}=${VALUE}|" "${AWS_HELPER_PROFILE}"
    fi
  else
    echo "export ${KEY}=${VALUE}" >> "$AWS_HELPER_PROFILE"
  fi
}

function save_setup() {
  local SETUP_AWS_HELPER_ACCOUNT_ID="$( get_prompt_string "Enter your AWS account ID:" )"
  local SETUP_AWS_HELPER_IAM_USERNAME="$( get_prompt_string "Enter your IAM username:" )"
  local SETUP_AWS_HELPER_USER_ARN="arn:aws:iam::${SETUP_AWS_HELPER_ACCOUNT_ID}:user/${SETUP_AWS_HELPER_IAM_USERNAME}"
  set_profile_env "AWS_HELPER_USER_ARN" "${SETUP_AWS_HELPER_USER_ARN}"

  local SETUP_AWS_HELPER_MFA_DEVICE_NAME="$( get_prompt_string "Enter the name of your AWS MFA device:" )"
  local SETUP_AWS_HELPER_MFA_DEVICE_ARN="arn:aws:iam::${SETUP_AWS_HELPER_ACCOUNT_ID}:mfa/${SETUP_AWS_HELPER_MFA_DEVICE_NAME}"
  set_profile_env "AWS_HELPER_MFA_DEVICE_ARN" "${SETUP_AWS_HELPER_MFA_DEVICE_ARN}"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    set_profile_env "AWS_HELPER_VAULT_ENGINE" "osxkeychain"
  else
    set_profile_env "AWS_HELPER_VAULT_ENGINE" "file"
  fi

  if get_prompt_bool "Do you use 1password client for 2fa?"; then
    local SETUP_AWS_HELPER_OP_ITEM="$( get_prompt_string "Enter the name or ID of your 1password item:" )"
    set_profile_env "AWS_HELPER_OP_ITEM" "${SETUP_AWS_HELPER_OP_ITEM}"
  fi

  if get_prompt_bool "Do you want to add a custom aws config file?"; then
    local SETUP_CUSTOM_CONFIG="$( get_prompt_string "Enter the path or URL to the custom config file:" )"
    save_custom_config "${SETUP_CUSTOM_CONFIG}"
  fi

  local SETUP_AWS_ACCESS_KEY_ID="$( get_prompt_private_string "Enter your AWS access key ID:" )"
  local SETUP_AWS_SECRET_ACCESS_KEY="$( get_prompt_private_string "Enter your AWS secret access key:" )"
  local SETUP_AWS_HELPER_CREDENTIALS="{\"Version\":1,\"AccessKeyId\":\"${SETUP_AWS_ACCESS_KEY_ID}\",\"SecretAccessKey\":\"${SETUP_AWS_SECRET_ACCESS_KEY}\"}"

  save_1fa_token "${SETUP_AWS_HELPER_USER_ARN}" "${SETUP_AWS_HELPER_CREDENTIALS}"
  save_2fa_token $( request_2fa_token )

  echo "✅ Setup complete! To validate, run:"
  echo "✨    aws sts get-caller-identity"
}

function set_lock() {
  if [[ -f "${HOME}/.aws/login.lock" ]]; then
    if [[ -t 0 ]]; then
      >&2 echo "🚫 Warning: another login attempt might be ongoing in parallel!"
    else
      exit 1
    fi
  fi

  touch "${HOME}/.aws/login.lock"
}

function delete_lock() {
  rm -f "${HOME}/.aws/login.lock"
}

function get_help_message() {
  local HELP_MESSAGE=<<EOF
        CLI for aws-cli-helper.

        Usage:

            ~/.aws/helper.sh [options]

        Options:

            --custom-config <url_or_path>  Save custom config file from URL or path
            --help                         Show this help message
            --login                        Request and save 2fa token
            --setup                        Run setup to save account and 2fa details

EOF

  echo "${HELP_MESSAGE}"
}

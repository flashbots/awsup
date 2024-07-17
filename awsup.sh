#!/usr/bin/env bash
#
# https://github.com/flashbots/awsup
#
#

set -eo pipefail
echo "🆙 Starting awsup..."

TARGET_DIR="${HOME}/.aws"
REPO_URL="https://github.com/flashbots/awsup.git"

DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="${TARGET_DIR}/backup-${DATE}"
TEMP_DIR="$( mktemp -d -t awsup-XXX )"

git_check() {
    if ! command -v git &> /dev/null; then
        echo "🚫 Git is not installed. Please install Git and try again."
        exit 1
    fi
}

handle_file_backup() {
    echo "🔄 Backing up ${TARGET_DIR} to ${BACKUP_DIR}..."
    mkdir -p "${BACKUP_DIR}"

    # Only backup the files, not subdirectories
    for item in "${TARGET_DIR}"/*; do
        if [ -f "${item}" ]; then
            mv "${item}" "${BACKUP_DIR}"
        fi
    done
}

handle_installation() {
    echo "🔄 Downloading and installing..."

    pushd "${TEMP_DIR}" > /dev/null 2>&1

    git clone "${REPO_URL}" > /dev/null 2>&1

    rm -rf awsup/.git
    cp -r awsup/* "${TARGET_DIR}/"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|/Users/anton/|$HOME/|g" "${TARGET_DIR}/credentials"
    else
        sed -i "s|/Users/anton/|$HOME/|g" "${TARGET_DIR}/credentials"
    fi

    popd > /dev/null 2>&1

    echo "✅ Installation complete! To finish setup, run:"
    echo "✨    . ~/.aws/helper.sh --setup"
}

git_check

handle_file_backup

handle_installation

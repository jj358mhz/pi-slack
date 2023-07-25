#!/usr/bin/env bash
# shellcheck disable=SC1090

# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e

# check if the script is running with super user privileges
if [ "$EUID" -ne 0 ]; then
  echo "This script requires super user privileges. Re-executing script with sudo."
  sudo "$0" "$@"  # re-execute script with super user privileges
  exit  # exit the current instance of the script
else
  echo "Running script with super user privileges."
fi

SCRIPT="alerts_slack.py"
CI_PROJECT_URL="https://github.com/jj358mhz/pi-slack"
APP_PATH=$(find . -type f -name ${SCRIPT} ! -path '.git*')
PACKAGED_DATE=$(date +"%F %T %Z")
RELEASE=$(grep -P 'VERSION.*\d+' "${APP_PATH}" | grep --color=never -Po '\d+\.\d+\.\d+')
VERSION=${RELEASE}
SOFTWARE='pi-slack'
SOFTWARE_DESC='Slack alert sender for Broadcastify feeds'
USER=$(whoami)
GET_PIP_URL='https://bootstrap.pypa.io/get-pip.py'
REPO_URL='https://github.com/jj358mhz/pi-slack.git'

# error handling function
function error() {
  echo "Error on line $1, exit code $2"
  exit "$2"
}

# trap errors
trap 'error ${LINENO} $?' ERR

make_venv() {
  # build the python virtual environment
  python -c 'import venv' > /dev/null 2>&1 || \
  apt-get update && apt-get install python3-venv -y || exit $?
  cd "${SOFTWARE}/opt/uplynk/${SOFTWARE}" || exit $?
  python3 -m venv . || exit $?
  source bin/activate || exit $?
  wget -qO- "${GET_PIP_URL}" | python3 || exit $?
  pip install -r requirements.txt || exit $?
  deactivate || exit $?
  cd - || exit
}

install_files() {
  # Clone the GitHub repository
  git clone --depth=1 "${REPO_URL}" .

  # Create necessary directories
  mkdir -p "/usr/local/bin/${SOFTWARE}"
  mkdir -p "/etc/${SOFTWARE}/${SOFTWARE}"
  cd "${SOFTWARE}/opt/uplynk/${SOFTWARE}" || exit $?

  # Remove unnecessary files, if any
  rm -rf .git*

  cd - || exit
}

make_venv
install_files

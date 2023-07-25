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

# Create a temporary directory
temp_dir=$(mktemp -d)

# Clone the GitHub repository into the temporary directory
git clone --depth=1 "${REPO_URL}" "$temp_dir"

make_venv() {
  # Build the python virtual environment
  python -c 'import venv' > /dev/null 2>&1 || \
  apt-get update && apt-get install python3-venv -y || exit $?

  # Create the venv directory
  mkdir -p "/opt/venvs/${SOFTWARE}"
  cd "$temp_dir" || exit $?

  python3 -m venv "/opt/venvs/${SOFTWARE}" || exit $?
  source "/opt/venvs/${SOFTWARE}/bin/activate" || exit $?
  wget -qO- "${GET_PIP_URL}" | python3 || exit $?

  # Install Python dependencies from requirements.txt
  pip install -r requirements.txt || exit $?

  # Deactivate the virtual environment
  deactivate || exit $?

  # Move back to the original directory
  cd - || exit
}

install_files() {
  # Create necessary directories
  mkdir -p "/usr/local/bin/${SOFTWARE}/" "/etc/${SOFTWARE}/${SOFTWARE}.ini/" "/etc/logrotate.d/${SOFTWARE}/" "/etc/systemd/system/${SOFTWARE}.service/"

  # Copy files to their respective directories
  cp -r "$temp_dir"/. "/etc/${SOFTWARE}/${SOFTWARE}.ini/"
  cp -r "$temp_dir"/. "/etc/logrotate.d/${SOFTWARE}/"
  cp -r "$temp_dir"/. "/etc/systemd/system/${SOFTWARE}.service/"
  cp -r "$temp_dir"/alerts_slack.py "/usr/local/bin/${SOFTWARE}/"

  # Ensure the copied files are owned by root
  chown -R root:root "/usr/local/bin/${SOFTWARE}/" "/etc/${SOFTWARE}/" || exit $?

  # Remove unnecessary files, if any
  rm -rf "$temp_dir"/.git*
}

make_venv
install_files

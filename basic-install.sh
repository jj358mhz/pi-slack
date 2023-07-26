#!/usr/bin/env bash
# shellcheck disable=SC1090

# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e

# Set these values so the installer can still run in color
COL_NC='\e[0m' # No Color
COL_LIGHT_GREEN='\e[1;32m'
COL_LIGHT_RED='\e[1;31m'
TICK="[${COL_LIGHT_GREEN}✓${COL_NC}]"
CROSS="[${COL_LIGHT_RED}✗${COL_NC}]"

# check if the script is running with super user privileges
if [ "$EUID" -ne 0 ]; then
  # shellcheck disable=SC2059
  printf "${CROSS}" "This script requires super user privileges. Re-executing script with sudo."
  sudo "$0" "$@"  # re-execute script with super user privileges
  exit  # exit the current instance of the script
else
  # shellcheck disable=SC2059
  printf "${TICK}" "Running script with super user privileges."
fi

SOFTWARE='pi-slack'
GET_PIP_URL='https://bootstrap.pypa.io/get-pip.py'
REPO_URL='https://github.com/jj358mhz/pi-slack.git'

# error handling function
function error() {
  # shellcheck disable=SC2059
  printf "${CROSS}" "Error on line $1, exit code $2"
  exit "$2"
}

# trap errors
trap 'error ${LINENO} $?' ERR

# Stop and disable the service if it's already running
if systemctl is-active --quiet "${SOFTWARE}.service"; then
  printf "${TICK}" "Stopping and disabling ${SOFTWARE}.service..."
  systemctl stop "${SOFTWARE}.service"
  systemctl disable "${SOFTWARE}.service"
fi

# Create a temporary directory
temp_dir=$(mktemp -d)
echo "Temporary directory created: $temp_dir"

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
  pip install -r "requirements.txt" || exit $?

  # Deactivate the virtual environment
  deactivate || exit $?
}

install_files() {
  # Create necessary directories
  mkdir -p "/usr/local/bin/${SOFTWARE}/" "/etc/${SOFTWARE}/"

  # Remove unnecessary files, if any
  rm -rf "$temp_dir/.git*"

  # Check if the .ini file already exists
if [ -f "/etc/${SOFTWARE}/${SOFTWARE}.ini" ]; then
  read -r -p "An .ini file already exists. Do you want to overwrite it? (y/n) " response
  if [[ $response =~ ^[Yy]$ ]]; then
    echo "Overwriting existing .ini file..."
  else
    echo "Skipping .ini file copy."
    rm -r "$temp_dir"  # Remove the temporary directory
    exit 0
  fi
else
  # Prompt the user for their credentials if the .ini file does not exist
  echo "Please enter your feed credentials:"
  read -r -p "FEED_ID: " feed_id
  read -r -p "USERNAME: " username
  read -r -s -p "PASSWORD: " password
  echo
  read -r -p "WEBHOOK_URL: " webhook_url

  # Generate the content of the .ini file with user credentials
  ini_content=$(cat <<EOF
[CREDENTIALS]
# ENTER YOUR BROADCASTIFY FEED ID
FEED_ID = ${feed_id}
# ENTER YOUR BROADCASTIFY USERNAME
USERNAME = ${username}
# ENTER YOUR BROADCASTIFY PASSWORD
PASSWORD = ${password}

[ENDPOINT]
# ENTER YOUR SLACK WEBHOOK URL
WEBHOOK_URL = ${webhook_url}
EOF
)

  # Write the generated .ini content to the actual .ini file
  echo "$ini_content" > "/etc/${SOFTWARE}/${SOFTWARE}.ini"
fi


  # Copy files to their respective directories
  cp "$temp_dir/${SOFTWARE}/usr/local/bin/${SOFTWARE}/alerts_slack.py" "/usr/local/bin/${SOFTWARE}/"
  cp "$temp_dir/${SOFTWARE}/etc/logrotate.d/${SOFTWARE}" "/etc/logrotate.d"
  cp "$temp_dir/${SOFTWARE}/etc/systemd/system/${SOFTWARE}.service" "/etc/systemd/system/"

  # Make alerts_slack.py executable
  chmod +x "/usr/local/bin/${SOFTWARE}/alerts_slack.py"

  # Ensure the copied files are owned by root
  chown -R root:root "/usr/local/bin/${SOFTWARE}/" "/etc/${SOFTWARE}/" || exit $?

  # Remove the temporary directory
  rm -r "$temp_dir"
}

make_venv
install_files

# Enable the service
systemctl enable "${SOFTWARE}.service"

echo " "
echo " "
echo "Service files installed and permissions set & please be sure to \
update your /etc/${SOFTWARE}/${SOFTWARE}.ini file with your feed credentials"

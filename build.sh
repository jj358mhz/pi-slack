#!/usr/bin/env bash

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
  cd "${SOFTWARE}"/opt/uplynk/"${SOFTWARE}"/ || exit $?
  python3 -m venv . || exit $?
  source bin/activate || exit $?
  wget -qO- "${GET_PIP_URL}" | python3 || exit $?
  pip install -r requirements.txt || exit $?
  deactivate || exit $?
  cd - || exit
}

make_deb() {
    # create control file
    echo "Package: ${SOFTWARE}
    Maintainer: Jeff Johnston <jj358mhz@gmail.com>
    Homepage: ${CI_PROJECT_URL}
    Architecture: amd64
    Priority: extra
    Description: ${SOFTWARE_DESC}
    Packaged-on: ${PACKAGED_DATE}
    Ci-Job-Url: ${CI_JOB_URL}
    Version: ${VERSION}" | sed -r 's/^\s+//g' | tee ${SOFTWARE}/DEBIAN/control

    # set exec on pre/post install scripts
    chmod 0755 ${SOFTWARE}/DEBIAN/p*

    # set mode 644 for all files with mode 664
    find ${SOFTWARE} -type f ! -executable -exec chmod 644 {} \;

    # if a directory is executable but not 755, chmod it.
    find ${SOFTWARE} -type d -executable ! -perm 755 -exec chmod 755 {} \;

    # chown package contents to root.root
    chown -R root.root ${SOFTWARE}

    # build debian package
    dpkg-deb --build ${SOFTWARE} ./build

    # make deb readable, just in case.
    find . -type f -name '*deb' -exec chmod 644 {} \;

    # make deb owned by non-root, just in case.
    find . -type f -name '*deb' -exec chown "${USER}"."${USER}" {} \;
}

make_venv
make_deb

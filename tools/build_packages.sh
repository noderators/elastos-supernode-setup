#!/bin/bash

while getopts ":i:" opt; do
  case $opt in
    i) INSTALL="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

CURR_DIR=$(pwd)

function build_deb_package() {
    WORK_DIR="${1}"
    PACKAGE_DIR="${2}"
    PACKAGE_NAME="${3}"

    cd $WORK_DIR
    dpkg-deb --build $PACKAGE_DIR
    if [ "${INSTALL}" == "yes" ]
    then
        sudo apt-get remove -y $PACKAGE_NAME >/dev/null
        sudo systemctl stop $PACKAGE_NAME
        sudo dpkg -i "${PACKAGE_DIR}.deb"
        sudo systemctl daemon-reload
        sudo systemctl start $PACKAGE_NAME
    fi
    cd $CURR_DIR
}

build_deb_package ela elastos-ela_0.3.2-1 elastos-ela

build_deb_package did elastos-did_0.1.2-1 elastos-did 

build_deb_package token elastos-token_0.1.2-1 elastos-token 

build_deb_package carrier elastos-carrier-bootstrap_5.2.3-1 elastos-carrier-bootstrap

cd $CURR_DIR

## SOME USEFUL COMMANDS
# Install deb package
# sudo dpkg -i package.deb
# Start the service
# sudo systemctl start package-name
# Start on boot
# sudo systemctl enable package-name
# Stop the service
# sudo systemctl stop package-name
# Check the status of the service
# sudo systemctl status package-name
# Remove deb package
# sudo apt-get remove package-name
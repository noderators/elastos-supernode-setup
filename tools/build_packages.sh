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
    PACKAGE_NAME="${2}"
    VERSION="${3}"

    cd $WORK_DIR
    dpkg-deb --build $PACKAGE_NAME
    if [ "${INSTALL}" == "yes" ]
    then
        sudo apt-get remove -y $PACKAGE_NAME >/dev/null
        sudo systemctl stop $PACKAGE_NAME
        sudo dpkg -i "${PACKAGE_NAME}.deb"
        sudo systemctl daemon-reload
        sudo systemctl start $PACKAGE_NAME
    fi
    mv "${PACKAGE_NAME}.deb" "${PACKAGE_NAME}_${VERSION}.deb"
    cd $CURR_DIR
}

build_deb_package ela elastos-ela 0.5.0-1

build_deb_package did elastos-did 0.1.5-1

build_deb_package token elastos-token 0.1.2-3

build_deb_package carrier elastos-carrier-bootstrap 5.2.3-2

build_deb_package metrics elastos-metrics 1.2.0-2

build_deb_package ioex ioex-mainchain 0.2.1-1

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
#!/bin/bash

CURR_DIR=$(pwd)

function build_deb_package() {
    WORK_DIR="${1}"
    PACKAGE="${2}"

    cd $WORK_DIR
    dpkg-deb --build $PACKAGE
    cd $CURR_DIR
}

build_deb_package ela elastos-ela_0.3.2-1

build_deb_package did elastos-did_0.1.2-1

build_deb_package token elastos-token_0.1.2-1

build_deb_package carrier elastos-carrier-bootstrap_5.2.3-1

cd $CURR_DIR

# Install deb package
# sudo dpkg -i package.deb
# Start the service
# sudo systemctl start elastos-ela
# Start on boot
# sudo systemctl enable elastos-ela
# Stop the service
# sudo systemctl stop elastos-ela
# Check the status of the service
# sudo systemctl status elastos-ela
# Remove deb package
# sudo apt-get remove package-name
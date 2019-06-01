#!/bin/bash

while getopts ":f:c:" opt; do
  case $opt in
    f) CONFIG_FILE="$OPTARG"
    ;;
    c) COMMAND="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [ -z "${CONFIG_FILE}" ]
then
  CONFIG_FILE="/data/elastos/carrier/bootstrap.conf"
fi

if [ "${COMMAND}" == "start" ]
then
  nohup /usr/local/bin/elastos-carrier-bootstrap --config ${CONFIG_FILE} --foreground > /dev/null 2>output
fi
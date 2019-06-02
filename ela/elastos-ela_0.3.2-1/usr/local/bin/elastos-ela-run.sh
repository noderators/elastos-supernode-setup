#!/bin/bash

while getopts ":f:p:c:" opt; do
  case $opt in
    f) CONFIG_FILE="$OPTARG"
    ;;
    p) KEYSTORE_PASSWORD="$OPTARG"
    ;;
    c) COMMAND="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [ -z "${CONFIG_FILE}" ]
then
  CONFIG_FILE="/data/elastos/ela/config.json"
fi

if [ "${COMMAND}" == "start" ]
then
  if [ -z "${KEYSTORE_PASSWORD}" ]
  then
    /usr/local/bin/elastos-ela --conf ${CONFIG_FILE}
  else 
    echo ${KEYSTORE_PASSWORD} | /usr/local/bin/elastos-ela --conf ${CONFIG_FILE}
  fi
fi
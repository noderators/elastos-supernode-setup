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
  CONFIG_FILE="/etc/elastos-ela/config.json"
fi

if [ "${COMMAND}" == "start" ]
then
  if [ -z "${KEYSTORE_PASSWORD}" ]
  then
    nohup /usr/local/bin/elastos-ela --conf ${CONFIG_FILE} > /dev/null 2>output
  else 
    echo ${KEYSTORE_PASSWORD} | nohup /usr/local/bin/elastos-ela --conf ${CONFIG_FILE} > /dev/null 2>output
  fi
fi
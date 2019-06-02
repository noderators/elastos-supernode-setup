#!/bin/bash

while getopts ":c:" opt; do
  case $opt in
    c) COMMAND="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [ "${COMMAND}" == "start" ]
then
    /usr/local/bin/elastos-token
fi
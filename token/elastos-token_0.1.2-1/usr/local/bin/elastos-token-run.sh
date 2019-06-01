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
    nohup /usr/local/bin/elastos-token > /dev/null 2>output
fi
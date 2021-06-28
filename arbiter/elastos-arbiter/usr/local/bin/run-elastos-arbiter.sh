#!/bin/bash

# Make sure the nodes are healthy before starting up arbiter node
# Check for mainchain node
status=""
echo "Checking to see if mainchain is synced up..."
while [[ ${status} != "ready" ]]
do 
  port=$(cat /data/elastos/ela/config.json | jq -r ".Configuration.HttpJsonPort")
  usr=$(cat /data/elastos/ela/config.json | jq -r ".Configuration.RpcConfiguration.User")
  pswd=$(cat /data/elastos/ela/config.json | jq -r ".Configuration.RpcConfiguration.Pass")
  height=$(curl -X POST --user ${usr}:${pswd} http://localhost:${port} -H 'Content-Type: application/json' -d '{"method":"getnodestate"}' | jq ".result.height")
  if [[ ${height} != null ]] && [[ ! -z "${height}" ]]; then status="ready"; else sleep 5; fi
done
echo "Mainchain is all synced up"

# Check for did node
status=""
echo "Checking to see if Elastos ID(EID) sidechain is synced up..."
while [[ ${status} != "ready" ]]
do 
  port=$(cat /data/elastos/did/config.json | jq -r ".RPCPort")
  usr=$(cat /data/elastos/did/config.json | jq -r ".RPCUser")
  pswd=$(cat /data/elastos/did/config.json | jq -r ".RPCPass")
  height=$(curl -X POST --user ${usr}:${pswd} http://localhost:${port} -H 'Content-Type: application/json' -d '{"method":"getnodestate"}' | jq ".result.height")
  if [[ ${height} != null ]] && [[ ! -z "${height}" ]]; then status="ready"; else sleep 5; fi
done
echo "Elastos ID(EID) sidechain is all synced up"

# Check for eth node
status=""
echo "Checking to see if Elastos Smart Contract(ESC) sidechain is synced up..."
while [[ ${status} != "ready" ]]
do 
  port=$(cat /etc/elastos-eth/params.env | grep RPCPORT | sed 's#.*RPCPORT=##g' | sed 's#"##g')
  height=$(curl -X POST http://localhost:${port} -H 'Content-Type: application/json' -d '{"method":"eth_blockNumber", "id":1}' | jq -r ".result")
  if [[ ${height} != null ]] && [[ ! -z "${height}" ]]; then status="ready"; else sleep 5; fi
done
echo "Elastos Smart Contract(ESC) sidechain is all synced up"

# Start arbiter process
echo "Starting Elastos Arbiter process..."
KEYSTORE_PASSWORD=$(cat /etc/elastos-ela/params.env | grep KEYSTORE_PASSWORD | sed 's#.*KEYSTORE_PASSWORD=##g' | sed 's#"##g')
/usr/local/bin/elastos-arbiter -p ${KEYSTORE_PASSWORD}
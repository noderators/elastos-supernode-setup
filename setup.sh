#!/usr/bin/env bash

RELEASE="v1.25"

# If not running with sudo, exit 
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  echo "This script needs to run with sudo priviledges. Please re-run the script as root"
  exit
fi

# Create a temporary directory that will be deleted when the script exits or is interrupted
MYTMPDIR="$(mktemp -d)"
trap 'rm -rf -- "$MYTMPDIR"' EXIT

cd ${MYTMPDIR}

function stop_script () {
  ERROR=$1
  if [ ! -z "${ERROR}" ]
  then
    echo "Encountered an error: ${ERROR}"
    echo "Exiting..."
  else
    echo 'Cleaning up and exiting...'
  fi
  rm -rf ${TMP_DIR}
  exit 1
}
trap stop_script EXIT

# Prepare by updating packages and installing dependencies before the installation
echo "Updating the system packages"
apt-get update -y 
echo "Installing third party tools and dependencies"
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
apt-get install -y python3 python3-pip nodejs jq || stop_script "Cannot install third party tools and dependencies"
echo "Installing dependencies for Elastos Supernode if not installed"
DEPS=( "prometheus" "prometheus-node-exporter" "prometheus-pushgateway" "prometheus-alertmanager" )
for dep in "${DEPS[@]}"
do
  dpkg -s ${dep} >/dev/null 2>&1
  if [ $(echo $?) -ne "0" ]
  then 
    apt-get install ${dep} -y
  fi
done
# Remove token sidechain stuff as it's no longer needed to be run
apt-get remove elastos-token -y; rm -rf /data/elastos/token 
# Remove ioex node as it's no longer supported
apt-get remove ioex-mainchain -y; rm -rf /data/ioex

# Make sure to backup important config files and wallets before proceeding just in case something goes wrong
if [ -f /data/elastos/ela/keystore.dat ]
then
  PREVIOUS_INSTALL="yes"
  # Let's backup these files just in case the user does not want to change any settings with the new release
  NOW=$(date +"%Y-%m-%dT%H:%M:%S")
  mkdir -p /data/elastos/backup/${NOW}
  cp /data/elastos/ela/keystore.dat mainchain_keystore.dat; cp /data/elastos/ela/keystore.dat /data/elastos/backup/${NOW}/mainchain_keystore.dat
  cp /data/elastos/ela/config.json mainchain_config.json; cp /data/elastos/ela/config.json /data/elastos/backup/${NOW}/mainchain_config.json
  cp /data/elastos/did/config.json did_config.json; cp /data/elastos/did/config.json /data/elastos/backup/${NOW}/did_config.json
  cp /data/elastos/eid/keystore.dat eid_keystore.dat; cp /data/elastos/eid/keystore.dat /data/elastos/backup/${NOW}/eid_keystore.dat
  cp /data/elastos/eid/data/keystore/miner-keystore.dat eid_miner_keystore.dat; cp /data/elastos/eid/data/keystore/miner-keystore.dat /data/elastos/backup/${NOW}/miner-keystore.dat
  cp /etc/elastos-eid/params.env eid_params.env; cp /etc/elastos-eid/params.env /data/elastos/backup/${NOW}/eid_params.env
  cp /data/elastos/eth/keystore.dat eth_keystore.dat; cp /data/elastos/eth/keystore.dat /data/elastos/backup/${NOW}/eth_keystore.dat
  cp /data/elastos/eth/data/keystore/miner-keystore.dat eth_miner_keystore.dat; cp /data/elastos/eth/data/keystore/miner-keystore.dat /data/elastos/backup/${NOW}/miner-keystore.dat
  cp /etc/elastos-eth/params.env eth_params.env; cp /etc/elastos-eth/params.env /data/elastos/backup/${NOW}/eth_params.env
  cp /data/elastos/arbiter/config.json arbiter_config.json; cp /data/elastos/arbiter/config.json /data/elastos/backup/${NOW}/arbiter_config.json
  if [ ! -f /data/elastos/arbiter/keystore.dat ]
  then 
    cp /data/elastos/ela/keystore.dat /data/elastos/arbiter/keystore.dat
  fi
  cp /data/elastos/arbiter/keystore.dat arbiter_keystore.dat; cp /data/elastos/arbiter/keystore.dat /data/elastos/backup/${NOW}/arbiter_keystore.dat
  cp /etc/elastos-metrics/params.env metrics_params.env; cp /etc/elastos-metrics/params.env /data/elastos/backup/${NOW}/metrics_params.env
  cp /data/elastos/metrics/conf/prometheus.yml prometheus.yml; cp /data/elastos/metrics/conf/prometheus.yml /data/elastos/backup/${NOW}/prometheus.yml
  cp /data/elastos/metrics/conf/alertmanager.yml alertmanager.yml; cp /data/elastos/metrics/conf/alertmanager.yml /data/elastos/backup/${NOW}/alertmanager.yml
fi

# Download all the noderators packages required for setting up Elastos Supernode
echo ""
echo "Downloading packages required for Elastos Supernode"
DEPS=( "elastos-ela" "elastos-did" "elastos-eid" "elastos-eth" "elastos-arbiter" "elastos-carrier-bootstrap" "elastos-metrics" )
VERSIONS=( "0.7.0-3" "0.3.1-2" "0.1.0-1" "0.1.3-2" "0.2.3-1" "6.0.1-1" "1.6.0-1" )
for i in "${!DEPS[@]}"
do 
  echo "Downloading ${DEPS[$i]} Version: ${VERSIONS[$i]}"
  wget https://github.com/noderators/elastos-supernode-setup/releases/download/${RELEASE}/${DEPS[$i]}_${VERSIONS[$i]}.deb
  dpkg -s ${DEPS[$i]} | grep Version | grep ${VERSIONS[$i]}
  if [ $(echo $?) -ne "0" ]
  then 
    echo "Installing ${DEPS[$i]} Version: ${VERSIONS[$i]}"
    dpkg -i --force-confmiss --force-confnew "${DEPS[$i]}_${VERSIONS[$i]}.deb"
    apt-get install -f
  else  
    echo "${DEPS[$i]} is already the latest version with Version: ${VERSIONS[$i]}"
  fi
done

# If this is the first time installing packages, we wanna make sure to copy required info from config files 
# from the packages that were just installed
if [[ "${PREVIOUS_INSTALL}" != "yes" ]]
then
  # Let's backup these files just in case the user does not want to change any settings with the new release
  NOW=$(date +"%Y-%m-%dT%H:%M:%S")
  mkdir -p /data/elastos/backup/${NOW}
  cp /data/elastos/ela/keystore.dat mainchain_keystore.dat; cp /data/elastos/ela/keystore.dat /data/elastos/backup/${NOW}/mainchain_keystore.dat
  cp /data/elastos/ela/config.json mainchain_config.json; cp /data/elastos/ela/config.json /data/elastos/backup/${NOW}/mainchain_config.json
  cp /data/elastos/did/config.json did_config.json; cp /data/elastos/did/config.json /data/elastos/backup/${NOW}/did_config.json
  cp /data/elastos/eid/keystore.dat eid_keystore.dat; cp /data/elastos/eid/keystore.dat /data/elastos/backup/${NOW}/eid_keystore.dat
  cp /data/elastos/eid/data/keystore/miner-keystore.dat eid_miner_keystore.dat; cp /data/elastos/eid/data/keystore/miner-keystore.dat /data/elastos/backup/${NOW}/miner-keystore.dat
  cp /etc/elastos-eid/params.env eid_params.env; cp /etc/elastos-eid/params.env /data/elastos/backup/${NOW}/eid_params.env
  cp /data/elastos/eth/keystore.dat eth_keystore.dat; cp /data/elastos/eth/keystore.dat /data/elastos/backup/${NOW}/eth_keystore.dat
  cp /data/elastos/eth/data/keystore/miner-keystore.dat eth_miner_keystore.dat; cp /data/elastos/eth/data/keystore/miner-keystore.dat /data/elastos/backup/${NOW}/miner-keystore.dat
  cp /etc/elastos-eth/params.env eth_params.env; cp /etc/elastos-eth/params.env /data/elastos/backup/${NOW}/eth_params.env
  cp /data/elastos/arbiter/config.json arbiter_config.json; cp /data/elastos/arbiter/config.json /data/elastos/backup/${NOW}/arbiter_config.json
  if [ ! -f /data/elastos/arbiter/keystore.dat ]
  then 
    cp /data/elastos/ela/keystore.dat /data/elastos/arbiter/keystore.dat
  fi
  cp /data/elastos/arbiter/keystore.dat arbiter_keystore.dat; cp /data/elastos/arbiter/keystore.dat /data/elastos/backup/${NOW}/arbiter_keystore.dat
  cp /etc/elastos-metrics/params.env metrics_params.env; cp /etc/elastos-metrics/params.env /data/elastos/backup/${NOW}/metrics_params.env
  cp /data/elastos/metrics/conf/prometheus.yml prometheus.yml; cp /data/elastos/metrics/conf/prometheus.yml /data/elastos/backup/${NOW}/prometheus.yml
  cp /data/elastos/metrics/conf/alertmanager.yml alertmanager.yml; cp /data/elastos/metrics/conf/alertmanager.yml /data/elastos/backup/${NOW}/alertmanager.yml
fi

# Create a new wallet for ELA mainchain node or do nothing depending on what the user wants to do
echo ""
echo "Personalizing your Elastos Supernode setup"
read -p "WARNING! You're trying to create a new wallet for ELA mainchain node. This may replace your previous wallet if it exists already. Proceed? [y/N] " answer
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then 
  rm -f /data/elastos/ela/keystore.dat 
  read -p "Enter the password for your keystore.dat: " pswd
  echo "Creating a wallet with the given password"
  /usr/local/bin/elastos-ela-cli wallet create -p ${pswd}
  mv keystore.dat /data/elastos/ela/keystore.dat
  chown elauser:elauser /data/elastos/ela/keystore.dat 
  cp /data/elastos/ela/keystore.dat /data/elastos/eth/keystore.dat
  cp /data/elastos/ela/keystore.dat /data/elastos/arbiter/keystore.dat
  sed -i "s#KEYSTORE_PASSWORD=.*#KEYSTORE_PASSWORD=\"${pswd}\"#g" /etc/elastos-ela/params.env
  keyword_password_file=$(cat /etc/elastos-eth/params.env | grep KEYSTORE_PASSWORD_FILE | sed 's#.*KEYSTORE_PASSWORD_FILE=##g' | sed 's#"##g')
  echo ${pswd} > ${keyword_password_file}
else 
  cp mainchain_keystore.dat /data/elastos/ela/keystore.dat
  cp eid_keystore.dat /data/elastos/eid/keystore.dat
  cp eth_keystore.dat /data/elastos/eth/keystore.dat
  cp arbiter_keystore.dat /data/elastos/arbiter/keystore.dat
fi
chmod 644 /data/elastos/ela/keystore.dat

# Create a new secondary wallet for DID sidechain node on Arbiter node if it doesn't exist
echo ""
pswd=$(cat /etc/elastos-ela/params.env | grep KEYSTORE_PASSWORD | sed 's#.*KEYSTORE_PASSWORD=##g' | sed 's#"##g')
# Check to make sure whether the keystore.dat of ELA mainchain node and Arbiter node match
cp /data/elastos/arbiter/keystore.dat .
NUM_WALLETS=$(elastos-ela-cli wallet a -p ${pswd} | grep - | wc -l)
NUM_WALLETS=$(expr ${NUM_WALLETS} - 1)
ELA_ADDRESS=$(cat /data/elastos/ela/keystore.dat | jq -r ".Account[0].Address")
if [[ "${ELA_ADDRESS}" != "$(cat /data/elastos/arbiter/keystore.dat | jq -r ".Account[0].Address")" ]]
then 
  if [[ "${NUM_WALLETS}" -gt "2" ]] || [[ "${NUM_WALLETS}" -lt "2" ]]
  then 
    cp /data/elastos/ela/keystore.dat .
    NUM_WALLETS=1
  elif [[ "${NUM_WALLETS}" -eq "2" ]] 
  then 
    if [[ "${ELA_ADDRESS}" != "$(cat /data/elastos/arbiter/keystore.dat | jq -r ".Account[1].Address")" ]]
    then 
      cp /data/elastos/ela/keystore.dat .
      NUM_WALLETS=1
    fi
  fi 
fi 
if [[ "${NUM_WALLETS}" -eq "1" ]]
then
  echo ""
  echo "Creating a secondary account for Arbiter node that will be used for did block generation"
  chown $USER:$USER keystore.dat
  /usr/local/bin/elastos-ela-cli wallet add -p ${pswd}
  cp keystore.dat /data/elastos/arbiter/keystore.dat
  chown elauser:elauser /data/elastos/arbiter/keystore.dat 
fi
chmod 644 /data/elastos/arbiter/keystore.dat

# Configure all the configs for RPC and miner info for ELA mainchain node
echo ""
echo "Modifying the config file parameters for ELA mainchain node"
cat <<< $(jq ".Configuration.DPoSConfiguration.IPAddress = \"$(curl ifconfig.me)\"" /data/elastos/ela/config.json) > /data/elastos/ela/config.json
read -p "Would you like to change the current info for RPC configuration and/or miner configuration for this node? [y/N] " answer
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter the port you would like to set for RPC configuration: " port
  read -p "Enter the username you would like to set for RPC configuration: " usr
  read -p "Enter the password you would like to set for RPC configuration: " pswd
  read -p "Enter the ELA address you would like to set for miner fees payout: " elaaddr
  read -p "Enter the miner name you would like to assign to your node: " minername
else 
  port=$(cat mainchain_config.json | jq -r ".Configuration.HttpJsonPort")
  usr=$(cat mainchain_config.json | jq -r ".Configuration.RpcConfiguration.User")
  pswd=$(cat mainchain_config.json | jq -r ".Configuration.RpcConfiguration.Pass")
  elaaddr=$(cat mainchain_config.json | jq -r ".Configuration.PowConfiguration.PayToAddr")
  minername=$(cat mainchain_config.json | jq -r ".Configuration.PowConfiguration.MinerInfo")
fi
if [[ ${port} = null ]] || [[ -z ${port} ]]; then port="20336"; fi
if [[ ${usr} = null ]]; then usr=""; fi
if [[ ${pswd} = null ]]; then pswd=""; fi
if [[ ${elaaddr} = null ]] || [[ -z ${elaaddr} ]]; then elaaddr="EHohTEm9oVUY5EQxm8MDb6fBEoRpwTyjbb"; fi
if [[ ${minername} = null ]] || [[ -z ${minername} ]]; then minername="Noderators - Watermelon"; fi
cat <<< $(jq ".Configuration.HttpJsonPort = ${port}" /data/elastos/ela/config.json) > /data/elastos/ela/config.json
cat <<< $(jq ".Configuration.RpcConfiguration.User = \"${usr}\"" /data/elastos/ela/config.json) > /data/elastos/ela/config.json
cat <<< $(jq ".Configuration.RpcConfiguration.Pass = \"${pswd}\"" /data/elastos/ela/config.json) > /data/elastos/ela/config.json
cat <<< $(jq ".Configuration.PowConfiguration.PayToAddr = \"${elaaddr}\"" /data/elastos/ela/config.json) > /data/elastos/ela/config.json
cat <<< $(jq ".Configuration.PowConfiguration.MinerInfo = \"${minername}\"" /data/elastos/ela/config.json) > /data/elastos/ela/config.json
cat <<< $(jq ".Configuration.MainNode.Rpc.HttpJsonPort = ${port}" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json
cat <<< $(jq ".Configuration.MainNode.Rpc.User = \"${usr}\"" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json
cat <<< $(jq ".Configuration.MainNode.Rpc.Pass = \"${pswd}\"" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json

# Configure all the configs for RPC and miner info for DID sidechain node
echo ""
echo "Modifying the config file parameters for DID sidechain node"
read -p "Would you like to change the current info for RPC configuration and/or miner configuration for this node? [y/N] " answer
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter the port you would like to set for RPC configuration: " port
  read -p "Enter the username you would like to set for RPC configuration: " usr
  read -p "Enter the password you would like to set for RPC configuration: " pswd
  read -p "Enter the ELA address you would like to set for miner fees payout: " elaaddr
  read -p "Enter the miner name you would like to assign to your node: " minername
else 
  port=$(cat did_config.json | jq -r ".RPCPort")
  usr=$(cat did_config.json | jq -r ".RPCUser")
  pswd=$(cat did_config.json | jq -r ".RPCPass")
  elaaddr=$(cat did_config.json | jq -r ".PayToAddr")
  minername=$(cat did_config.json | jq -r ".MinerInfo")
fi
if [[ ${port} = null ]] || [[ -z ${port} ]]; then port="20606"; fi
if [[ ${usr} = null ]]; then usr=""; fi
if [[ ${pswd} = null ]]; then pswd=""; fi
if [[ ${elaaddr} = null ]] || [[ -z ${elaaddr} ]]; then elaaddr="EHohTEm9oVUY5EQxm8MDb6fBEoRpwTyjbb"; fi
if [[ ${minername} = null ]] || [[ -z ${minername} ]]; then minername="Noderators - Watermelon"; fi
cat <<< $(jq ".RPCPort = ${port}" /data/elastos/did/config.json) > /data/elastos/did/config.json
cat <<< $(jq ".RPCUser = \"${usr}\"" /data/elastos/did/config.json) > /data/elastos/did/config.json
cat <<< $(jq ".RPCPass = \"${pswd}\"" /data/elastos/did/config.json) > /data/elastos/did/config.json
cat <<< $(jq ".PayToAddr = \"${elaaddr}\"" /data/elastos/did/config.json) > /data/elastos/did/config.json
cat <<< $(jq ".MinerInfo = \"${minername}\"" /data/elastos/did/config.json) > /data/elastos/did/config.json
cat <<< $(jq ".Configuration.SideNodeList[2].Rpc.HttpJsonPort = ${port}" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json
cat <<< $(jq ".Configuration.SideNodeList[2].Rpc.User = \"${usr}\"" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json
cat <<< $(jq ".Configuration.SideNodeList[2].Rpc.Pass = \"${pswd}\"" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json
cat <<< $(jq ".Configuration.SideNodeList[2].PayToAddr = \"${elaaddr}\"" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json
mining_address=$(cat /data/elastos/arbiter/keystore.dat | jq -r ".Account[0].Address")
if [[ "$(cat /data/elastos/arbiter/keystore.dat | jq -r ".Account[0].Type")" != "sub-account" ]]
then 
  mining_address=$(cat /data/elastos/arbiter/keystore.dat | jq -r ".Account[1].Address")
fi
cat <<< $(jq ".Configuration.SideNodeList[2].MiningAddr = \"${mining_address}\"" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json

# Configure all the configs for Elastos ID(EID) sidechain node such as creating miner wallet if it 
# does not exist 
echo ""
echo "Modifying the config file parameters for Elastos ID(EID) sidechain node"
read -p "WARNING! You're trying to create a new eid miner wallet. This may replace your previous wallet if it exists already. Proceed? [y/N] " answer
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then 
  rm -f /data/elastos/eid/data/keystore/miner-keystore.dat
  read -p "Enter the password for your miner-keystore.dat: " pswd
  miner_password_file=$(cat /etc/elastos-eid/params.env | grep MINER_PASSWORD_FILE | sed 's#.*MINER_PASSWORD_FILE=##g' | sed 's#"##g')
  echo ${pswd} > ${miner_password_file}
  echo "Creating a eid miner wallet with the given password"
  datadir=$(cat /etc/elastos-eid/params.env | grep DATADIR | sed 's#.*DATADIR=##g' | sed 's#"##g')
  /usr/local/bin/elastos-eid --datadir ${datadir} account new --password ${miner_password_file}
  mv /data/elastos/eid/data/keystore/UTC* /data/elastos/eid/data/keystore/miner-keystore.dat
  chown elauser:elauser /data/elastos/eid/data/keystore/miner-keystore.dat 
else 
  cp eid_miner_keystore.dat /data/elastos/eid/data/keystore/miner-keystore.dat
fi
chmod 644 /data/elastos/eid/data/keystore/miner-keystore.dat
read -p "Would you like to change the current info for RPC configuration and/or miner configuration for this node? [y/N] " answer
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter the port you would like to set for RPC configuration: " port
else 
  port=$(cat eid_params.env | grep RPCPORT | sed 's#.*RPCPORT=##g' | sed 's#"##g')
fi
if [[ ${port} = null ]] || [[ -z ${port} ]]; then port="20646"; fi
sed -i "s#RPCPORT=.*#RPCPORT=\"${port}\"#g" /etc/elastos-eid/params.env
ipaddress=$(curl ifconfig.me)
sed -i "s#IPADDRESS=.*#IPADDRESS=\"${ipaddress}\"#g" /etc/elastos-eid/params.env
cd /data/elastos/eid/oracle
npm install
cd ${MYTMPDIR}

# Configure all the configs for Elastos Smart Contract(ESC) sidechain node such as creating miner wallet if it 
# does not exist 
echo ""
echo "Modifying the config file parameters for Smart Contract Sidechain(ETH) node"
read -p "WARNING! You're trying to create a new eth miner wallet. This may replace your previous wallet if it exists already. Proceed? [y/N] " answer
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then 
  rm -f /data/elastos/eth/data/keystore/miner-keystore.dat
  read -p "Enter the password for your miner-keystore.dat: " pswd
  miner_password_file=$(cat /etc/elastos-eth/params.env | grep MINER_PASSWORD_FILE | sed 's#.*MINER_PASSWORD_FILE=##g' | sed 's#"##g')
  echo ${pswd} > ${miner_password_file}
  echo "Creating a eth miner wallet with the given password"
  datadir=$(cat /etc/elastos-eth/params.env | grep DATADIR | sed 's#.*DATADIR=##g' | sed 's#"##g')
  /usr/local/bin/elastos-geth --datadir ${datadir} account new --password ${miner_password_file}
  mv /data/elastos/eth/data/keystore/UTC* /data/elastos/eth/data/keystore/miner-keystore.dat
  chown elauser:elauser /data/elastos/eth/data/keystore/miner-keystore.dat 
else 
  cp eth_miner_keystore.dat /data/elastos/eth/data/keystore/miner-keystore.dat
fi
chmod 644 /data/elastos/eth/data/keystore/miner-keystore.dat
read -p "Would you like to change the current info for RPC configuration and/or miner configuration for this node? [y/N] " answer
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter the port you would like to set for RPC configuration: " port
  read -p "Enter the ETH address you would like to set for miner fees payout: " elaaddr
else 
  port=$(cat eth_params.env | grep RPCPORT | sed 's#.*RPCPORT=##g' | sed 's#"##g')
fi
if [[ ${port} = null ]] || [[ -z ${port} ]]; then port="20636"; fi
sed -i "s#RPCPORT=.*#RPCPORT=\"${port}\"#g" /etc/elastos-eth/params.env
ipaddress=$(curl ifconfig.me)
sed -i "s#IPADDRESS=.*#IPADDRESS=\"${ipaddress}\"#g" /etc/elastos-eth/params.env
cd /data/elastos/eth/oracle
npm install
cd ${MYTMPDIR}

# Configure all the configs for RPC and miner info for Arbiter node
echo ""
echo "Modifying the config file parameters for Arbiter node"
read -p "Would you like to change the current info for RPC configuration and/or miner configuration for this node? [y/N] " answer
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter the username you would like to set for RPC configuration: " usr
  read -p "Enter the password you would like to set for RPC configuration: " pswd
else 
  usr=$(cat arbiter_config.json | jq -r ".Configuration.RpcConfiguration.User")
  pswd=$(cat arbiter_config.json | jq -r ".Configuration.RpcConfiguration.Pass")
fi
if [[ ${usr} = null ]]; then usr=""; fi
if [[ ${pswd} = null ]]; then pswd=""; fi
cat <<< $(jq ".Configuration.RpcConfiguration.User = \"${usr}\"" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json
cat <<< $(jq ".Configuration.RpcConfiguration.Pass = \"${pswd}\"" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json

# Configure all the configs for Carrier Bootstrap node
echo ""
echo "Modifying the config file parameters for Carrier Bootstrap node"
sed -i "s#// external_ip.*#external_ip = \"$(curl ifconfig.me)\"#g" /data/elastos/carrier/bootstrap.conf

# Configure all the configs for Metrics node such as setting up username and password
echo ""
echo "Modifying the config file parameters for Metrics node"
read -p "Would you like to change the current settings for metrics endpoint? [y/N] " answer 
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter the port to be used for exposing your supernode metrics: " port
  read -p "Enter the username to be used for exposing your supernode metrics: " usr
  read -p "Enter the password to be used for exposing your supernode metrics: " pswd
else 
  port=$(cat metrics_params.env | grep PORT | sed 's#.*PORT=##g' | sed 's#"##g')
  usr=$(cat metrics_params.env | grep AUTH_USER | sed 's#.*AUTH_USER=##g' | sed 's#"##g')
  pswd=$(cat metrics_params.env | grep AUTH_PASSWORD | sed 's#.*AUTH_PASSWORD=##g' | sed 's#"##g')
fi 
if [[ ${port} = null ]] || [[ -z ${port} ]]; then port="5000"; fi
if [[ ${usr} = null ]]; then usr="user"; fi
if [[ ${pswd} = null ]]; then pswd="password"; fi
sed -i "s#PORT=.*#PORT=\"${port}\"#g" /etc/elastos-metrics/params.env
sed -i "s#AUTH_USER=.*#AUTH_USER=\"${usr}\"#g" /etc/elastos-metrics/params.env
sed -i "s#AUTH_PASSWORD=.*#AUTH_PASSWORD=\"${pswd}\"#g" /etc/elastos-metrics/params.env

# Configure all the configs for Prometheus and Alertmanager such as setting up alerts to be
# sent to the user's email
echo ""
echo "Modifying the config file parameters for Prometheus and Alertmanager"
read -p "Would you like to change your supernode name for Prometheus configuration? [y/N] " answer 
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter the name of your supernode: " supernodeName
else 
  supernodeName=$(cat prometheus.yml | grep replacement | sed 's#.*replacement: ##g' | sed 's#:9100##g' | sed 's#"##g')
fi 
sed -i "s#replacement:.*#replacement: \"${supernodeName}:9100\"#g" /data/elastos/metrics/conf/prometheus.yml
read -p "Would you like to change your smtp settings for Alertmanager configuration? [y/N] " answer 
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter your smtp host for your Alertmanager setting if you would like to setup email alerts for your supernode: " smtp_smarthost
  read -p "Enter your smtp 'from' address for your Alertmanager setting if you would like to setup email alerts for your supernode: " smtp_from
  read -p "Enter the email to send the alerts to for your Alertmanager setting if you would like to setup email alerts for your supernode: " smtp_to
  read -p "Enter your smtp username for your Alertmanager setting if you would like to setup email alerts for your supernode: " smtp_auth_username
  read -p "Enter you smtp password for your Alertmanager setting if you would like to setup email alerts for your supernode: " smtp_auth_password
else 
  smtp_smarthost=$(cat alertmanager.yml | grep smtp_smarthost | sed 's#.*smtp_smarthost: ##g' | sed 's#"##g')
  smtp_from=$(cat alertmanager.yml | grep smtp_from | sed 's#.*smtp_from: ##g' | sed 's#"##g')
  smtp_to=$(cat alertmanager.yml | grep "to: " | sed 's#.*to: ##g' | sed 's#"##g')
  smtp_auth_username=$(cat alertmanager.yml | grep smtp_auth_username | sed 's#.*smtp_auth_username: ##g' | sed 's#"##g')
  smtp_auth_password=$(cat alertmanager.yml | grep smtp_auth_password | sed 's#.*smtp_auth_password: ##g' | sed 's#"##g')
fi 
if [[ ${smtp_smarthost} = null ]] || [[ -z ${smtp_smarthost} ]]; then smtp_smarthost="localhost:25"; fi
if [[ ${smtp_from} = null ]] || [[ -z ${smtp_from} ]]; then smtp_from="smtp_from@noderators.org"; fi
if [[ ${smtp_to} = null ]] || [[ -z ${smtp_to} ]]; then smtp_to="smtp_to@noderators.org"; fi
if [[ ${smtp_auth_username} = null ]]; then smtp_auth_username=""; fi
if [[ ${smtp_auth_password} = null ]]; then smtp_auth_password=""; fi
sed -i "s#smtp_smarthost:.*#smtp_smarthost: \"${smtp_smarthost}\"#g" /data/elastos/metrics/conf/alertmanager.yml
sed -i "s#smtp_from:.*#smtp_from: \"${smtp_from}\"#g" /data/elastos/metrics/conf/alertmanager.yml
sed -i "s#smtp_auth_username:.*#smtp_auth_username: \"${smtp_auth_username}\"#g" /data/elastos/metrics/conf/alertmanager.yml
sed -i "s#smtp_auth_password:.*#smtp_auth_password: \"${smtp_auth_password}\"#g" /data/elastos/metrics/conf/alertmanager.yml
sed -i "s#to:.*#to: \"${smtp_to}\"#g" /data/elastos/metrics/conf/alertmanager.yml

# Start all the services required for running the Elastos supernode
echo ""
echo "Starting up all the services required for running the supernode"
systemctl daemon-reload
systemctl restart elastos-ela elastos-did elastos-eid elastos-eid-oracle elastos-eth elastos-eth-oracle elastos-carrier-bootstrap elastos-metrics prometheus prometheus-node-exporter prometheus-pushgateway prometheus-alertmanager
systemctl restart elastos-arbiter
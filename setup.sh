#!/usr/bin/env bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  echo "This script needs to run with sudo priviledges. Please re-run the script as root"
  exit
fi

MYTMPDIR="$(mktemp -d)"
WORK_DIR="${HOME}/.noderators"
mkdir -p ${WORK_DIR}

trap 'rm -rf -- "$MYTMPDIR"' EXIT
cd ${MYTMPDIR}

RELEASE="v1.24"

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

echo "Updating the system packages"
apt-get update -y 
echo "Installing third party tools and dependencies"
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
apt-get install -y python3 python3-pip nodejs || stop_script "Cannot install third party tools and dependencies"
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

if [ -f /data/elastos/ela/keystore.dat ]
then
  PREVIOUS_INSTALL="yes"
  # Let's backup these files just in case the user does not want to change any settings with the new release
  cp /data/elastos/ela/keystore.dat mainchain_keystore.dat
  cp /data/elastos/ela/config.json mainchain_config.json 
  cp /data/elastos/did/config.json did_config.json 
  cp /data/elastos/eth/keystore.dat eth_keystore.dat
  cp /data/elastos/eth/data/keystore/miner-keystore.dat eth_miner_keystore.dat
  cp /data/elastos/arbiter/keystore.dat arbiter_keystore.dat
  cp /etc/elastos-metrics/params.env /data/elastos/metrics/conf/prometheus.yml /data/elastos/metrics/conf/alertmanager.yml .
fi

echo ""
echo "Downloading packages required for Elastos Supernode"
DEPS=( "elastos-ela" "elastos-did" "elastos-eth" "elastos-arbiter" "elastos-carrier-bootstrap" "elastos-metrics" )
VERSIONS=( "0.7.0-2" "0.2.0-2" "0.1.2-1" "0.2.1-1" "5.2.3-3" "1.4.0-1" )
'''
for i in "${!DEPS[@]}"
do 
  echo "Downloading ${DEPS[$i]} Version: ${VERSIONS[$i]}"
  wget https://github.com/noderators/elastos-supernode-setup/releases/download/${RELEASE}/${DEPS[$i]}_${VERSIONS[$i]}.deb
  dpkg -s ${DEPS[$i]} | grep Version | grep ${VERSIONS[$i]}
  if [ $(echo $?) -ne "0" ]
  then 
    echo "Installing ${DEPS[$i]} Version: ${VERSIONS[$i]}"
    dpkg -i --force-confmiss "${DEPS[$i]}_${VERSIONS[$i]}.deb"
    apt-get install -f
  else  
    echo "${DEPS[$i]} is already the latest version with Version: ${VERSIONS[$i]}"
  fi
done
'''

DEB_DIRECTORY="/home/kpachhai/repos/github.com/noderators/elastos-supernode-setup"
dpkg -i --force-confmiss ${DEB_DIRECTORY}/ela/elastos-ela_0.7.0-2.deb
dpkg -i --force-confmiss ${DEB_DIRECTORY}/did/elastos-did_0.2.0-2.deb
dpkg -i --force-confmiss ${DEB_DIRECTORY}/eth/elastos-eth_0.1.2-1.deb
dpkg -i --force-confmiss ${DEB_DIRECTORY}/arbiter/elastos-arbiter_0.2.1-1.deb
dpkg -i --force-confmiss ${DEB_DIRECTORY}/carrier/elastos-carrier-bootstrap_5.2.3-3.deb
dpkg -i --force-confmiss ${DEB_DIRECTORY}/metrics/elastos-metrics_1.4.0-1.deb

if [[ "${PREVIOUS_INSTALL}" != "yes" ]]
then
  # Let's backup these files just in case the user does not want to change any settings with the new release
  cp /data/elastos/ela/keystore.dat mainchain_keystore.dat
  cp /data/elastos/ela/config.json mainchain_config.json 
  cp /data/elastos/did/config.json did_config.json 
  cp /data/elastos/eth/keystore.dat eth_keystore.dat
  cp /data/elastos/eth/data/keystore/miner-keystore.dat eth_miner_keystore.dat 
  cp /data/elastos/arbiter/keystore.dat arbiter_keystore.dat
  cp /etc/elastos-metrics/params.env /data/elastos/metrics/conf/prometheus.yml /data/elastos/metrics/conf/alertmanager.yml .
fi

echo ""
echo "Personalizing your Elastos Supernode setup"
read -p "WARNING! You're trying to create a new wallet. This may replace your previous wallet if it exists already. Proceed? [y/N] " answer
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
  cp eth_keystore.dat /data/elastos/eth/keystore.dat
  cp arbiter_keystore.dat /data/elastos/arbiter/keystore.dat
fi
chmod 644 /data/elastos/ela/keystore.dat

echo ""
echo "Modifying the config file parameters for ELA mainchain node"
cat <<< $(jq ".Configuration.DPoSConfiguration.IPAddress = \"$(curl ifconfig.me)\"" /data/elastos/ela/config.json) > /data/elastos/ela/config.json
read -p "Would you like to change the current username and password for RPC configuration for this node? [y/N] " answer
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter the username for RPC configuration: " usr
  read -p "Enter the password for RPC configuration: " pswd
else 
  usr=$(cat mainchain_config.json | jq -r ".Configuration.RpcConfiguration.User")
  pswd=$(cat mainchain_config.json | jq -r ".Configuration.RpcConfiguration.Pass")
fi
cat <<< $(jq ".Configuration.RpcConfiguration.User = \"${usr}\"" /data/elastos/ela/config.json) > /data/elastos/ela/config.json
cat <<< $(jq ".Configuration.RpcConfiguration.Pass = \"${pswd}\"" /data/elastos/ela/config.json) > /data/elastos/ela/config.json
cat <<< $(jq ".Configuration.MainNode.Rpc.User = \"${usr}\"" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json
cat <<< $(jq ".Configuration.MainNode.Rpc.Pass = \"${pswd}\"" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json

echo ""
echo "Modifying the config file parameters for DID sidechain node"
read -p "Would you like to change the current username and password for RPC configuration for this node? [y/N] " answer
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter the username for RPC configuration: " usr
  read -p "Enter the password for RPC configuration: " pswd
else 
  usr=$(cat did_config.json | jq -r ".RPCUser")
  pswd=$(cat did_config.json | jq -r ".RPCPass")
fi
cat <<< $(jq ".RPCUser = \"${usr}\"" /data/elastos/did/config.json) > /data/elastos/did/config.json
cat <<< $(jq ".RPCPass = \"${pswd}\"" /data/elastos/did/config.json) > /data/elastos/did/config.json
cat <<< $(jq ".Configuration.SideNodeList[0].Rpc.User = \"${usr}\"" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json
cat <<< $(jq ".Configuration.SideNodeList[0].Rpc.Pass = \"${pswd}\"" /data/elastos/arbiter/config.json) > /data/elastos/arbiter/config.json

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
unlock_address=$(echo 0x$(cat /data/elastos/eth/data/keystore/miner-keystore.dat | jq -r .address))
sed -i "s#UNLOCK_ADDRESS=.*#UNLOCK_ADDRESS=\"${unlock_address}\"#g" /etc/elastos-eth/params.env
ipaddress=$(curl ifconfig.me)
sed -i "s#IPADDRESS=.*#IPADDRESS=\"${ipaddress}\"#g" /etc/elastos-eth/params.env
cd /data/elastos/eth/oracle
npm install
cd ${MYTMPDIR}

pswd=$(cat /etc/elastos-ela/params.env | grep KEYSTORE_PASSWORD | sed 's#.*KEYSTORE_PASSWORD=##g' | sed 's#"##g')
cp /data/elastos/arbiter/keystore.dat .
NUM_WALLETS=$(elastos-ela-cli wallet a -p ${pswd} | grep - | wc -l)
NUM_WALLETS=$(expr ${NUM_WALLETS} - 1)
if [ "${NUM_WALLETS}" -lt "2" ]
then
  echo ""
  echo "Creating a secondary account for Arbiter node that will be used for did block generation"
  chown $USER:$USER keystore.dat
  /usr/local/bin/elastos-ela-cli wallet add -p ${pswd}
  cp keystore.dat /data/elastos/arbiter/keystore.dat
  chown elauser:elauser /data/elastos/arbiter/keystore.dat 
fi
chmod 644 /data/elastos/arbiter/keystore.dat

echo ""
echo "Modifying the config file parameters for Carrier Bootstrap node"
sed -i "s#// external_ip.*#external_ip = \"$(curl ifconfig.me)\"#g" /data/elastos/carrier/bootstrap.conf

echo ""
echo "Modifying the config file parameters for Metrics node"
read -p "Would you like to change the current settings for metrics endpoint? [y/N] " answer 
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter the port to be used for exposing your supernode metrics: " port
  read -p "Enter the username to be used for exposing your supernode metrics: " usr
  read -p "Enter the password to be used for exposing your supernode metrics: " pswd
else 
  port=$(cat params.env | grep PORT | sed 's#.*PORT=##g' | sed 's#"##g')
  usr=$(cat params.env | grep AUTH_USER | sed 's#.*AUTH_USER=##g' | sed 's#"##g')
  pswd=$(cat params.env | grep AUTH_PASSWORD | sed 's#.*AUTH_PASSWORD=##g' | sed 's#"##g')
fi 
sed -i "s#PORT=.*#PORT=\"${port}\"#g" /etc/elastos-metrics/params.env
sed -i "s#AUTH_USER=.*#AUTH_USER=\"${usr}\"#g" /etc/elastos-metrics/params.env
sed -i "s#AUTH_PASSWORD=.*#AUTH_PASSWORD=\"${pswd}\"#g" /etc/elastos-metrics/params.env

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
sed -i "s#smtp_smarthost:.*#smtp_smarthost: \"${smtp_smarthost}\"#g" /data/elastos/metrics/conf/alertmanager.yml
sed -i "s#smtp_from:.*#smtp_from: \"${smtp_from}\"#g" /data/elastos/metrics/conf/alertmanager.yml
sed -i "s#smtp_auth_username:.*#smtp_auth_username: \"${smtp_auth_username}\"#g" /data/elastos/metrics/conf/alertmanager.yml
sed -i "s#smtp_auth_password:.*#smtp_auth_password: \"${smtp_auth_password}\"#g" /data/elastos/metrics/conf/alertmanager.yml
sed -i "s#to:.*#to: \"${smtp_to}\"#g" /data/elastos/metrics/conf/alertmanager.yml

echo ""
echo "Starting up all the services required for running the supernode"
systemctl restart elastos-ela elastos-did elastos-eth elastos-eth-oracle elastos-arbiter elastos-carrier-bootstrap elastos-metrics prometheus prometheus-node-exporter prometheus-pushgateway prometheus-alertmanager

# systemctl stop elastos-ela elastos-did elastos-eth elastos-eth-oracle elastos-arbiter elastos-carrier-bootstrap elastos-metrics prometheus prometheus-node-exporter prometheus-pushgateway prometheus-alertmanager; apt-get purge "elastos-ela" "elastos-did" "elastos-eth" "elastos-arbiter" "elastos-carrier-bootstrap" "elastos-metrics" -y; rm -rf /data/elastos /etc/elastos-*

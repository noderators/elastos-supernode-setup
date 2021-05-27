#!/usr/bin/env bash

MYTMPDIR="$(mktemp -d)"
trap 'rm -rf -- "$MYTMPDIR"' EXIT
cd ${MYTMPDIR}

RELEASE="v1.24"

echo "Updating the system packages"
sudo apt-get update -y 
echo "Installing dependencies if not installed"
DEPS=( "wget" "jq" "python3" "prometheus" "prometheus-node-exporter" "prometheus-pushgateway" "prometheus-alertmanager" )
for dep in "${DEPS[@]}"
do
  dpkg -s ${dep} >/dev/null 2>&1
  if [ $(echo $?) -ne "0" ]
  then 
    sudo apt-get install ${dep} -y
  fi
done

# Let's backup these files just in case the user does not want to change any settings with the new release
sudo cp /data/elastos/ela/config.json mainchain_config.json 
sudo cp /data/elastos/ela/keystore.dat mainchain_keystore.dat
sudo cp /data/elastos/arbiter/keystore.dat arbiter_keystore.dat
sudo cp /data/elastos/did/config.json did_config.json 
sudo cp /etc/elastos-metrics/params.env /data/elastos/metrics/conf/prometheus.yml /data/elastos/metrics/conf/alertmanager.yml .

echo ""
echo "Downloading packages required for Elastos Supernode"
DEPS=( "elastos-ela" "elastos-did" "elastos-arbiter" "elastos-carrier-bootstrap" "elastos-metrics" )
VERSIONS=( "0.7.0-2" "0.2.0-2" "0.2.1-1" "5.2.3-3" "1.4.0-1" )
'''
for i in "${!DEPS[@]}"
do 
  echo "Downloading ${DEPS[$i]} Version: ${VERSIONS[$i]}"
  wget https://github.com/noderators/elastos-supernode-setup/releases/download/${RELEASE}/${DEPS[$i]}_${VERSIONS[$i]}.deb
  dpkg -s ${DEPS[$i]} | grep Version | grep ${VERSIONS[$i]}
  if [ $(echo $?) -ne "0" ]
  then 
    echo "Installing ${DEPS[$i]} Version: ${VERSIONS[$i]}"
    sudo dpkg -i --force-confmiss "${DEPS[$i]}_${VERSIONS[$i]}.deb"
    sudo apt-get install -f
  else  
    echo "${DEPS[$i]} is already the latest version with Version: ${VERSIONS[$i]}"
  fi
done
'''

DEB_DIRECTORY="/home/kpachhai/repos/github.com/noderators/elastos-supernode-setup"
sudo dpkg -i --force-confmiss ${DEB_DIRECTORY}/ela/elastos-ela_0.7.0-2.deb
sudo dpkg -i --force-confmiss ${DEB_DIRECTORY}/did/elastos-did_0.2.0-2.deb
sudo dpkg -i --force-confmiss ${DEB_DIRECTORY}/arbiter/elastos-arbiter_0.2.1-1.deb
sudo dpkg -i --force-confmiss ${DEB_DIRECTORY}/carrier/elastos-carrier-bootstrap_5.2.3-3.deb
sudo dpkg -i --force-confmiss ${DEB_DIRECTORY}/metrics/elastos-metrics_1.4.0-1.deb


echo ""
echo "Personalizing your Elastos Supernode setup"
read -p "WARNING! You're trying to create a new wallet. This may replace your previous wallet if it exists already. Proceed? [y/N] " answer
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then 
  sudo rm -f /data/elastos/ela/keystore.dat 
  read -p "Enter the password for your keystore.dat: " pswd
  echo "Creating a wallet with the given password"
  /usr/local/bin/elastos-ela-cli wallet create -p ${pswd}
  sudo mv keystore.dat /data/elastos/ela/keystore.dat
  sudo chown elauser:elauser /data/elastos/ela/keystore.dat 
  sudo cp /data/elastos/ela/keystore.dat /data/elastos/arbiter/keystore.dat
  sudo sed -i "s#KEYSTORE_PASSWORD=.*#KEYSTORE_PASSWORD=\"${pswd}\"#g" /etc/elastos-ela/params.env
else 
  sudo cp mainchain_keystore.dat /data/elastos/ela/keystore.dat
  sudo cp arbiter_keystore.dat /data/elastos/arbiter/keystore.dat
fi

echo ""
echo "Modifying the config file parameters for ELA mainchain node"
sudo sed -i "s#\"IPAddress\":.*#\"IPAddress\": \"$(curl ifconfig.me)\"#g" /data/elastos/ela/config.json
read -p "Would you like to change the current username and password for RPC configuration for this node? [y/N] " answer
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter the username for RPC configuration: " usr
  read -p "Enter the password for RPC configuration: " pswd
else 
  usr=$(cat mainchain_config.json | grep User | sed 's#.*User": ##g' | sed 's#"##g')
  pswd=$(cat mainchain_config.json | grep Pass | sed 's#.*Pass": ##g' | sed 's#"##g')
fi
sudo sed -i "s#\"User\":.*#\"User\": \"${usr}\"#g" /data/elastos/ela/config.json
sudo sed -i "s#\"Pass\":.*#\"Pass\": \"${pswd}\"#g" /data/elastos/ela/config.json 
sudo sed -i "s#\"mainchain_rpc_user\"#${usr}#g" /data/elastos/arbiter/config.json
sudo sed -i "s#\"mainchain_rpc_pass\"#${pswd}#g" /data/elastos/arbiter/config.json

echo ""
echo "Modifying the config file parameters for DID sidechain node"
read -p "Would you like to change the current username and password for RPC configuration for this node? [y/N] " answer
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter the username for RPC configuration: " usr
  read -p "Enter the password for RPC configuration: " pswd
else 
  usr=$(cat did_config.json | grep RPCUser | sed 's#.*RPCUser": ##g' | sed 's#"##g')
  pswd=$(cat did_config.json | grep RPCPass | sed 's#.*RPCPass": ##g' | sed 's#"##g')
fi
sudo sed -i "s#\"RPCUser\":.*#\"RPCUser\": \"${usr}\"#g" /data/elastos/did/config.json
sudo sed -i "s#\"RPCPass\":.*#\"RPCPass\": \"${pswd}\"#g" /data/elastos/did/config.json
sudo sed -i "s#\"did_rpc_user\"#${usr}#g" /data/elastos/arbiter/config.json
sudo sed -i "s#\"did_rpc_pass\"#${pswd}#g" /data/elastos/arbiter/config.json

pswd=$(cat /etc/elastos-ela/params.env | grep KEYSTORE_PASSWORD | sed 's#.*KEYSTORE_PASSWORD=##g' | sed 's#"##g')
sudo cp /data/elastos/arbiter/keystore.dat .
NUM_WALLETS=$(sudo elastos-ela-cli wallet a -p ${pswd} | grep - | wc -l)
NUM_WALLETS=$(expr ${NUM_WALLETS} - 1)
if [ "${NUM_WALLETS}" -lt "2" ]
then
  echo ""
  echo "Creating a secondary account for Arbiter node that will be used for did block generation"
  sudo chown $USER:$USER keystore.dat
  /usr/local/bin/elastos-ela-cli wallet add -p ${pswd}
  sudo cp keystore.dat /data/elastos/arbiter/keystore.dat
  sudo chown elauser:elauser /data/elastos/arbiter/keystore.dat 
fi

echo ""
echo "Modifying the config file parameters for Carrier Bootstrap node"
sudo sed -i "s#// external_ip.*#external_ip = \"$(curl ifconfig.me)\"#g" /data/elastos/carrier/bootstrap.conf

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
sudo sed -i "s#PORT=.*#PORT=\"${port}\"#g" /etc/elastos-metrics/params.env
sudo sed -i "s#AUTH_USER=.*#AUTH_USER=\"${usr}\"#g" /etc/elastos-metrics/params.env
sudo sed -i "s#AUTH_PASSWORD=.*#AUTH_PASSWORD=\"${pswd}\"#g" /etc/elastos-metrics/params.env

echo ""
echo "Modifying the config file parameters for Prometheus and Alertmanager"
read -p "Would you like to change your supernode name for Prometheus configuration? [y/N] " answer 
if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]] || [[ "${answer}" == "yes" ]]
then
  read -p "Enter the name of your supernode: " supernodeName
else 
  supernodeName=$(cat prometheus.yml | grep replacement | sed 's#.*replacement: ##g' | sed 's#"##g')
fi 
sudo sed -i "s#replacement:.*#replacement: \"${supernodeName}:9100\"#g" /data/elastos/metrics/conf/prometheus.yml
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
sudo sed -i "s#smtp_smarthost:.*#smtp_smarthost: \"${smtp_smarthost}\"#g" /data/elastos/metrics/conf/alertmanager.yml
sudo sed -i "s#smtp_from:.*#smtp_from: \"${smtp_from}\"#g" /data/elastos/metrics/conf/alertmanager.yml
sudo sed -i "s#smtp_auth_username:.*#smtp_auth_username: \"${smtp_auth_username}\"#g" /data/elastos/metrics/conf/alertmanager.yml
sudo sed -i "s#smtp_auth_password:.*#smtp_auth_password: \"${smtp_auth_password}\"#g" /data/elastos/metrics/conf/alertmanager.yml
sudo sed -i "s#to:.*#to: \"${smtp_to}\"#g" /data/elastos/metrics/conf/alertmanager.yml

echo ""
echo "Starting up all the services required for running the supernode"
sudo systemctl restart elastos-ela elastos-did elastos-arbiter elastos-carrier-bootstrap elastos-metrics prometheus prometheus-node-exporter prometheus-pushgateway prometheus-alertmanager

# sudo systemctl stop elastos-ela elastos-did elastos-arbiter elastos-carrier-bootstrap elastos-metrics prometheus prometheus-node-exporter prometheus-pushgateway prometheus-alertmanager; sudo apt-get purge "elastos-ela" "elastos-did" "elastos-arbiter" "elastos-carrier-bootstrap" "elastos-metrics" -y; sudo rm -rf /data/elastos /etc/elastos-*
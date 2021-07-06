## Pre-requisites for running the supernode

- Ubuntu Server 18.04 LTS

## How to setup and run an Elastos supernode

```
sudo ./setup.sh
```

## Open up the required ports on your firewall configuration

```
ELA Mainchain - [TCP:20338,20339]
Elastos Smart Contract(ESC) Sidechain - [TCP:20639,20638, UDP:20638]
Elastos ID(EID) Sidechain - [TCP:20649,20648, UDP:20648]
Elastos Arbiter - [TCP:20538]
Elastos Carrier - [TCP:33445, UDP:3478,33445]
```

## Change additional configs(OPTIONAL)

- If you want to enable REST API Port on your ELA mainchain node, update /data/elastos/ela/config.json and do the following:

  - Add `"HttpRestStart": true,` inside `"Configuration"` object
  - Add `"HttpRestPort": 20334,` where `"20334"` is the port of your choosing

- If you want to enable REST API Port on your DID sidechain node, update /data/elastos/did/config.json and do the following:

  - Add `"EnableREST": true,`
  - Add `"RESTPort": 20604` where `"20604"` is the port of your choosing

- Once you change any config, make sure to restart the appropriate service
  ```
  sudo systemctl restart elastos-ela
  sudo systemctl restart elastos-did
  ```

## Verify whether the supernode has started running

- Check current height for Elastos mainchain node

  ```
  port=$(cat /data/elastos/ela/config.json | jq -r ".Configuration.HttpJsonPort")
  usr=$(cat /data/elastos/ela/config.json | jq -r ".Configuration.RpcConfiguration.User")
  pswd=$(cat /data/elastos/ela/config.json | jq -r ".Configuration.RpcConfiguration.Pass")
  height=$(curl -X POST --user ${usr}:${pswd} http://localhost:${port} -H 'Content-Type: application/json' -d '{"method":"getnodestate"}' | jq ".result.height")
  echo ${height}
  ```

- Check current height for Elastos ID(EID) sidechain node

  ```
  port=$(cat /etc/elastos-eid/params.env | grep RPCPORT | sed 's#.*RPCPORT=##g' | sed 's#"##g')
  height=$(curl -X POST http://localhost:${port} -H 'Content-Type: application/json' -d '{"method":"eth_blockNumber", "id":1}' | jq -r ".result")
  echo ${height}
  ```

- Check current height for Elastos Smart Contract(ESC) sidechain node
  ```
  port=$(cat /etc/elastos-eth/params.env | grep RPCPORT | sed 's#.*RPCPORT=##g' | sed 's#"##g')
  height=$(curl -X POST http://localhost:${port} -H 'Content-Type: application/json' -d '{"method":"eth_blockNumber", "id":1}' | jq -r ".result")
  echo ${height}
  ```

## Miscellaneous

### How to set up an smtp server to be used for setting up alerts within Alertmanager

- Option 1: You can install postfix by following the directions at [https://hostadvice.com/how-to/how-to-setup-postfix-as-send-only-mail-server-on-an-ubuntu-18-04-dedicated-server-or-vps/](https://hostadvice.com/how-to/how-to-setup-postfix-as-send-only-mail-server-on-an-ubuntu-18-04-dedicated-server-or-vps/)
- Option 2: If you're using AWS, you can use AWS SES service to set up a SMTP server for free
  1.  Follow the directions at [https://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-email-addresses.html](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-email-addresses.html) to first verify your email
  2.  Go to [https://console.aws.amazon.com/ses/](https://console.aws.amazon.com/ses/)
  3.  In the navigation pane on the left side of the Amazon SES console, under **Identity Management**, choose **Email Addresses** to view the email address that you verified from step 1
  4.  In the list of identities, check the box next to email address that you have verified
  5.  Choose **Send a Test Email** to send a test email so you know it works correctly
  6.  In the navigation pane, choose **SMTP Settings**
  7.  In the content pane, choose **Create My SMTP Credentials**
  8.  For **Create User for SMTP**, type a name for your SMTP user. Alternatively, you can use the default value that is provided in this field. When you finish, choose **Create**
  9.  Choose **Show User SMTP Credentials**. Your SMTP credentials are shown on the screen. Copy these credentials and store them in a safe place. You can also choose **Download Credentials** to download a file that contains your credentials.

## What to do in case your supernode becomes inactive

- In case your mainchain node becomes inactive for whatever reason, please do the following to move to active status again
  ```bash
  cd /data/elastos/ela;
  sudo su;
  keystore_pswd=$(cat /etc/elastos-ela/params.env | grep KEYSTORE_PASSWORD | sed 's#.*KEYSTORE_PASSWORD=##g' | sed 's#"##g')
  rpc_port=$(cat /data/elastos/ela/config.json | jq -r ".Configuration.HttpJsonPort")
  rpc_user=$(cat /data/elastos/ela/config.json | jq -r ".Configuration.RpcConfiguration.User")
  rpc_pswd=$(cat /data/elastos/ela/config.json | jq -r ".Configuration.RpcConfiguration.Pass")
  node_key=$(elastos-ela-cli wallet a -p ${keystore_pswd} | tail -2 | head -1 | cut -d' ' -f2);
  elastos-ela-cli wallet buildtx activate --nodepublickey ${node_key} -p ${keystore_pswd};
  elastos-ela-cli wallet sendtx -f ready_to_send.txn --rpcuser ${rpc_user} --rpcpassword ${rpc_pswd} --rpcport ${rpc_port};
  rm -f ready_to_send.txn
  ```

## Check your metrics

- Check the metrics that's being scraped through prometheus-node-exporter service
  ```
  curl http://localhost:9100/metrics | grep elastos-
  ```
- You can also check other metrics. Visit [https://github.com/prometheus/node_exporter](https://github.com/prometheus/node_exporter) for more info
- With node exporter, metrics about your server is exposed. Some of them include:

  ```
  curl http://localhost:9100/metrics | grep node_filesystem_size | grep "/data"
  ```

  Should return the total size of your /data directory where all the supernode blockchain data is stored

  ```
  curl http://localhost:9100/metrics | grep node_filesystem_free | grep "/data"
  ```

  Should return the available size of your /data directory so you can expand your volume when it's about to be full.

- By default, elastos-metrics is running on port 5000 so what it does is expose all the node-exporter metrics to an API port and in JSON format so you can use this in your own applications to gather statistics about your supernode
  ```
  curl --user user:password http://localhost:5000/elastosmetrics
  ```

## Upgrade instructions

- Whenever there is a new package available, you need to download the latest `setup.sh` file from this repo and then run it like so:
  ```
  sudo ./setup.sh
  ```
- Any time you restart an instance, you're stopping the node for main chain, did sidechain, smart contract sidehchain, etc and then starting them again. You should also make sure to not upgrade elastos-ela without first making sure that your supernode is not currently in queue to submit a block proposal. You can check when your supernode will be proposing a block next by going to [https://www.noderators.org/arbitratorsonduty/](https://www.noderators.org/arbitratorsonduty/)
- You can also check for this using your command line by doing the following
  ```bash
  port=$(cat /data/elastos/ela/config.json | jq -r ".Configuration.HttpJsonPort")
  usr=$(cat /data/elastos/ela/config.json | jq -r ".Configuration.RpcConfiguration.User")
  pswd=$(cat /data/elastos/ela/config.json | jq -r ".Configuration.RpcConfiguration.Pass")
  curl --user ${usr}:${pswd} -H 'Content-Type: application/json' -H 'Accept:application/json' --data '{"method":"getarbitersinfo"}' http://localhost:${port}
  ```
  Should return the current onduty supernode(arbiter) and the next list of supernodes in queue to submit block proposals every block(~2 minutes)

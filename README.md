## Pre-requisites for running the supernode

- Ubuntu Server 18.04 LTS

## How to setup and run an Elastos supernode

```
sudo ./setup.sh
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

## Debugging

- In case your mainchain node becomes inactive for whatever reason, please do the following to move to active status again
  ```bash
  cd /data/elastos/ela;
  sudo su;
  # Replace 'todo_keystore_password' with your own password for your keystore.dat file. You can find this at /etc/elastos-ela/params.env
  KEYSTORE_PASSWORD='todo_keystore_password';
  # Replace 'todo_rpc_user' with your own RPC username for your ELA mainchain node. You can find this at /data/elastos/ela/config.json
  RPCUSERNAME='todo_rpc_user';
  # Replace 'todo_rpc_pass' with your own RPC password for your ELA mainchain node. You can find this at /data/elastos/ela/config.json
  RPCPASSWORD='todo_rpc_pass';
  NODEKEY=$(elastos-ela-cli wallet a -p ${KEYSTORE_PASSWORD} | tail -2 | head -1 | cut -d' ' -f2);
  elastos-ela-cli wallet buildtx activate --nodepublickey ${NODEKEY} -p ${KEYSTORE_PASSWORD};
  elastos-ela-cli wallet sendtx -f ready_to_send.txn --rpcuser ${RPCUSERNAME} --rpcpassword ${RPCPASSWORD};
  rm -f ready_to_send.txn
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
  # Replace 'todo_rpc_user' and 'todo_rpc_password' with your own RPC username and password. You can find this at /data/elastos/ela/config.json
  curl --user todo_rpc_user:todo_rpc_password -H 'Content-Type: application/json' -H 'Accept:application/json' --data '{"method":"getarbitersinfo"}' http://localhost:20336
  ```
  Should return the current onduty supernode(arbiter) and the next list of supernodes in queue to submit block proposals every block(~2 minutes)

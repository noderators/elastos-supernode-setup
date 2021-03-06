## Pre-requisites for running the supernode
- Ubuntu Server 18.04 LTS

## Pre-requisites for building the packages yourself
- Docker(if you want to build the .deb packages)

## How to build and install everything yourself(the hard way)
1. Build the .deb packages on your ubuntu machine
    ```
    docker build -t deb-builder:18.04 -f tools/ubuntu-18.04.Dockerfile .;
    docker run -it -w /elastos-supernode-setup -v /Users/kpachhai/dev/src/github.com/noderators/elastos-supernode-setup:/elastos-supernode-setup -e USER=501 -e GROUP=20 --rm deb-builder:18.04 /elastos-supernode-setup/tools/build_packages.sh
    ```

2. Install the packages
    ```
    sudo dpkg -i --force-confmiss ela/elastos-ela_0.6.0-1.deb did/elastos-did_0.2.0-1.deb token/elastos-token_0.1.2-3.deb carrier/elastos-carrier-bootstrap_5.2.3-2.deb metrics/elastos-metrics_1.2.1-1.deb;
    sudo apt-get install -f
    ```

## How to download and install the packages(the easy way)
1. Go to releases at [https://github.com/noderators/elastos-supernode-setup/releases](https://github.com/noderators/elastos-supernode-setup/releases)

2. Download all the deb packages

3. Install the packages
    ```
    sudo apt-get install prometheus prometheus-node-exporter prometheus-pushgateway prometheus-alertmanager jq python3;
    sudo dpkg -i --force-confmiss elastos-ela_0.6.0-1.deb elastos-did_0.2.0-1.deb elastos-token_0.1.2-3.deb elastos-carrier-bootstrap_5.2.3-2.deb elastos-metrics_1.2.1-1.deb;
    sudo apt-get install -f
    ```

## Change configs
1. Replace /data/elastos/ela/keystore.dat with your own keystore.dat
    ```
    rm -f /data/elastos/ela/keystore.dat;
    /usr/local/bin/elastos-ela-cli wallet create -p $YOURPASSWORDHERE
    cp keystore.dat /data/elastos/ela/keystore.dat
    sudo chown elauser:elauser /data/elastos/ela/keystore.dat
    ```

2. Update /data/elastos/ela/config.json
    - Change "IPAddress" to your own public IP address
    - Change "User" to your own username you want to set
    - Change "Pass" to your own password you want to set
    - Change "HttpJsonPort" to the port of your choosing
    - If you want to enable REST API Port, add 
        ```"HttpRestStart": true,```
    - Change "HttpRestPort" to the port of your choosing

3. Update /etc/elastos-ela/params.env
    - Change "KEYSTORE_PASSWORD" to your own keystore password you set above(whatever $YOURPASSWORDHERE is)

4. Update /data/elastos/did/config.json
    - Change "RPCUser" to your own username you want to set
    - Change "RPCPass" to your own username you want to set
    - Change "RPCPort" to the port of your choosing
    - If you want to enable REST API Port, add 
        ```"EnableREST": true,```
    - Change "RESTPort" to the port of your choosing

5. Update /data/elastos/token/config.json
    - Change "RPCUser" to your own username you want to set
    - Change "RPCPass" to your own username you want to set
    - Change "RPCPort" to the port of your choosing
    - If you want to enable REST API Port, add 
        ```"EnableREST": true,```
    - Change "RESTPort" to the port of your choosing

6. Update /data/elastos/carrier/bootstrap.conf
    - Change "external_ip" to your own public IP address. Make sure to remove the 2 backslashes "//" from the line too

7. Update /etc/elastos-metrics/params.env
    - Change "PORT", "AUTH_USER" and "AUTH_PASSWORD" to your own choosing

8. Update /data/elastos/metrics/conf/prometheus.yml
    - Right above the line with "metric_relabel_configs:", add the following:
        ```
        relabel_configs:
          - source_labels: [__address__]
            regex:  '.*'
            target_label: instance
            replacement: '$YOURNODENAME:9100'
        ```
        Make sure to replace $YOURNODENAME with your own supernode name. Every time email is sent, it'll have this label. This comes in handy if you're running multiple supernodes

9. Set up an smtp server
    - Option 1: You can install postfix by following the directions at [https://hostadvice.com/how-to/how-to-setup-postfix-as-send-only-mail-server-on-an-ubuntu-18-04-dedicated-server-or-vps/](https://hostadvice.com/how-to/how-to-setup-postfix-as-send-only-mail-server-on-an-ubuntu-18-04-dedicated-server-or-vps/)
    - Option 2: If you're using AWS, you can use AWS SES service to set up a SMTP server for free
        1. Follow the directions at [https://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-email-addresses.html](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-email-addresses.html) to first verify your email
        2. Go to [https://console.aws.amazon.com/ses/](https://console.aws.amazon.com/ses/)
        3. In the navigation pane on the left side of the Amazon SES console, under **Identity Management**, choose **Email Addresses** to view the email address that you verified from step 1
        4. In the list of identities, check the box next to email address that you have verified
        5. Choose **Send a Test Email** to send a test email so you know it works correctly
        6. In the navigation pane, choose **SMTP Settings**
        7. In the content pane, choose **Create My SMTP Credentials**
        8. For **Create User for SMTP**, type a name for your SMTP user. Alternatively, you can use the default value that is provided in this field. When you finish, choose **Create**
        9. Choose **Show User SMTP Credentials**. Your SMTP credentials are shown on the screen. Copy these credentials and store them in a safe place. You can also choose **Download Credentials** to download a file that contains your credentials.
    - Update /data/elastos/metrics/conf/alertmanager.yml and change the values for "smtp_smarthost", "smtp_from", "smtp_auth_username" and "smtp_auth_password" to your own setting

10. Now, start up your services
    ```
    sudo systemctl restart elastos-ela elastos-did elastos-token elastos-carrier-bootstrap elastos-metrics prometheus prometheus-node-exporter prometheus-pushgateway prometheus-alertmanager
    ``` 

11. In case your mainchain node becomes inactive for whatever reason, please do the following to move to active status again
    ```
    cd /data/elastos/ela;
    sudo su;
    KEYSTORE_PASSWORD='YOUROWNKEYSTOREPASSWORDHERE';
    RPCUSERNAME='YOURRPCUSERNAMEHERE';
    RPCPASSWORD='YOURRPCPASSHERE';
    YOURNODEKEY=$(elastos-ela-cli wallet a -p $KEYSTORE_PASSWORD | tail -2 | head -1 | cut -d' ' -f2);
    elastos-ela-cli wallet buildtx activate --nodepublickey $YOURNODEKEY -p $KEYSTORE_PASSWORD;
    elastos-ela-cli wallet sendtx -f ready_to_send.txn --rpcuser $RPCUSERNAME --rpcpassword $RPCPASSWORD;
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
- Whenever there is a new package available, you need to upgrade your package on your machine to receive the latest apps so follow the instructions on the releases page at [https://github.com/noderators/elastos-supernode-setup/releases](https://github.com/noderators/elastos-supernode-setup/releases) 
- Any time you restart an instance, you're stopping the node for main chain, did sidechain, token sidehchain, etc and then starting them again. You should also make sure to not upgrade elastos-ela without first making sure that your supernode is not currently in queue to submit a block proposal. You can check when your supernode will be proposing a block next by going to [https://www.noderators.org/arbitratorsonduty/](https://www.noderators.org/arbitratorsonduty/)
- You can also check for this using your command line by doing the following
    ```
    curl --user user:password -H 'Content-Type: application/json' -H 'Accept:application/json' --data '{"method":"getarbitersinfo"}' http://localhost:20336
    ```
    Should return the current onduty supernode(arbiter) and the next list of supernodes in queue to submit block proposals every block(~2 minutes)

## Roadmap for this repository
- Support redhat/centos machines by putting out rpm packages in addition to deb packages
- Create a grafana dashboard for your supernode using elastos-metrics package


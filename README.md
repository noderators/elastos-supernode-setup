## Pre-requisites
- Ubuntu Server 18.04 LTS
- Docker(if you want to build the .deb packages)

## How to build and install everything yourself(the hard way)
1. Build the .deb packages on your ubuntu machine
    ```
    docker build -t deb-builder:18.04 -f tools/Dockerfile-ubuntu-18.04 .;
    docker run -it -w /elastos-supernode-setup -v /Users/kpachhai/dev/src/github.com/noderators/elastos-supernode-setup:/elastos-supernode-setup -e USER=501 -e GROUP=20 --rm deb-builder:18.04 /elastos-supernode-setup/tools/build_packages.sh
    ```

2. Install the packages
    ```
    sudo dpkg -i ela/elastos-ela_0.3.2-2.deb did/elastos-did_0.1.2-2.deb token/elastos-token_0.1.2-2.deb carrier/elastos-carrier-bootstrap_5.2.3-2.deb metrics/elastos-metrics_1.0.0-1.deb;
    sudo apt-get install -f
    ```

## How to download and install the packages(the easy way)
1. Go to releases at [https://github.com/noderators/elastos-supernode-setup/releases](https://github.com/noderators/elastos-supernode-setup/releases)

2. Download all the deb packages

3. Install the packages
    ```
    sudo dpkg -i elastos-carrier-bootstrap_5.2.3-2.deb elastos-did_0.1.2-2.deb elastos-ela_0.3.2-2.deb elastos-token_0.1.2-2.deb elastos-metrics_1.0.0-1.deb;
    sudo apt-get install -f
    ```

## Change configs
1. Replace /data/elastos/ela/keystore.dat with your own keystore.dat
    ```
    /usr/local/bin/elastos-ela-cli wallet create -p $YOURPASSWORDHERE
    cp keystore.dat /data/elastos/ela/keystore.dat
    sudo chown elauser:elauser /data/elastos/ela/keystore.dat
    ```

2. Update /data/elastos/ela/config.json
    - Change "IPAddress" to your own public IP address
    - Change "User" to your own username you want to set
    - Change "Pass" to your own password you want to set

3. Update /etc/elastos-ela/params.env
    - Change "KEYSTORE_PASSWORD" to your own keystore password you set above(whatever $YOURPASSWORDHERE is)

4. Update /data/elastos/did/config.json
    - Change "RPCUser" to your own username you want to set
    - Change "RPCPass" to your own username you want to set

5. Update /data/elastos/token/config.json
    - Change "RPCUser" to your own username you want to set
    - Change "RPCPass" to your own username you want to set

6. Update /data/elastos/carrier/bootstrap.conf
    - Change "external_ip" to your own public IP address. Make sure to remove the 2 backslashes "//" from the line too

7. Once all the changes are in place, enable your services to start on boot
    ```
    sudo systemctl enable elastos-ela elastos-did elastos-token elastos-carrier-bootstrap
    ```

8. Now, start up your services
    ```
    sudo systemctl start elastos-ela elastos-did elastos-token elastos-carrier-bootstrap
    ```

## Upgrade instructions
Whenever there is a new package available, you need to upgrade your package on your machine to receive the latest apps so follow the instructions then:

1. Download the new releases by going to [https://github.com/noderators/elastos-supernode-setup/releases](https://github.com/noderators/elastos-supernode-setup/releases)

2. Install the latest package
    ```
    sudo dpkg -i package-name.deb
    ```

3. Go back to "Change configs" section above to re-modify all the config files that might have been updated

4. Restart the services
    ```
    sudo systemctl daemon-reload
    sudo systemctl restart elastos-ela elastos-did elastos-token elastos-carrier-bootstrap
    ```

## Roadmap for this repository
- Update the deb packages with metrics service so the daemons start producing meaningful metrics that can be used to watch over your supernodes 
- Update the deb packages so if the node goes down, it alerts via SMS or email

## Noderators - Jazz(US - Ohio)

## Noderators - Champagne(Europe - Frankfurt)

## Noderators - Watermelon(Asia - Mumbai)

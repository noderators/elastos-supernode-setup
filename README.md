## Pre-requisites
- Ubuntu Server 18.04 LTS

## How to install everything
1. Build the .deb packages on your ubuntu machine
    ```
    tools/build_packages.sh
    ```

2. Install elastos-ela
    ```
    sudo dpkg -i ela/*.deb
    ```

3. Install elastos-did
    ```
    sudo dpkg -i did/*.deb
    ```

4. Install elastos-token
    ```
    sudo dpkg -i token/*.deb
    ```

5. Install elastos-carrier-boostrap
    ```
    sudo dpkg -i carrier/*.deb
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
3. Update /data/elastos/did/config.json
    - Change "RPCUser" to your own username you want to set
    - Change "RPCPass" to your own username you want to set
4. Update /data/elastos/token/config.json
    - Change "RPCUser" to your own username you want to set
    - Change "RPCPass" to your own username you want to set
5. Update /data/elastos/carrier/bootstrap.conf
    - Change "external_ip" to your own public IP address. Make sure to remove the 2 backslashes "//" from the line too

## Upgrade instructions
1. Remove the previous package-name 
    ```
    sudo apt-get remove elastos-ela elastos-did elastos-token elastos-carrier-boostrap
    ```
2. Install the latest package
    ```
    sudo dpkg -i package-name.deb
    ```

## Roadmap for this repository
- Update the deb packages with metrics service so the daemons start producing meaningful metrics that can be used to watch over your supernodes 
- Update the deb packages so if the node goes down, it alerts via SMS or email

## Noderators - Jazz
- IP Address: 18.191.96.97
- Elastos Mainchain Node: 18.191.96.97:20338
- Elastos DID Sidechain Node: 18.191.96.97:20608
- Elastos Token Sidechain Node: 18.191.96.97:20618
- Elastos Carrier Bootstrap Node: 18.191.96.97:33445

## Noderators - Champagne


## Noderators - Watermelon
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from requests import Session

import subprocess
import json

HOST="127.0.0.1"
PARAMETERS = {}
HEADERS = {
    'Accepts': 'application/json',
    'Content-Type': 'application/json'
}

def main():
    session = Session()
    session.headers.update(HEADERS)

    # Main chain Node State
    rpcport, rpcuser, rpcpassword = getConfigs("/data/elastos/ela/config.json", chain="main")
    node_state = getNodeState(session, rpcport, rpcuser, rpcpassword)
    height = node_state["height"]
    node_version = node_state["compile"]
    services = node_state["services"]
    print(height, node_version, services)
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "a") as out:
        out.write(f'elastos_metrics_nodestate{{chain="main",height="{height}",nodeversion="{node_version}",services="{services}"}} 1\n')

    # DPoS Node Info
    nodekey = getNodeKeyFromKeystoreFile()
    producer = getProducerInfo(session, rpcport, rpcuser, rpcpassword, nodekey) 
    producer_ownerpublickey = producer["ownerpublickey"]
    producer_nodepublickey = producer["nodepublickey"]
    producer_nickname = producer["nickname"]
    #producer_url = producer["url"]
    #producer_location = producer["location"]
    #producer_active = producer["active"]
    #producer_votes = producer["votes"]
    producer_state = producer["state"]
    producer_registerheight = producer["registerheight"]
    producer_cancelheight = producer["cancelheight"]
    producer_inactiveheight = producer["inactiveheight"]
    producer_illegalheight = producer["illegalheight"]
    producer_rank = producer["index"] + 1
    print(producer_nickname, producer_rank, producer_ownerpublickey, producer_nodepublickey, producer_state, producer_registerheight, producer_cancelheight, producer_inactiveheight, producer_illegalheight)

    # DID Sidechain Node State
    rpcport, rpcuser, rpcpassword = getConfigs("/data/elastos/did/config.json", chain="did")
    node_state = getNodeState(session, rpcport, rpcuser, rpcpassword)
    height = node_state["height"]
    node_version = node_state["compile"]
    services = node_state["services"]
    print(height, node_version, services)
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "a") as out:
        out.write(f'elastos_metrics_nodestate{{chain="did",height="{height}",nodeversion="{node_version}",services="{services}"}} 1\n')

    # Token Sidechain Node State 
    rpcport, rpcuser, rpcpassword = getConfigs("/data/elastos/token/config.json", chain="token")
    node_state = getNodeState(session, rpcport, rpcuser, rpcpassword)
    height = node_state["height"]
    node_version = node_state["compile"]
    services = node_state["services"]
    print(height, node_version, services)
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "a") as out:
        out.write(f'elastos_metrics_nodestate{{chain="token",height="{height}",nodeversion="{node_version}",services="{services}"}} 1\n')

def getProducerInfo(session, rpcport, rpcuser, rpcpassword, nodekey):
    producer = {}
    url = "http://{0}:{1}".format(HOST, rpcport)
    d = {"method":"listproducers", "params": { "start": 0, "state": "all"}}
    response = session.post(url, data=json.dumps(d), auth=(rpcuser, rpcpassword))
    producers = json.loads(response.text)["result"]["producers"]
    for p in producers:
        if p["nodepublickey"] == nodekey:
            producer = p
            break
    return producer

def getNodeKeyFromKeystoreFile():
    env_vars = {}
    with open("/etc/elastos-ela/params.env", 'r') as f:
        for line in f:
            if line.startswith('#'):
                continue
            key, value = line.strip().split('=', 1)
            env_vars[key] = value
    keystore_pass = env_vars["KEYSTORE_PASSWORD"].replace('"', '', -1)
    cmd = ["/usr/local/bin/elastos-ela-cli", "wallet", "account", "-p", "{0}".format(keystore_pass)]
    keystore_cmd = subprocess.Popen(cmd, stdout=subprocess.PIPE, cwd="/data/elastos/ela")
    nodekey = keystore_cmd.communicate()[0].decode().replace("-", "", -1).split("\n")[2].split(" ")[1]
    return nodekey

def getNodeState(session, rpcport, rpcuser, rpcpassword):
    url = "http://{0}:{1}".format(HOST, rpcport)
    d = {"method":"getnodestate"}
    response = session.post(url, data=json.dumps(d), auth=(rpcuser, rpcpassword))
    data = json.loads(response.text)["result"]
    return data

def getConfigs(config_file, chain="main"):
    with open(config_file, 'r') as f:
        config = f.read()
    if chain == "main":
        config_data = json.loads(config)["Configuration"]
    elif chain == "did" or chain == "token":
        config_data = json.loads(config)

    if chain == "main":
        try:
            rpcport = config_data["HttpJsonPort"]
        except KeyError:
            rpcport = 20336
        rpcuser = config_data["RpcConfiguration"]["User"]
        rpcpassword = config_data["RpcConfiguration"]["Pass"]
    elif chain == "did":
        try:
            rpcport = config_data["RPCPort"]
        except KeyError:
            rpcport = 20606
        rpcuser = config_data["RPCUser"]
        rpcpassword = config_data["RPCPass"]
    elif chain == "token":
        try:
            rpcport = config_data["RPCPort"]
        except KeyError:
            rpcport = 20616
        rpcuser = config_data["RPCUser"]
        rpcpassword = config_data["RPCPass"]
    return rpcport, rpcuser, rpcpassword

if __name__ == '__main__':
    main()
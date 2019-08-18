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
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "w") as out:
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
    producer_states = {"Pending": 1, "Active": 2, "Inactive": 3, "Canceled": 4, "Illegal": 5, "Returned": 6}
    producer_state_raw = producer["state"]
    producer_state = producer_states[producer_state_raw]
    producer_registerheight = producer["registerheight"]
    producer_cancelheight = producer["cancelheight"]
    producer_inactiveheight = producer["inactiveheight"]
    producer_illegalheight = producer["illegalheight"]
    producer_rank = producer["index"] + 1
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "a") as out:
        out.write(f'elastos_metrics_dpos_rank{{height="{height}",nickname="{producer_nickname}",ownerpublickey="{producer_ownerpublickey}",nodepublickey="{producer_nodepublickey}"}} {producer_rank}\n')
        out.write(f'elastos_metrics_dpos_state{{height="{height}",nickname="{producer_nickname}",ownerpublickey="{producer_ownerpublickey}",nodepublickey="{producer_nodepublickey}",state="{producer_state_raw}"}} {producer_state}\n')
        out.write(f'elastos_metrics_dpos_registerheight{{height="{height}",nickname="{producer_nickname}",ownerpublickey="{producer_ownerpublickey}",nodepublickey="{producer_nodepublickey}"}} {producer_registerheight}\n')
        out.write(f'elastos_metrics_dpos_cancelheight{{height="{height}",nickname="{producer_nickname}",ownerpublickey="{producer_ownerpublickey}",nodepublickey="{producer_nodepublickey}"}} {producer_cancelheight}\n')
        out.write(f'elastos_metrics_dpos_inactiveheight{{height="{height}",nickname="{producer_nickname}",ownerpublickey="{producer_ownerpublickey}",nodepublickey="{producer_nodepublickey}"}} {producer_inactiveheight}\n')
        out.write(f'elastos_metrics_dpos_illegalheight{{height="{height}",nickname="{producer_nickname}",ownerpublickey="{producer_ownerpublickey}",nodepublickey="{producer_nodepublickey}"}} {producer_illegalheight}\n')

    # DID Sidechain Node State
    rpcport, rpcuser, rpcpassword = getConfigs("/data/elastos/did/config.json", chain="did")
    node_state = getNodeState(session, rpcport, rpcuser, rpcpassword)
    height = node_state["height"]
    node_version = node_state["compile"]
    services = node_state["services"]
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "a") as out:
        out.write(f'elastos_metrics_nodestate{{chain="did",height="{height}",nodeversion="{node_version}",services="{services}"}} 1\n')

    # Token Sidechain Node State 
    rpcport, rpcuser, rpcpassword = getConfigs("/data/elastos/token/config.json", chain="token")
    node_state = getNodeState(session, rpcport, rpcuser, rpcpassword)
    height = node_state["height"]
    node_version = node_state["compile"]
    services = node_state["services"]
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "a") as out:
        out.write(f'elastos_metrics_nodestate{{chain="token",height="{height}",nodeversion="{node_version}",services="{services}"}} 1\n')

    # ioex mining node stats
    node_state = getNodeState(session, 30336)
    height = node_state["Height"]
    with open("/data/elastos/metrics/prometheus/node-exporter/ioex-metrics.prom", "a") as out:
        out.write(f'ioex_metrics_nodestate{{chain="ioexmain",height="{height}"}} 1\n')

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

def getNodeState(session, rpcport, rpcuser=None, rpcpassword=None):
    url = "http://{0}:{1}".format(HOST, rpcport)
    d = {"method":"getnodestate"}
    if rpcuser and rpcpassword:
        response = session.post(url, data=json.dumps(d), auth=(rpcuser, rpcpassword))
    else:
        response = session.post(url, data=json.dumps(d))
    data = json.loads(response.text)["result"]
    return data

def getConfigs(config_file, chain="main"):
    with open(config_file, encoding='utf-8-sig') as f:
        if chain == "main":
            config_data = json.load(f)["Configuration"]
        elif chain == "did" or chain == "token":
            config_data = json.load(f)

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
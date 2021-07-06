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
    try:
        handle_mainchain(session)
    except:
        pass

    # DPoS Node Info
    try:
        handle_dpos(session)
    except:
        pass

    # DID Sidechain Node State
    try:
        handle_did_sidechain(session)
    except:
        pass

    # Elastos ID(EI) Sidechain Node State 
    try:
        handle_eid_sidechain(session)
    except:
        pass

    # Elastos Smart Contract(ESC) Sidechain Node State 
    try:
        handle_eth_sidechain(session)
    except:
        pass 

    # Arbiter Node State 
    try:
        handle_arbiter(session)
    except:
        pass 

    # Carrier Boostrap Node State 
    try:
        handle_carrier_bootstrap(session)
    except:
        pass 

    # Metrics Node State 
    try:
        handle_metrics(session)
    except Exception as e:
        print(str(e))
        pass
    
def handle_mainchain(session):
    rpcport, rpcuser, rpcpassword = getConfigs("/data/elastos/ela/config.json", chain="main")
    node_state = getNodeState(session, rpcport, rpcuser=rpcuser, rpcpassword=rpcpassword)
    height = node_state["height"]
    node_version = node_state["compile"]
    services = node_state["services"]
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "w") as out:
        out.write(f'elastos_metrics_nodestate{{chain="main",node="mainchain",port="{int(rpcport)}",rpcport="{int(rpcport)}",nodeversion="{node_version}",services="{services}"}} {height}\n')

def handle_dpos(session):
    nodekey = getNodeKeyFromKeystoreFile()
    rpcport, rpcuser, rpcpassword = getConfigs("/data/elastos/ela/config.json", chain="main")
    producer = getProducerInfo(session, rpcport, rpcuser, rpcpassword, nodekey) 
    if producer:
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
            out.write(f'elastos_metrics_dpos_rank{{nickname="{producer_nickname}",ownerpublickey="{producer_ownerpublickey}",nodepublickey="{producer_nodepublickey}"}} {producer_rank}\n')
            out.write(f'elastos_metrics_dpos_state{{nickname="{producer_nickname}",ownerpublickey="{producer_ownerpublickey}",nodepublickey="{producer_nodepublickey}"}} {producer_state}\n')
            out.write(f'elastos_metrics_dpos_registerheight{{nickname="{producer_nickname}",ownerpublickey="{producer_ownerpublickey}",nodepublickey="{producer_nodepublickey}"}} {producer_registerheight}\n')
            out.write(f'elastos_metrics_dpos_cancelheight{{nickname="{producer_nickname}",ownerpublickey="{producer_ownerpublickey}",nodepublickey="{producer_nodepublickey}"}} {producer_cancelheight}\n')
            out.write(f'elastos_metrics_dpos_inactiveheight{{nickname="{producer_nickname}",ownerpublickey="{producer_ownerpublickey}",nodepublickey="{producer_nodepublickey}"}} {producer_inactiveheight}\n')
            out.write(f'elastos_metrics_dpos_illegalheight{{nickname="{producer_nickname}",ownerpublickey="{producer_ownerpublickey}",nodepublickey="{producer_nodepublickey}"}} {producer_illegalheight}\n')

def handle_did_sidechain(session):
    rpcport, rpcuser, rpcpassword = getConfigs("/data/elastos/did/config.json", chain="did")
    node_state = getNodeState(session, rpcport, rpcuser=rpcuser, rpcpassword=rpcpassword)
    height = node_state["height"]
    node_version = node_state["compile"]
    services = node_state["services"]
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "a") as out:
        out.write(f'elastos_metrics_nodestate{{chain="did",node="did-sidechain",port="{int(rpcport)}",rpcport="{int(rpcport)}",nodeversion="{node_version}",services="{services}"}} {height}\n')

def handle_eid_sidechain(session):
    rpcport, _, _ = getConfigs("/etc/elastos-eid/params.env", chain="eid")
    node_state = getNodeState(session, rpcport, ethchain=True)
    height = node_state["height"]
    node_version = "0.1.0"
    services = "Ethereum Virtual Machine"
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "a") as out:
        out.write(f'elastos_metrics_nodestate{{chain="eid",node="eid-sidechain",port="{int(rpcport)}",rpcport="{int(rpcport)}",nodeversion="{node_version}",services="{services}"}} {height}\n')

def handle_eth_sidechain(session):
    rpcport, _, _ = getConfigs("/etc/elastos-eth/params.env", chain="eth")
    node_state = getNodeState(session, rpcport, ethchain=True)
    height = node_state["height"]
    node_version = "0.1.3.2"
    services = "Ethereum Virtual Machine"
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "a") as out:
        out.write(f'elastos_metrics_nodestate{{chain="eth",node="eth-sidechain",port="{int(rpcport)}",rpcport="{int(rpcport)}",nodeversion="{node_version}",services="{services}"}} {height}\n')

def handle_arbiter(session):
    rpcport = "20536"
    node_version = "0.2.3"
    services = "Elastos Carrier Bootstrap Node"
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "a") as out:
        out.write(f'elastos_metrics_nodestate{{chain="crosschain",node="arbiter",port="{int(rpcport)}",rpcport="{int(rpcport)}",nodeversion="{node_version}",services="{services}"}} 1\n')

def handle_carrier_bootstrap(session):
    port = "33445"
    node_version = "6.0.1"
    services = "Elastos Carrier Bootstrap Node"
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "a") as out:
        out.write(f'elastos_metrics_nodestate{{chain="carrier",node="carrier",port="{int(port)}",rpcport="{int(port)}",nodeversion="{node_version}",services="{services}"}} 1\n')

def handle_metrics(session):
    port, user, password = getConfigs("/etc/elastos-metrics/params.env", chain="metrics")
    node_version = "1.6.0"
    services = "Elastos Metrics Node"
    with open("/data/elastos/metrics/prometheus/node-exporter/elastos-metrics.prom", "a") as out:
        out.write(f'elastos_metrics_nodestate{{chain="metrics",node="metrics",port="{int(port)}",rpcport="{int(port)}",nodeversion="{node_version}",services="{services}"}} 1\n')

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

def getNodeState(session, rpcport, rpcuser=None, rpcpassword=None, ethchain=False):
    url = "http://{0}:{1}".format(HOST, rpcport)
    if ethchain:
        d = {"method":"eth_blockNumber", "id":1}
    else: 
        d = {"method":"getnodestate"}
    try:
        if rpcuser and rpcpassword:
            response = session.post(url, data=json.dumps(d), auth=(rpcuser, rpcpassword))
        else:
            response = session.post(url, data=json.dumps(d))
        data = json.loads(response.text)["result"]
    except:
        return {}
    if ethchain:
        data = {"height": int(data, 16)}
    return data

def getConfigs(config_file, chain="main"):
    with open(config_file, encoding='utf-8-sig') as f:
        if chain == "main":
            config_data = json.load(f)["Configuration"]
        elif chain == "did":
            config_data = json.load(f)
        elif chain == "eth" or chain == "metrics":
            config_data = {}
            for line in f:
                key, val = line.partition("=")[::2]
                config_data[key.strip()] = val

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
    elif chain == "eth":
        try:
            rpcport = config_data["RPCPort"].rstrip().strip('"')
        except KeyError:
            rpcport = 20636
            rpcuser, rpcpassword = '', ''
    elif chain == "metrics":
        try:
            rpcport = config_data["PORT"].rstrip().strip('"')
            rpcuser = config_data["AUTH_USER"].rstrip()
            rpcpassword = config_data["AUTH_PASSWORD"].rstrip()
        except KeyError:
            rpcport = 5000
            rpcuser, rpcpassword = '', ''
    return rpcport, rpcuser, rpcpassword

if __name__ == '__main__':
    main()
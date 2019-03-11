#!/usr/bin/env python3

import os
import base64, codecs, json, requests

url = 'https://localhost:8181/v1/getinfo'
cert_path = '/media/important/important/lnd/tls.cert'
macaroon_path = '/media/important/important/lnd/data/chain/bitcoin/mainnet/readonly.macaroon';

def getinfo():
  if os.path.exists(macaroon_path):
    with open(os.path.expanduser(macaroon_path), "rb") as f:
      macaroon_bytes = f.read()
      macaroon = codecs.encode(macaroon_bytes, 'hex')

  if macaroon:
    r = requests.get(url, headers={"Grpc-Metadata-macaroon": macaroon}, verify=cert_path)
    if r.status_code == 200:
      return r.json()
    else:
      return {"error": r.status_code, "dump": r.text}
  else:
    return {"error": "No Macaroon files present"}
  
if __name__ == '__main__':
  if os.path.exists("/media/important/important/lnd"):
    if not os.path.exists("/media/important/important/lnd/v2_onion_private_key"):
      # LND private key doesnt exist, don't do anything yet
      print("LND private key doesn't exist, node still syncing or not a tor node");
    else:
      # Check lncli info
      json_result = getinfo();
      if not 'uris' in json_result:
        print("URIs doesn't exist, restarting");
      else:
        print("key exists");
  else:
    print("LND directory doesn't exist");

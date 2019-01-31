#!/usr/bin/env python3

import base64, codecs, json, requests, os
import random, string


# Generate seed
url = 'https://localhost:8181/v1/genseed'
# Initialize wallet
url2 = 'https://localhost:8181/v1/initwallet'
cert_path = '/media/important/lnd/tls.cert'
seed_filename  = '/home/lncm/seed.txt' 


def randompass(stringLength=10):
  letters = string.ascii_letters
  return ''.join(random.choice(letters) for i in range(stringLength))

def main():
  # Check if there is an existing file, if not generate a random password
  if not os.path.exists("/media/important/lnd/sesame.txt"):
    password_str=randompass(stringLength=15)
    password_file = open("/media/important/lnd/sesame.txt","w")
    password_file.write(password_str)
    password_file.close()
  else:
    password_str = open('/media/important/lnd/sesame.txt', 'r').read().rstrip()
    password_bytes = str(password_str).encode('utf-8')
  
  
  try:
    r = requests.get(url, verify=cert_path)
  except:
    # Silence connection errors when lnd is not running
    pass
  else:
    try:
        if r.status_code == 200:
            json_seed_creation = r.json()
            json_seed_mnemonic = json_seed_creation['cipher_seed_mnemonic']
            json_enciphered_seed = json_seed_creation['enciphered_seed']
            if not os.path.exists(seed_filename):
                seed_file = open(seed_filename, "w")
                for word in json_seed_mnemonic:
                    seed_file.write(word + "\n")
                seed_file.close()
                data = { 'cipher_seed_mnemonic': json_seed_mnemonic, 'wallet_password': base64.b64encode(password_bytes).decode()}
            else:
                seed_file = open(seed_filename, "r")
                seed_file_words = seed_file.readlines()
                import_file_array = []
                for importword in seed_file_words:
                    import_file_array.append(importword.replace("\n", ""))
                data = { 'cipher_seed_mnemonic': import_file_array, 'wallet_password': base64.b64encode(password_bytes).decode()}
            # Next import new or existing seed
            #print(data)
            r2 = requests.post(url2, verify=cert_path, data=json.dumps(data))
            if r2.status_code == 200:
                print(r2.status_code)
                print(r2.json())
            else:
                print('Error creating wallet')
    except:
        # JSON will fail to decode when unlocked already since response is empty
        pass


if __name__ == '__main__':
    if os.path.exists("/media/important/lnd"):
        if not os.path.exists("/media/important/lnd/data/chain"):
            main()
        else:
            print('Wallet already exists! Please delete /media/important/lnd/data/chain and then restart LND')
    else:
        print('LND directory does not exist!')



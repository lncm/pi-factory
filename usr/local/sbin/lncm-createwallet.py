#!/usr/bin/env python3

import base64, codecs, json, requests, os
import random, string

# Generate seed
url = 'https://localhost:8181/v1/genseed'
# Initialize wallet
url2 = 'https://localhost:8181/v1/initwallet'
cert_path = '/media/important/lnd/tls.cert'
seed_filename  = '/home/lncm/seed.txt' 


''' 
  Functions have 2 spaces
'''
def randompass(stringLength=10):
  letters = string.ascii_letters
  return ''.join(random.choice(letters) for i in range(stringLength))

def main():
  # Check if there is an existing file, if not generate a random password
  if not os.path.exists("/media/important/lnd/sesame.txt"):
    password_str=randompass(stringLength=15)
    # Write password string to file if not exist
    password_file = open("/media/important/lnd/sesame.txt","w")
    password_file.write(password_str)
    password_file.close()
  else:
    # Get password from file
    password_str = open('/media/important/lnd/sesame.txt', 'r').read().rstrip()
  
  # Convert password to byte encoded
  password_bytes = str(password_str).encode('utf-8')
  
  # Step 1 get seed from web or file
  
  # Send request to generate seed if seed file doesnt exist
  if not os.path.exists(seed_filename):
    r = requests.get(url, verify=cert_path)
    if r.status_code == 200:
      json_seed_creation = r.json()
      json_seed_mnemonic = json_seed_creation['cipher_seed_mnemonic']
      json_enciphered_seed = json_seed_creation['enciphered_seed']
      seed_file = open(seed_filename, "w")
      for word in json_seed_mnemonic:
        seed_file.write(word + "\n")
      seed_file.close()
      data = { 'cipher_seed_mnemonic': json_seed_mnemonic, 'wallet_password': base64.b64encode(password_bytes).decode()}
    # Data doesnt get set if cant create the seed but that is fine, handle it later
  else:
    # Seed exists
    seed_file = open(seed_filename, "r")
    seed_file_words = seed_file.readlines()
    import_file_array = []
    for importword in seed_file_words:
      import_file_array.append(importword.replace("\n", ""))
    # Generate init wallet file from what was posted
    data = { 'cipher_seed_mnemonic': import_file_array, 'wallet_password': base64.b64encode(password_bytes).decode()}
  
  # Step 2: Create wallet
  try:
    data
  except NameError:
    print("data isn't defined")
    pass
  else:
    # Data is defined so proceed
    r2 = requests.post(url2, verify=cert_path, data=json.dumps(data))
    if r2.status_code == 200:
      # If create wallet was successful
      print("Create wallet is successful")
    else:
      print("Create wallet is not successful")


'''
Main entrypoint function

Testing creation notes:
rm /home/lncm/seed.txt
rm /media/important/lnd/sesame.txt

docker stop compose_lndbox_1 ; rm -fr /media/important/lnd/data/chain/ ; docker start compose_lndbox_1
'''

if __name__ == '__main__':
  if os.path.exists("/media/important/lnd"):
    if not os.path.exists("/media/important/lnd/data/chain"):
      main()
    else:
      print('Wallet already exists! Please delete /media/important/lnd/data/chain and then restart LND')
  else:
    print('LND directory does not exist!')



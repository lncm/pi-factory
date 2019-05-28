#!/usr/bin/env python3

'''
How to use

Dependencies
sudo pip3 install toml
'''

import os, sys
import toml
from pathlib import Path

def read(configfile='', bitcoindusername='', bitcoindpassword=''):
    if os.path.exists(configfile):
        # write config file
        invoicer_config_dict = toml.load(configfile)
        invoicer_config_dict['port'] = '8088'
        invoicer_config_dict['log-file'] = '/logs/invoicer.logs'
        invoicer_config_dict['static-dir'] = '/static/'
        invoicer_config_dict['bitcoind']['user'] = bitcoindusername
        invoicer_config_dict['bitcoind']['pass'] = bitcoindpassword
        invoicer_config_dict['lnd']['tls'] = '/lnd/tls.cert'
        invoicer_config_dict['lnd']['macaroon']['invoice'] = '/lnd/data/chain/bitcoin/mainnet/invoice.macaroon'
        invoicer_config_dict['lnd']['macaroon']['readonly'] = '/lnd/data/chain/bitcoin/mainnet/invoice.macaroon'

        # write in default users
        invoicer_config_dict['users'] = {
            'lncm': 'chiangmai'
        }
        
        # Open file for writing
        file_object  = open(configfile, "w")
        
        # Write out the dictionary to a file
        toml.dump(invoicer_config_dict, file_object)

        # Be a good citizen and close it
        file_object.close()
    else:
        print("File does not exist")

if __name__ == '__main__':
    if len(sys.argv) == 3:
        read('/media/important/important/invoicer.conf', sys.argv[1], sys.argv[2])
    else:
        print('Need more arguments')
        print('Usage: ' + sys.argv[0] + ' <rpcusername> <rpcpassword>')
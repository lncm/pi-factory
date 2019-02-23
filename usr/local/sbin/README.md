# `/usr/local/sbin/`

This directory contains scripts responsible for various functions of The Box.

## `check-invoicer-status`

Checks `invoicer`'s status and restarts it when necessary.


## `lncm-unlock.py`

A simple python script that unlocks lnd 

> **TODO_0:** rename the script to be more descriptive (lnd-unlock?)

> **TODO_1:** move the script to be called after `lnd` starts and not in cron 

> **TODO_2:** Is python really the best choice here?


## `lncm-usb` & `lncm-usb.py`

I think it's the same function (detecting attached USB devices and using them best), but written twice. Once in `sh` and
once in `python`.

> **TODO_0:** make sure if above is correct

> **TODO_1:** document how the decision is made
 
 
## `mana`

CLI management utility for the box.

> **TODO:** document

#!/bin/sh

file $(which file)
apk update
apk add bitcoin
file $(which bitcoind)

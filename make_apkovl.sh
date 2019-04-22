#!/bin/sh

cp README.md home/lncm/README.txt

# `COPYFILE_DISABLE=true` disables adding resource-forks on MacOS
COPYFILE_DISABLE=true tar czf box.apkovl.tar.gz --exclude '.DS_Store' --exclude 'README.md' etc home

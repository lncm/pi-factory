#!/bin/sh

# Disables adding resource-forks on MacOS
export COPYFILE_DISABLE=true

cp README.md home/lncm/README.txt

tar czf box.apkovl.tar.gz --exclude '.DS_Store' --exclude 'README.md' etc home usr

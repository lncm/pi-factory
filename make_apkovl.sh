#!/bin/sh

# Disables adding resource-forks on MacOS
export COPYFILE_DISABLE=true

cp README.md home/lncm/README.md

tar czf box.apkovl.tar.gz --exclude '.DS_Store' etc home

#!/bin/sh

# Move README to lncm HOME directory
cp README.md home/lncm/README.txt

# Create apkovl (configuration overlay)
# `COPYFILE_DISABLE=true` disables adding resource-forks on MacOS
COPYFILE_DISABLE=true tar czf box.apkovl.tar.gz --exclude '.DS_Store' --exclude 'README.md' etc home

#!/bin/sh

# Disables adding resource-forks on MacOS
export COPYFILE_DISABLE=true

# tar -h dereferences symlinks, i.e. add target to archive
# on MacOS/BSD it must be invoked as tar -H
tar czhf box.apkovl.tar.gz --exclude '.DS_Store' etc home

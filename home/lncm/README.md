# `/home/lncm/`

All files in this directory will land onto `lncm` user home directory.

## `bitcoin/bitcoin.conf` 

This file contains initial Bitcoind configuration. For a full list of options [see here].

`GENERATEDRPCAUTH` gets replaced with RPC credentials that apps using Bitcoind use.

[see here]: https://en.bitcoin.it/wiki/Running_Bitcoin


## `compose/docker-compose.yml`

This file defines how all Docker image modules interact with each other. This is now a symlink to either ```compose/clearnet/docker-compose.yml``` or ```compose/tor/docker-compose.yml```

> **TODO:** expand on that. Add links to Wikis, describe conventions, etc…


## `lnd/lnd.conf`

This is the initial config for the `lnd` client. Currently contains a lot of comments that are being overridden later. This is now a symlink to either ```lnd/clearnet/lnd.conf``` or ```lnd/tor/lnd.conf```


## `nginx`

This directory contains configuration files for nginx.

#### `nginx/conf.d/default.conf`

Specifies default paths for pre-installed apps.

> **TODO:** should probably be split into separate files, one per app.

#### `nginx/mime.types`

Defines all possible MIME types - do we really need it?

#### `nginx/nginx.conf`

Config file setting up base and common nginx configuration. 


## `public_html/index.html`

This is the merchant dashboard used by the invoicer as a UI for accepting payments.

> **TODO:** root dir here should probably be renamed to `invoicer/`


## `crontab`

Specifies periodic tasks. Most things should probably be either removed from here, or split into individual, app-specific files.

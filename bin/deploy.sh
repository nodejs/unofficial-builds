#!/bin/bash

# Any tasks that need to be run after this repository is deployed to the server
# can go in here. This is run as the `nodejs` user.

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deployed! $(date)"

# rebuild images if they need it

"${__dirname}/prepare-images.sh"
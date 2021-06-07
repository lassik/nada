#!/bin/bash
set -eux -o pipefail
cd "$(dirname "$0")"
curl --location --fail --silent --show-error \
    https://github.com/ibara/mg/archive/refs/heads/master.tar.gz |
    tar -xzf -
(cd mg-master && ./configure)
rm -rf src/
mkdir src
mv -f mg-master/*.[ch] src/
rm -rf mg-master/

#!/bin/bash

set -e

if [ "$#" -lt 2 ] || ([ "$2" != "ubuntu" ] && [ "$2" != "centos" ]); then
    cat <<EOF
Usage:
  build-variants.sh <NAME> <DISTRO> [additional vgt arguments]
Where:
 * DISTRO is one of 'ubuntu' or 'centos'
EOF
    exit 1
fi

NAME=$1
DISTRO=$2

shift 2;

vgt variantset --build 'USE_JEMALLOC=no make clean && USE_JEMALLOC=no make && PREFIX=../install make install' --artifacts install --output-dir redis-galois-${NAME}-${DISTRO} --executable-path bin/redis-server --mvee-rbuff-path /vagrant/vgt/mvee/${DISTRO}/artifacts/rbuff --multicompiler-path /vagrant/vgt/galois-multicompiler-bin-${DISTRO} --vhmalloc-path /vagrant/vgt/galois-multicompiler-bin-${DISTRO}/lib --libstdcxx-path /vagrant/vgt/galois-multicompiler-bin-${DISTRO}/vtable-rando --print-stats --xchecks-blacklist crosschecks_blacklist.txt --disable-data-rando $@

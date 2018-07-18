#!/bin/bash


# ---------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------

MONITORCONF=""
RESULTS=()
TESTS=()
MONITORLOG="testing.log"
TESTINGLOG="testing.log"   #Same by default

# ---------------------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------------------

function show_help {
    echo "Usage: $0 [-h] [-f <monitor conf>] [-m <monitor.log>] [-t <test.log>]  test1 test2 ..."
}

function runtest {
    pkill -9 monitor
    pkill -9 redis-server
    
    /mvee_module/monitor -f /target_apps/monitor.conf | tee -a $MONITORLOG &
    while ! grep -q 'Ready to accept connections' $MONITORLOG
    do
        sleep 1
    done
    
    tclsh tests/test_helper.tcl --host localhost --port 6379 --clients 1 --single $1 | tee -a $TESTINGLOG
    if [[ "${PIPESTATUS[0]}" -eq "0" ]]
        then
            RESULTS+=("$1 : SUCCEEDED")
        else
            RESULTS+=("$1 : FAILED")
    fi
    
    pkill -9 monitor
    pkill -9 redis-server
}

# ---------------------------------------------------------------------
# Option Handling
# ---------------------------------------------------------------------

# A POSIX variable. Reset in case getopts has been used previously in the shell.
OPTIND=1

while getopts "h?f:m:t:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    f)  MONITORCONF=$OPTARG
        ;;
    m)  MONITORLOG=$OPTARG
        ;;
    t)  TESTINGLOG=$OPTARG
        ;;    
    esac
done

shift $((OPTIND-1))

TESTS+=(
"unit/aofrw"
"unit/auth"
"unit/bitfield"
"unit/bitops"
"unit/dump"
"unit/expire"
"unit/geo"
"unit/hyperloglog"
"unit/introspection"
"unit/introspection-2"
"unit/keyspace"
"unit/latency-monitor"
"unit/maxmemory"
"unit/memefficiency"
"unit/multi"
"unit/obuf-limits"
"unit/other"
"unit/printver"
"unit/pubsub"
"unit/scan"
"unit/scripting"
"unit/slowlog"
"unit/sort"
"unit/type/hash"
"unit/type/list-2"
"unit/type/list-3"
"unit/type/list-common"
"unit/type/list"
"unit/type/set"
"unit/type/string"
"unit/wait"
"integration/psync2-reg"
)

if [[ -n "$*" ]]
    then 
        unset TESTS
        TESTS=("$@")
fi
        
echo "Test Count: ${#TESTS[@]}"

MONITORCONF=$MONITORCONF || '-f /target_apps/monitor.conf'

# ---------------------------------------------------------------------
# Running Tests
# ---------------------------------------------------------------------

rm -f $TESTINGLOG
rm -f $MONITORLOG

for i in "${TESTS[@]}"
do
    runtest $i
done

sleep 2
printf '\n\nRESULTS\n-------\n'
printf '%s\n' "${RESULTS[@]}"


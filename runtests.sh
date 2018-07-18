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
    killall monitor
    killall redis-server
    
    /mvee_module/monitor -f /target_apps/monitor.conf | tee -a $MONITORLOG &
    sleep 5
    
    tclsh tests/test_helper.tcl --host localhost --port 6379 --clients 1 --single $1 | tee -a $TESTINGLOG
    if [[ $? -eq 0 ]]
        then
            RESULTS+=("$1 : SUCCEEDED")
        else
            RESULTS+=("$1 : FAILED")
    fi
    
    killall monitor
    killall redis-server
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
"unit/auth"
"unit/scan"
"unit/geo"
"unit/bitfield"
"unit/bitops"
"unit/type/string"
"unit/type/list-2"
"unit/type/list-3"
"unit/type/set"
"unit/type/hash"
"unit/expire"
"unit/sort"
"unit/multi"
"unit/pubsub"
"unit/introspection"
"unit/introspection-2"
"unit/obuf-limits"
"unit/hyperloglog"
"unit/wait"
"unit/keyspace"
"integration/psync2-reg"
)

if [[ -n "$*" ]]
    then 
        unset TESTS
        TESTS="$@"
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


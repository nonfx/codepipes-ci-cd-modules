#!/bin/bash
set -e

action=$1
if [ "$action" = "run" ]; then
    cmd=$2
    retry_count=${3:-2}
    sleep_sec=${4:-2}
    if [ -n "$cmd" ]; then
        while [ $retry_count -gt 0 ]; do
            # run the command
            value=$($cmd)

            if [ ! -z "$value" ]; then
                echo "$value"; break
            fi

            sleep $sleep_sec
            retry_count=`expr $retry_count - 1`
        done
    fi
else
    script_name="$0"
    echo "Usage: $script_name command [n=2] [t=2]"
    echo "run the given command until it returns non empty output or maximum 'n' times and wait for 't' seconds between each retry."
    echo "  n   retry count. min 1. default 2"
    echo "  t   wait time between each re-try in seconds. default 2"
    echo "Example: $script_name 'cat file.txt' 2 2"
fi
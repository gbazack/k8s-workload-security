#!/bin/bash
process_name=$@

if test -z $(which strace); then
    echo "Error: Strace package is not installed"
    if test -e $(which apk); then
        echo "Installing strace..."
        apk update && apk add --no-cahe strace
    elif test -e $(which apt); then
        echo "Installing strace..."
        apt update && apt install strace --yes
    else
        exit 1
    fi
fi

# Collecting process system calls and signals
strace -ff $process_name -o strace.log

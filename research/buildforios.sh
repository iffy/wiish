#!/bin/bash
# Build a nim file into an iOS app

NIMFILE=$1
if [ -z "$NIMFILE" ]; then
    echo "Please provide a nim file"
    exit 1
fi


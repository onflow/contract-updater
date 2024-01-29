#!/bin/bash

# Check if exactly one argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <FILENAME>"
    exit 1
fi

# Hex encode the file's contents
cat "$1" | xxd -p | tr -d '\n'


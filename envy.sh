#!/bin/bash

set -euo pipefail

envy() {
    INPUT=$1
    if grep -q "vault://" <<< "$INPUT"; then
        VAULT_PATH=$(echo ${INPUT} | sed 's/vault:\/\///')
        VAULT_RESPONSE=$(vault read ${VAULT_PATH} -format=json)
        CONTENTS=$(echo ${VAULT_RESPONSE} | jq -r '.data|to_entries|map("\(.key)=\(.value|tostring)")|.[]')
    else
        CONTENTS=$(cat $INPUT)
    fi
    for PAIR in $CONTENTS; do
        K=$(echo ${PAIR} | sed 's/\([^=]*\)=\(.*\)/\1/')
        V=$(echo ${PAIR} | sed 's/\([^=]*\)=\(.*\)/\2/')
        if [ $K == "_INCLUDE" ]; then
            envy $V
        else
            # If variable not already set then export
            if [ -z "${!K:-}" ]; then
                echo "export $K=$V"
            fi
        fi
    done
}

if [ -n "${1:-}" ]; then
  envy $1
else
  echo "Usage: ./envy.sh <input>"
fi
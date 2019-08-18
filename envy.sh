#!/usr/bin/env bash
# envy: https://github.com/dlip/envy

set -euo pipefail

OUTPUT_FORMAT=${2:-bash}

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
                BASH_FORMAT="export $K=$V"
                eval "${BASH_FORMAT}"
                if [ $OUTPUT_FORMAT == "bash" ]; then
                    echo $BASH_FORMAT
                elif [ $OUTPUT_FORMAT == "env-file" ]; then
                    echo "$K=$V"
                fi
            fi
        fi
    done
}

if [ -n "${1:-}" ]; then
    envy $1
else
    echo "Usage: ./envy.sh input [output-format]"
    echo "Valid output formats: bash (default), env-file"
fi
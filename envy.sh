#!/usr/bin/env bash
# envy.sh: https://github.com/dlip/envy.sh

set -euo pipefail

OUTPUT=${2:-bash}

envy() {
    INPUT=$1
    if grep -q "vault://" <<< "$INPUT"; then
        VAULT_PATH=$(echo ${INPUT} | sed 's/vault:\/\///')
        VAULT_RESPONSE=$(vault read ${VAULT_PATH} -format=json)
        CONTENTS=$(echo ${VAULT_RESPONSE} | jq -r '.data|to_entries|map("\(.key)=\(.value|tostring)")|.[]')
    else
        CONTENTS=$(cat $INPUT)
    fi
    for PAIR in ${CONTENTS}; do
        K=$(echo ${PAIR} | sed 's/\([^=]*\)=\(.*\)/\1/')
        V=$(echo ${PAIR} | sed 's/\([^=]*\)=\(.*\)/\2/')
        if grep -q "^_INCLUDE" <<< "${K}"; then
            envy $V
        else
            # If variable not already set then export
            if [ -z "$(printenv ${K})" ]; then
                BASH_FORMAT="export $K=$V"
                eval "${BASH_FORMAT}"
                if [ $OUTPUT == "bash" ]; then
                    echo "${BASH_FORMAT}"
                elif [ ${OUTPUT} == "env-file" ]; then
                    echo "${PAIR}"
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
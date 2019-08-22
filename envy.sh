#!/usr/bin/env bash
# envy.sh: https://github.com/dlip/envy.sh

set -euo pipefail

OUTPUT=${2:-bash}

envy() {
    INPUT=$1
    IS_LOCAL_FILE=true
    if grep -q "^vault://" <<< "$INPUT"; then
        IS_LOCAL_FILE=false
        VAULT_PATH=$(echo ${INPUT} | sed 's/vault:\/\///')
        VAULT_RESPONSE=$(vault read ${VAULT_PATH} -format=json)
        CONTENTS=$(echo ${VAULT_RESPONSE} | jq -r '.data|to_entries|map("\(.key)=\(.value|tostring)")|.[]')
    else
        FILEPATH=$(dirname "${INPUT}")
        pushd "${FILEPATH}" > /dev/null
        FILENAME=$(basename "${INPUT}")
        CONTENTS=$(cat "${FILENAME}" | grep "^[^#]")
    fi
    while read -r PAIR; do
        K=$(echo ${PAIR} | sed 's/\([^=]*\)=\(.*\)/\1/')
        V=$(echo ${PAIR} | sed 's/\([^=]*\)=\(.*\)/\2/')
        if grep -q "^_INCLUDE" <<< "${K}"; then
            envy "${V}"
        else
            # If variable not already set then export
            if [ -z "$(printenv ${K})" ]; then
                BASH_ESCAPED_VALUE=$(sed 's/\([$\\ ]\)/\\\1/g' <<< "${V}")
                BASH_FORMAT="export ${K}=${BASH_ESCAPED_VALUE}"
                eval "${BASH_FORMAT}"
                if [ $OUTPUT == "bash" ]; then
                    echo "${BASH_FORMAT}"
                elif [ ${OUTPUT} == "env-file" ]; then
                    echo "${PAIR}"
                elif [ ${OUTPUT} == "make" ]; then
                    MAKE_ESCAPED_VALUE=$(sed 's/\([$]\)/$\1/g' <<< "${V}")
                    MAKE_ESCAPED_VALUE=$(sed 's/\([#\\]\)/\\\1/g' <<< "${MAKE_ESCAPED_VALUE}")
                    echo "export ${K}=${MAKE_ESCAPED_VALUE}"
                fi
            fi
        fi
    done <<< "${CONTENTS}"
    if [ "${IS_LOCAL_FILE}" = "true" ]; then
        popd > /dev/null
    fi
}

if [ -n "${1:-}" ]; then
    envy "${1}"
else
    echo "envy.sh v1.1.2"
    echo "Usage: envy.sh input [output-format]"
    echo "Valid inputs: env-file, vault"
    echo "Valid output formats: bash (default), make, env-file"
    echo "See project for details: https://github.com/dlip/envy.sh"
fi
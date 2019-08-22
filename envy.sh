#!/usr/bin/env bash
# envy.sh: https://github.com/dlip/envy.sh

set -euo pipefail

OUTPUT=${2:-bash}

ENV_NAMESPACE=
ENVY_OVERRIDE_ENV="${ENVY_OVERRIDE_ENV:-}"
if [ "${ENVY_OVERRIDE_ENV}" == "true" ]; then
    ENV_NAMESPACE="__ENVY_"
fi

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
            EXISTING_VAR=$(printenv "${ENV_NAMESPACE}${K}" || true)
            if [ -z "${EXISTING_VAR}" ]; then
                BASH_ESCAPED_VALUE=$(sed 's/\([$\\ ]\)/\\\1/g' <<< "${V}")
                eval "export ${ENV_NAMESPACE}${K}=${BASH_ESCAPED_VALUE}"
                if [ "${OUTPUT}" == "bash" ]; then
                    echo "export ${K}=${BASH_ESCAPED_VALUE}"
                elif [ "${OUTPUT}" == "env-file" ]; then
                    echo "${PAIR}"
                elif [ "${OUTPUT}" == "make" ]; then
                    MAKE_ESCAPED_VALUE=$(sed 's/\([$]\)/$\1/g' <<< "${V}")
                    MAKE_ESCAPED_VALUE=$(sed 's/\([#\\]\)/\\\1/g' <<< "${MAKE_ESCAPED_VALUE}")
                    echo "export ${K}=${MAKE_ESCAPED_VALUE}"
                fi
            fi
        fi
    done <<< "${CONTENTS}"
    if [ "${IS_LOCAL_FILE}" == "true" ]; then
        popd > /dev/null
    fi
}

if [ -n "${1:-}" ]; then
    envy "${1}"
else
    echo "envy.sh v1.2.0"
    echo "Usage: envy.sh input [output-format]"
    echo "Valid inputs: env-file, vault"
    echo "Valid output formats: bash (default), make, env-file"
    echo "See project for details: https://github.com/dlip/envy.sh"
fi
#!/usr/bin/env bash
# envy.sh: https://github.com/dlip/envy.sh

set -euo pipefail

ENVY_NAMESPACE="__ENVY_"
OUTPUT_FORMAT="${2:-bash}"
OUTPUT="${3:-/dev/stdout}"

template () {
    local RESULT=""
    local LAST_CHAR=""

    # Read input char by char
    while read -n1 CHAR; do
        # If found {{
        if [[ "${CHAR}" == "{" && "${LAST_CHAR}" == "{" ]]; then
            # Remove extra {
            RESULT="${RESULT%?}"
            local VAR_RESULT=""
            local VAR_LAST_CHAR=""
            local VAR_FOUND=false
            # Search for }}
            while read -n1 VAR_CHAR; do
                # If found }}
                if [[ "${VAR_CHAR}" == "}" && "${VAR_LAST_CHAR}" == "}" ]]; then
                    VAR_FOUND=true
                    # Remove extra }
                    VAR="${VAR_RESULT%?}"
                    # Check for no variable, assume not a template
                    if [ "${VAR}" == "" ]; then
                        VAR_RESULT="{{}}"
                    # Check for escaping
                    elif [[ "${VAR:0:1}" == '\' ]]; then
                        VAR_RESULT="{{${VAR:1}}}"
                    else
                        # Lookup value
                        V=$(printenv "${VAR}")
                        # Throw error if not set
                        if [ -z "${V}" ]; then
                            echo "Error while parsing tempate, ${VAR} not set" >&2
                            exit 1
                        fi
                        VAR_RESULT="${V}"
                    fi
                    break
                # If find another {{ assume this is not a template and continue on to the next pair
                elif [[ "${VAR_CHAR}" == "{" && "${VAR_LAST_CHAR}" == "{" ]]; then
                    RESULT+="{{${VAR_RESULT%?}"
                    VAR_RESULT=""
                else
                    VAR_RESULT+="${VAR_CHAR}"
                fi
                VAR_LAST_CHAR="${VAR_CHAR}"
            done
            # If VAR never found, add back the open {{
            if [ "${VAR_FOUND}" == "false" ]; then
                RESULT+="{{"
            fi
            RESULT+="${VAR_RESULT}"
        else
            RESULT+="${CHAR}"
        fi
        LAST_CHAR="${CHAR}"
    done

    echo "${RESULT}"
}

bash_escape() {
    sed 's/\([$\\"'\''/ ]\)/\\\1/g' <<< "${1}"
}

process_input() {
    INPUT=$1
    IS_LOCAL_FILE=true
    if grep -q "^vault://" <<< "${INPUT}"; then
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
        K=${PAIR%%"="*}
        V=${PAIR#*"="*}
        V=$(template <<< $(bash_escape "${V}"))
        if grep -q "^_INCLUDE" <<< "${K}"; then
            process_input "${V}"
        else
            export ${K}="${V}"
            export ${ENVY_NAMESPACE}${K}="${V}"
        fi
    done <<< "${CONTENTS}"
    if [ "${IS_LOCAL_FILE}" == "true" ]; then
        popd > /dev/null
    fi
}

process_output() {
    if [ "${OUTPUT}" != "/dev/stdout" ]; then
        rm -f "${OUTPUT}"
    fi

    ENVY_ENV=$(env | sort | grep "^${ENVY_NAMESPACE}" | sed "s/^${ENVY_NAMESPACE}\([^=]*\)=.*/\1/")
    while read -r K; do
        V=$(printenv "${ENVY_NAMESPACE}${K}")
        if [ "${OUTPUT_FORMAT}" == "bash" ]; then
            echo "export ${K}=$(bash_escape "${V}")" >> $OUTPUT
        elif [ "${OUTPUT_FORMAT}" == "env-file" ]; then
            echo "${K}=${V}" >> $OUTPUT
        elif [ "${OUTPUT_FORMAT}" == "make" ]; then
            MAKE_ESCAPED_VALUE=$(sed 's/\([$]\)/$\1/g' <<< "${V}")
            MAKE_ESCAPED_VALUE=$(sed 's/\([#]\)/\\\1/g' <<< "${MAKE_ESCAPED_VALUE}")
            echo "export ${K}:=${MAKE_ESCAPED_VALUE}" >> $OUTPUT
        else
            echo "Unknown output format '${OUTPUT_FORMAT}'"
            exit 1
        fi
    done <<< "${ENVY_ENV}"
}

if [ -n "${1:-}" ]; then
    process_input "${1}"
    process_output
else
    echo "envy.sh v2.1.3"
    echo "Usage: envy.sh input [output-format] [output-file]"
    echo "Valid inputs: env-file, vault"
    echo "Valid output formats: bash (default), make, env-file"
    echo "See project for details: https://github.com/dlip/envy.sh"
fi


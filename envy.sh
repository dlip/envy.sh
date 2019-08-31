#!/usr/bin/env bash
# envy.sh: https://github.com/dlip/envy.sh

set -euo pipefail

OUTPUT="${2:-bash}"
ENVY_NAMESPACE="__ENVY_"

template () {
    local RESULT=""
    local LAST_CHAR=""

    # Read input char by char
    while read -n1 CHAR; do
        # Check if seen {{
        if [[ "${CHAR}" == "{" && "${LAST_CHAR}" == "{" ]]; then
            local VAR_RESULT=""
            local VAR_LAST_CHAR=""
            # Search for }}
            while read -n1 VAR_CHAR; do
                # Check if seen }}
                if [[ "${VAR_CHAR}" == "}" && "${VAR_LAST_CHAR}" == "}" ]]; then
                    # Remove extra {
                    RESULT="${RESULT::-1}"
                    # Remove extra }
                    VAR="${VAR_RESULT::-1}"
                    # Check for escaping
                    if [ "${VAR}" == "{{" ]; then
                        RESULT+="{{"
                    # Check for no variable, assume to a template
                    elif [ "${VAR}" == "" ]; then
                        RESULT+="{{}}"
                    else
                        # Lookup value
                        V=$(printenv "${VAR}")
                        # Throw error if not set
                        if [ -z "${V}" ]; then
                            echo "Error while parsing tempate, ${VAR} not set" >&2
                            exit 1
                        fi
                        RESULT+="${V}"
                    fi
                    break
                else
                    VAR_RESULT+="${VAR_CHAR}"
                fi
                VAR_LAST_CHAR="${VAR_CHAR}"
            done
        else
            RESULT+="${CHAR}"
        fi
        LAST_CHAR="${CHAR}"
    done

    echo ${RESULT}
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
        # Check if templating
        if grep -q "{{.*}}" <<< "${V}"; then
            V=$(template <<< "${V}")
        fi
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
    ENVY_ENV=$(env | sort | grep "^${ENVY_NAMESPACE}" | sed "s/^${ENVY_NAMESPACE}\([^=]*\)=.*/\1/")
    while read -r K; do
        V=$(printenv "${ENVY_NAMESPACE}${K}")
        if [ "${OUTPUT}" == "bash" ]; then
            echo "export ${K}=$(bash_escape "${V}")"
        elif [ "${OUTPUT}" == "env-file" ]; then
            echo "${K}=${V}"
        elif [ "${OUTPUT}" == "make" ]; then
            MAKE_ESCAPED_VALUE=$(sed 's/\([$]\)/$\1/g' <<< "${V}")
            MAKE_ESCAPED_VALUE=$(sed 's/\([#\\]\)/\\\1/g' <<< "${MAKE_ESCAPED_VALUE}")
            echo "export ${K}=${MAKE_ESCAPED_VALUE}"
        else
            echo "Unknown output format '${OUTPUT}'"
            exit 1
        fi
    done <<< "${ENVY_ENV}"
}

if [ -n "${1:-}" ]; then
    process_input "${1}"
    process_output
else
    echo "envy.sh v2.1.0"
    echo "Usage: envy.sh input [output-format]"
    echo "Valid inputs: env-file, vault"
    echo "Valid output formats: bash (default), make, env-file"
    echo "See project for details: https://github.com/dlip/envy.sh"
fi
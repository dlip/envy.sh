#!/usr/bin/env bash
# envy.sh: https://github.com/dlip/envy.sh

set -euo pipefail

OUTPUT="${2:-bash}"
ENVY_NAMESPACE="__ENVY_"

# Taken from https://github.com/jwerle/mush
mush () {
  local SELF="$0"
  local NULL=/dev/null
  local STDIN=0
  local STDOUT=1
  local STDERR=2
  local LEFT_DELIM="{{"
  local RIGHT_DELIM="}}"
  local INDENT_LEVEL="  "
  local ENV="`env`"
  local out=">&$STDOUT"

  ## read each line
  while IFS= read -r line; do
    printf '%q\n' "${line}" | {
        ## read each ENV variable
        echo "$ENV" | {
          while read var; do
            ## split each ENV variable by '='
            ## and parse the line replacing
            ## occurrence of the key with
            ## guarded by the values of
            ## `LEFT_DELIM' and `RIGHT_DELIM'
            ## with the value of the variable
            case "$var" in
              (*"="*)
                key=${var%%"="*}
                val=${var#*"="*}
                ;;

              (*)
                key=$var
                val=
                ;;
            esac

            line="${line//${LEFT_DELIM}$key${RIGHT_DELIM}/$val}"
          done

          ## output to stdout
          echo "$line" | {
            ## parse undefined variables
            sed -e "s#${LEFT_DELIM}[A-Za-z]*${RIGHT_DELIM}##g" | \
            ## parse comments
            sed -e "s#${LEFT_DELIM}\!.*${RIGHT_DELIM}##g" | \
            ## escaping
            sed -e 's/\\\"/""/g'
          };
        }
    };
  done
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
            V=$(mush <<< "${V}")
        fi
        if grep -q "^_INCLUDE" <<< "${K}"; then
            process_input "${V}"
        else
            export ${K}="$(bash_escape "${V}")"
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
    echo "envy.sh v2.0.0"
    echo "Usage: envy.sh input [output-format]"
    echo "Valid inputs: env-file, vault"
    echo "Valid output formats: bash (default), make, env-file"
    echo "See project for details: https://github.com/dlip/envy.sh"
fi
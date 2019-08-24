#!/usr/bin/env bash
# envy.sh: https://github.com/dlip/envy.sh

set -euo pipefail

OUTPUT="${2:-bash}"

ENV_NAMESPACE="__ENVY_"
ENVY_EXPORT_EXISTING_ENV="${ENVY_EXPORT_EXISTING_ENV:-true}"

mush () {
  local SELF="$0"
  local NULL=/dev/null
  local STDIN=0
  local STDOUT=1
  local STDERR=2
  local LEFT_DELIM="{{"
  local RIGHT_DELIM="}}"
  local INDENT_LEVEL="  "
  local ESCAPE=0
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

            # Remove namespace for this search
            key=$(sed "s/^${ENV_NAMESPACE}//" <<< "${key}")

            line="${line//${LEFT_DELIM}$key${RIGHT_DELIM}/$val}"
          done

          if [ "1" = "$ESCAPE" ]; then
            line="${line//&/&amp;}"
            line="${line//\"/&quot;}"
            line="${line//\</&lt;}"
            line="${line//\>/&gt;}"
          fi

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

envy() {
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
        K=$(sed 's/\([^=]*\)=\(.*\)/\1/' <<< "${PAIR}")
        V=$(sed 's/\([^=]*\)=\(.*\)/\2/' <<< "${PAIR}")
        if grep -q "^_INCLUDE" <<< "${K}"; then
            envy "${V}"
        else
            # If variable not already set then export
            EXISTING_VAR=$(printenv "${ENV_NAMESPACE}${K}" || true)
            if [ -z "${EXISTING_VAR}" ]; then
                # Check if templating
                if grep -q "{{.*}}" <<< "${V}"; then
                    V=$(mush <<< "${V}")
                fi
                BASH_ESCAPED_VALUE=$(sed 's/\([$\\ ]\)/\\\1/g' <<< "${V}")
                eval "export ${ENV_NAMESPACE}${K}=${BASH_ESCAPED_VALUE}"
                EXISTING_ENV_VAR=$(printenv "${K}" || true)
                if [ "${OUTPUT}" == "bash" ]; then
                    if [[ "${ENVY_EXPORT_EXISTING_ENV}" == "true" || -z "${EXISTING_ENV_VAR}" ]]; then
                        echo "export ${K}=${BASH_ESCAPED_VALUE}"
                    fi
                elif [ "${OUTPUT}" == "env-file" ]; then
                    echo "${PAIR}"
                elif [ "${OUTPUT}" == "make" ]; then
                    MAKE_ESCAPED_VALUE=$(sed 's/\([$]\)/$\1/g' <<< "${V}")
                    MAKE_ESCAPED_VALUE=$(sed 's/\([#\\]\)/\\\1/g' <<< "${MAKE_ESCAPED_VALUE}")
                    if [[ "${ENVY_EXPORT_EXISTING_ENV}" == "true" || -z "${EXISTING_ENV_VAR}" ]]; then
                        echo "export ${K}=${MAKE_ESCAPED_VALUE}"
                    fi
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
# [envy.sh](https://github.com/dlip/envy.sh)🤵

Stylish environment variable loading

[![Actions Status](https://wdp9fww0r9.execute-api.us-west-2.amazonaws.com/production/badge/dlip/envy.sh)](https://wdp9fww0r9.execute-api.us-west-2.amazonaws.com/production/results/dlip/envy.sh)

## Features

- Include variables from other files/inputs
- Multiple input types including vault which keeps secrets only in memory, not on disk
- Variable precedence allows logical overriding of common settings

## Requirements

- bash
- If using vault: 
    - [vault](https://www.vaultproject.io/docs/install/)
    - [jq](https://github.com/stedolan/jq)

## Installation

Download `envy.sh` and add to your repository:

```
curl -OL https://raw.githubusercontent.com/dlip/envy.sh/master/envy.sh
chmod +x ./envy.sh
```

## Usage

### basic

```
./envy.sh input [output-format]
```

### bash 

```
eval $(./envy.sh .env)
```

### make

```
export CONFIG ?= .env
$(foreach var,$(shell ./envy.sh $(CONFIG)),$(eval $(var)))
```

## Supported Inputs

### env-file

File in the format `KEY=value`:

```
VERSION=v1.0.0
ENVIRONMENT=development
```

### vault

URI eg. `vault://secret/myapp/secrets` with data in key value format:

```
{
    "VERSION": "v1.0.0",
    "ENVIRONMENT": "development"
}
```

## Supported Output Formats

### bash (default)

```
export VERSION=v1.0.0
export ENVIRONMENT=development
```

### env-file

```
VERSION=v1.0.0
ENVIRONMENT=development
```

## Includes

To include another input, add the key `_INCLUDE*` with the name of the input as the value. It supports any of the inputs listed above. eg:

```
_INCLUDE_SECRETS=vault://secret/myapp/secrets
_INCLUDE_OTHER=other.env
VERSION=v1.0.0
ENVIRONMENT=development
```

## Variable Precedence

- The highest priority is existing environment variables, envy will ignore any duplicates in the input.
- Input is evaluated top to bottom, if there is multiple declarations only the first one will be loaded.
- Includes are evaluated at the line they are included, if you want the include to take precedence add it to the top of the file, if you want the current input to take precedence add it to the bottom of the file.

## Todo

- [ ] Check `\` escapes correctly
- [ ] Output formats make docker-env-args
- [ ] Optionally override environment variables
- [ ] Consul input
- [ ] JSON input
- [ ] YAML input

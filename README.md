# [envy.sh](https://github.com/dlip/envy.sh)🤵

Stylish environment variable loading

[![Actions Status](https://wdp9fww0r9.execute-api.us-west-2.amazonaws.com/production/badge/dlip/envy.sh)](https://wdp9fww0r9.execute-api.us-west-2.amazonaws.com/production/results/dlip/envy.sh)

## Features

- Include variables from other files/inputs
- Multiple input types including vault which allows you keeps secrets only in memory for better security
- Variable precedence allows logical overriding of common settings

## Requirements

- bash
- If using vault: 
    - [vault](https://www.vaultproject.io/docs/install/)
    - [jq](https://github.com/stedolan/jq)
- Alternatively you can use the [docker](https://docs.docker.com/install/) [image](https://cloud.docker.com/u/dlip/repository/docker/dlip/envy.sh) which contains all the dependencies. To create an alias called `envy.sh` run:
  - `alias envy.sh='docker run -it --rm -v $PWD:/envy --workdir /envy dlip/envy.sh'`

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

- [Supported Inputs](#supported-inputs)
- [Supported Ouput Formats](#supported-output-formats)

### bash 

Import environment variables to current shell

```
eval $(./envy.sh .env)
```

Import environment variables in sub-shell and run command (replace env with your command)

```
bash -c 'eval $(bin/envy.sh .env) && env'
```

### make

```
export CONFIG ?= .env
$(foreach var,$(shell ./envy.sh $(CONFIG) make),$(eval $(var)))
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
export LOG_FILE=C:\\log.txt
```

### make

```
export LOG_FILE=C:\\log.txt
export PASSWORD=$$\\\#GOD\#/$$
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

- Existing environment variables will not be overridden
- Includes will override variables which are declared afterwards, if you have a shared common.env include add it to the bottom of your file so preceding variables can override its contents

## Todo

- [ ] Consider how to prioritise includes with json
- [ ] Optionally override environment variables
- [ ] Consul input
- [ ] JSON input/output
- [ ] YAML input/output
- [ ] docker-env-args output

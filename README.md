# [envy.sh](https://github.com/dlip/envy.sh)🤵

Stylish environment variable loading

[![Actions Status](https://wdp9fww0r9.execute-api.us-west-2.amazonaws.com/production/badge/dlip/envy.sh)](https://wdp9fww0r9.execute-api.us-west-2.amazonaws.com/production/results/dlip/envy.sh)

## Features

- Import other files
- Import Vault secrets
- Templating

## Example

`cat base.env`

```
ENVIRONMENT=development
VERSION=1.0.0
NAME=envy.sh
```

`cat deploy.env`

```
_INCLUDE_BASE=base.env
_INCLUDE_VAULT=vault://secret/myapp/{{DEPLOY_ENVIRONMENT}}
ENVIRONMENT={{DEPLOY_ENVIRONMENT}}
```

`DEPLOY_ENVIRONMENT=production ./envy.sh deploy.env`

```
export ENVIRONMENT=production
export NAME=envy.sh
export SECRET_VAULT_PASSWORD=GOD
export VERSION=1.0.0
```

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
curl -OL https://github.com/dlip/envy.sh/releases/latest/download/envy.sh
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
# This is a comment about the environment
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
export ENVIRONMENT=development
export LOG_FILE=C:\\log.txt
export VERSION=v1.0.0
```

### make

```
export LOG_FILE=C:\\log.txt
export PASSWORD=$$\\\#GOD\#/$$
```

### env-file

```
ENVIRONMENT=development
VERSION=v1.0.0
```

## Includes

To include another input, add the key `_INCLUDE*` with the name of the input as the value. It supports any of the inputs listed above. eg:

```
_INCLUDE_SECRETS=vault://secret/myapp/secrets
_INCLUDE_OTHER=other.env
VERSION=v1.0.0
ENVIRONMENT=development
```

## Templating

Variables can by templated by using curly braces "`{{`" and "`}}`", in this example `envy-{{VERSION}}` is replaced with `envy-1.0.0`

```
VERSION=1.0.0
NAME=envy-{{VERSION}}
```

To write a literal `{{`, escape it by putting it between curly braces `{{{{}}`

## Variable Precedence

- Variables are processed from top to bottom and lower variables will overwrite previous ones
- Includes will be evaluated in the line they are written. If you have a shared common.env you can include it at the top of your file so following variables can override its values
- Lines are sorted alphabetically before the output is written for consistency

## Changelog

### [v2.0.0 (2019-08-28)](https://github.com/dlip/envy.sh/releases/tag/v2.0.0)

- Templating
- Reverse priority logic

### [v1.1.2 (2019-08-22)](https://github.com/dlip/envy.sh/releases/tag/v1.1.2)

- Bugfix: Path with spaces not resolving

### [v1.1.1 (2019-08-21)](https://github.com/dlip/envy.sh/releases/tag/v1.1.1)

- Bugfix: Spaces not being escaped correctly

### [v1.1.0 (2019-08-21)](https://github.com/dlip/envy.sh/releases/tag/v1.1.0)

- Relative file loading

### [v1.0.0 (2019-08-21)](https://github.com/dlip/envy.sh/releases/tag/v1.0.0)

- Initial Release

## Todo

- [ ] Consider how to prioritise includes with json
- [ ] Vault testing
- [ ] Consul input
- [ ] docker-env-args output

## Licence

MIT Licence. See [LICENCE](LICENCE) for details

# [envy.sh](https://github.com/dlip/envy.sh)

Env-like configuration with superpowers 🦸

![Build Status](https://github.com/dlip/envy.sh/workflows/CI/badge.svg)

## Features

- Include other files
- Include Vault and AWS SES secrets
- Simple templating (variables only, no complex logic)

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
- If using AWS SSM:
    - [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
    - [jq](https://github.com/stedolan/jq)
- Alternatively you can use the [docker](https://docs.docker.com/install/) [image](https://cloud.docker.com/u/dlip/repository/docker/dlip/envy.sh) which contains all the dependencies. To create an alias called `envy.sh` run:
  - `alias envy.sh='docker run -it --rm -v $PWD:/envy --workdir /envy dlip/envy.sh'`

## Installation

### Via Curl

Download `envy.sh` and add to your repository:

```
curl -OL https://github.com/dlip/envy.sh/releases/latest/download/envy.sh
chmod +x ./envy.sh
```

### Via Nix Flake

``` sh
nix run github:dlip/envy.sh
```

## Usage

### basic

```
./envy.sh input [output-format] [output-file]
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

You can use the following to create a `.envy.mk` file and include it in your Makefile. Also add `.envy.mk` to your `.gitignore` file. Note: the dependency on `$(CONFIG)` here is quite simplistic so if your `.env` has any includes that change, you will need to run `make clean` to recreate the file.

```
export CONFIG ?= .env

ENVY_MK := .envy.mk
$(ENVY_MK): $(CONFIG)
	envy.sh $(CONFIG) make $@

-include $(ENVY_MK)

.PHONY: clean
clean:
	-rm -f $(ENVY_MK)
```

### Github actions

You can use the premade github action by adding a step, such as in the example below.

```yaml
name: example-pipeline
on: [pull_request]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v1

      - name: Load env-file using Envy
        uses: dlip/envy.sh@v2.3.8
        with:
          input-file: tests/basic.env

      - name: Print env
        run: env
```

Here are the other input arguments, which you can use to write an output file in any of the output formats envy supports:

```yaml
input-file:
  description: 'Envy file to load'
  required: false
  default: '.env'
output-format:
  description: 'Output format'
  required: false
  default: 'github-actions'
output-file:
  description: 'Output file'
  required: false
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

### AWS SSM

URI to path of secrets eg. `aws-ssm:///myapp/secrets`:

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

### github-actions

```
::set-env name=ENVIRONMENT::development
::set-env name=VERSION::1.0.0
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

To write a literal `{{VERSION}}`, escape it with a backslash i.e. `{{\VERSION}}`

## Variable Precedence

- Variables are processed from top to bottom and lower variables will overwrite previous ones
- Includes will be evaluated in the line they are written. If you have a shared common.env you can include it at the top of your file so following variables can override its values
- Lines are sorted alphabetically before the output is written for consistency

## Changelog

### [v2.3.8 (2020-06-16)](https://github.com/dlip/envy.sh/releases/tag/v2.3.8)

- Update to new GitHub Actions syntax

### [v2.3.7 (2020-06-16)](https://github.com/dlip/envy.sh/releases/tag/v2.3.7)

- Fix space

### [v2.3.6 (2020-06-16)](https://github.com/dlip/envy.sh/releases/tag/v2.3.6)

- Fix quote

### [v2.3.5 (2020-06-16)](https://github.com/dlip/envy.sh/releases/tag/v2.3.5)

- Handle empty env file

### [v2.3.4 (2020-06-04)](https://github.com/dlip/envy.sh/releases/tag/v2.3.4)

- Fix null check

### [v2.3.3 (2020-06-04)](https://github.com/dlip/envy.sh/releases/tag/v2.3.3)

- Throw error when no AWS secrets are found

### [v2.3.2 (2020-06-04)](https://github.com/dlip/envy.sh/releases/tag/v2.3.2)

- Throw error when no AWS secrets are found

### [v2.3.1 (2020-05-27)](https://github.com/dlip/envy.sh/releases/tag/v2.3.1)

- Fix release

### [v2.3.0 (2020-05-27)](https://github.com/dlip/envy.sh/releases/tag/v2.3.0)

- Add AWS SSM input

### [v2.2.2 (2020-05-17)](https://github.com/dlip/envy.sh/releases/tag/v2.2.2)

- Use prebuilt container in github action

### [v2.2.1 (2020-05-17)](https://github.com/dlip/envy.sh/releases/tag/v2.2.1)

- Rebuild docker container

### [v2.2.0 (2020-05-17)](https://github.com/dlip/envy.sh/releases/tag/v2.2.0)

- Feature github-actions output format
- Feature error message now diplays line the error occured

### [v2.1.4 (2020-05-15)](https://github.com/dlip/envy.sh/releases/tag/v2.1.4)

- Bugfix Escape parenthesis for bash output

### [v2.1.3 (2020-01-31)](https://github.com/dlip/envy.sh/releases/tag/v2.1.3)

- Bugfix Makefile backslash escape correction

### [v2.1.2 (2019-12-06)](https://github.com/dlip/envy.sh/releases/tag/v2.1.2)

- Bugfix Bash v3.2.57 compatibility

### [v2.1.1 (2019-09-10)](https://github.com/dlip/envy.sh/releases/tag/v2.1.1)

- Bugfix change make variables to be the simply expanded type

### [v2.1.0 (2019-09-09)](https://github.com/dlip/envy.sh/releases/tag/v2.1.0)

- Add argument to output to a file to help with Makefile includes

### [v2.0.1 (2019-09-03)](https://github.com/dlip/envy.sh/releases/tag/v2.0.1)

- Rewrite templating to be more efficient
- Bugfix: Throw error when template variable not set

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


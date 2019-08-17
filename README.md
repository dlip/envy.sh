# [envy](https://github.com/dlip/envy)

🤵Stylish environment variable loading🤵

## Features

- Include variables from other files/inputs
- Multiple input types including vault which keeps secrets only in memory, not on disk
- Variable precedence allows logical overriding of common settings

## Requirements

- bash
- If using vault: 
    - vault: https://www.vaultproject.io/docs/install/ and 
    - jq: https://github.com/stedolan/jq

## Usage

`./env.sh <input>`

## Supported Inputs

### env file

'.env' file in the format:

```
KEY=value
```

### vault

URI eg. `vault://secret/myapp/secrets` with data in key value format:

```
{
    "KEY": "value"
}
```

## Includes

To include another input, add the key `_INCLUDE` with the name of the input as the value. It supports any of the inputs listed above. eg:

```
_INCLUDE=vault://secret/myapp/secrets
_INCLUDE=.other.env
VERSION=v1.0.0
```

## Variable Precedence

The highest priority is existing environment variables and envy will ignore any duplicates in the input.

Input is evaluated top to bottom, if there is multiple declarations only the first one will be loaded.

Includes are also evaluated at the line they are included, if you want the include to take precedence add it to the top of the file if you want the current input to take precedence add it to the bottom of the file

## Examples

### bash 

```
eval $(./envy.sh .env)
```

### make

```
export CONFIG ?= .env
$(foreach var,$(shell ./envy.sh $(CONFIG)),$(eval $(var)))
```

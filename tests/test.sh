#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

@test "Given env-file input and bash output, should output variables with export prefix" {
  result="$(../envy.sh basic.env)"
  expected="export VERSION=1.0.0
export ENVIRONMENT=development"

  assert_equal "${result}" "${expected}"
}

@test "Given env-file input and env-file output, should output variables without export prefix" {
  result="$(../envy.sh basic.env env-file)"
  expected="VERSION=1.0.0
ENVIRONMENT=development"

  assert_equal "${result}" "${expected}"
}

@test "Given existing environment variables, Should not output" {
  export VERSION=2.0.0
  result="$(../envy.sh basic.env)"
  expected="export ENVIRONMENT=development"

  assert_equal "${result}" "${expected}"
}

@test "Given include, should combine output" {
  result="$(../envy.sh include.env)"
  expected="export VERSION=1.0.0
export ENVIRONMENT=development
export NAME=envy"

  assert_equal "${result}" "${expected}"
}

@test "Given include with low priority, should be overriden" {
  result="$(../envy.sh include-override.env)"
  expected="export ENVIRONMENT=production
export VERSION=1.0.0"

  assert_equal "${result}" "${expected}"
}

@test "Given env file which matches internally used variable, should not ignored" {
  result="$(../envy.sh internal-variable.env)"
  expected="export CONTENTS=test"

  assert_equal "${result}" "${expected}"
}
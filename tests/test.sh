#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

@test "Should output variables with export prefix" {
  result="$(../envy.sh basic.env)"
  expected="export VERSION=1.0.0
export ENVIRONMENT=development"

  assert_equal "${result}" "${expected}"
}


@test "Should ignore existing environment variables" {
  export VERSION=2.0.0
  result="$(../envy.sh basic.env)"
  expected="export ENVIRONMENT=development"

  assert_equal "${result}" "${expected}"
}

@test "Should load includes" {
  result="$(../envy.sh include.env)"
  expected="export VERSION=1.0.0
export ENVIRONMENT=development
export EXTRA=dane"

  [ "$result" = "$expected" ]
}
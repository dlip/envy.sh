#!/usr/bin/env bats

@test "Should output variables with export prefix" {
  result="$(../envy.sh basic.env)"
  expected="export VERSION=1.0.0
export ENVIRONMENT=development"

  [ "$result" = "$expected" ]
}


@test "Should ignore existing environment variables" {
  export VERSION=2.0.0
  result="$(../envy.sh basic.env)"
  expected="export ENVIRONMENT=development"

  [ "$result" = "$expected" ]
}

@test "Should load includes" {
  result="$(../envy.sh include.env)"
  expected="export VERSION=1.0.0
export ENVIRONMENT=development
export EXTRA=dane"

  [ "$result" = "$expected" ]
}
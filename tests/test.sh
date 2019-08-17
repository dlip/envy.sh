#!/usr/bin/env bats

@test "Should output variables with export prefix" {
  result="$(../envy.sh basic.env)"
  [ "$result" = 'export VERSION=1.0.0' ]
}
#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

@test "Given env-file input and bash output, should output variables with export prefix" {
  result="$(../envy.sh basic.env)"
  expected='export VERSION=1.0.0
export ENVIRONMENT=development'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file with comments, should ignore commented lines" {
  result="$(../envy.sh comments.env)"
  expected='export VERSION=1.0.0
export ENVIRONMENT=development'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file with empty lines, should ignore empty lines" {
  result="$(../envy.sh emptylines.env)"
  expected='export VERSION=1.0.0
export ENVIRONMENT=development'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file input and env-file output, should output variables without export prefix" {
  result="$(../envy.sh basic.env env-file)"
  expected='VERSION=1.0.0
ENVIRONMENT=development'

  assert_equal "${result}" "${expected}"
}

@test "Given existing environment variables, Should not output" {
  export VERSION=2.0.0
  result="$(../envy.sh basic.env)"
  expected='export ENVIRONMENT=development'

  assert_equal "${result}" "${expected}"
}

@test "Given include, should combine output" {
  result="$(../envy.sh include.env)"
  expected='export VERSION=1.0.0
export ENVIRONMENT=development
export NAME=envy'

  assert_equal "${result}" "${expected}"
}

@test "Given multiple includes, should combine output" {
  result="$(../envy.sh multiple-include.env)"
  expected='export VERSION=1.0.0
export ENVIRONMENT=development
export NAME=envy'

  assert_equal "${result}" "${expected}"
}

@test "Given include with low priority, should be overriden" {
  result="$(../envy.sh include-override.env)"
  expected='export ENVIRONMENT=production
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env file which matches internally used variable, should not ignored" {
  result="$(../envy.sh internal-variable.env)"
  expected='export CONTENTS=test'

  assert_equal "${result}" "${expected}"
}

@test "Given value with special characters and bash output, should escape correctly" {
  result="$(../envy.sh escape.env)"
  expected='export PASSWORD=\$\\#GOD#\ /\$'

  assert_equal "${result}" "${expected}"
}

@test "Given value with special characters and make output, should escape correctly" {
  result="$(../envy.sh escape.env make)"
  expected='export PASSWORD=$$\\\#GOD\# /$$'

  assert_equal "${result}" "${expected}"
}

@test "Given relative file locations, should load based on current file location" {
  result="$(../envy.sh relative/file/loading/relative.env)"
  expected='export RELATIVE=relative
export FILE=file
export LOADING=loading'

  assert_equal "${result}" "${expected}"
}

@test "Given file with spaces, should read file correctly" {
  result="$(../envy.sh 'path with spaces/file with spaces.env')"
  expected='export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given ENVY_OVERRIDE_ENV, should output regardless of current environment" {
  export ENVY_OVERRIDE_ENV=true
  export VERSION=1.0.0
  result="$(../envy.sh override-env.env)"
  expected='export VERSION=2.0.0'

  assert_equal "${result}" "${expected}"
}
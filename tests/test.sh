#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'


TEST_FILE1=test-out.env
TEST_FILE2=test-out2.env
teardown() {
	rm -f "${TEST_FILE1}"
	rm -f "${TEST_FILE2}"
}

@test "Given env-file input and bash output, should output variables with export prefix" {
  result="$(../envy.sh basic.env)"
  expected='export ENVIRONMENT=development
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file with comments, should ignore commented lines" {
  result="$(../envy.sh comments.env)"
  expected='export ENVIRONMENT=development
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file with empty lines, should ignore empty lines" {
  result="$(../envy.sh emptylines.env)"
  expected='export ENVIRONMENT=development
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file input with unsorted lines, should sort the output" {
  result="$(../envy.sh sort.env)"
  expected='export A=first
export B=second'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file input and env-file output, should output variables with env-file syntax" {
  result="$(../envy.sh basic.env env-file)"
  expected='ENVIRONMENT=development
VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file input and make output, should output variables with make syntax" {
  result="$(../envy.sh basic.env make)"
  expected='export ENVIRONMENT:=development
export VERSION:=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given include, should combine output" {
  result="$(../envy.sh include.env)"
  expected='export ENVIRONMENT=development
export NAME=envy
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given multiple includes, should combine output" {
  result="$(../envy.sh multiple-include.env)"
  expected='export ENVIRONMENT=development
export NAME=envy
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given include at top of file, should be overriden by following declarations" {
  result="$(../envy.sh include-override.env)"
  expected='export ENVIRONMENT=production
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env file which matches internally used variable, should not be ignored" {
  result="$(../envy.sh internal-variable.env)"
  expected='export ENVY_NAMESPACE=test'

  assert_equal "${result}" "${expected}"
}

@test "Given value with special characters and bash output, should escape correctly" {
  result="$(../envy.sh escape.env)"
  expected='export PASSWORD=\$\\#GOD#\'\''\"\ =\/\$'

  assert_equal "${result}" "${expected}"
}

@test "Given value with special characters and make output, should escape correctly" {
  result="$(../envy.sh escape.env make)"
  expected='export PASSWORD:=$$\\#GOD\#'\''" =/$$'

  assert_equal "${result}" "${expected}"
}

@test "Given relative file locations, should load based on current file location" {
  result="$(../envy.sh relative/file/loading/relative.env)"
  expected='export FILE=file
export LOADING=loading
export RELATIVE=relative'

  assert_equal "${result}" "${expected}"
}

@test "Given file with spaces, should read file correctly" {
  result="$(../envy.sh 'path with spaces/file with spaces.env')"
  expected='export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}


@test "Given existing environment variables, should be overridden" {
  export VERSION=2.0.0
  result="$(../envy.sh basic.env)"
  expected='export ENVIRONMENT=development
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file input with templating, should be evaluated" {
  export VERSION=1.0.0
  result="$(../envy.sh templating.env)"
  expected='export DOUBLE=envy-1.0.0-pro
export DOUBLE_NO_CLOSE=envy-{{VERSION-pro
export DOUBLE_OPEN={{NAME-1.0.0-pro
export NAME=envy
export NOT_TEMPLATE=envy-{{}}-pro
export NO_CLOSE_END=envy-{{
export NO_CLOSE_MIDDLE=envy-{{-pro
export NO_CLOSE_START={{-envy
export VAR_END=envy-1.0.0
export VAR_ESCAPE=envy-{{NOTVAR}}-pro
export VAR_MIDDLE=envy-1.0.0-pro
export VAR_START=1.0.0-pro
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file input with templating and environment variable, should be evaluated" {
  export VERSION=1.0.0
  result="$(../envy.sh templating-env.env)"
  expected='export NAME=envy-1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given include with tempating, should be evaluated before including" {
  result="$(../envy.sh include-templating.env)"
  expected='export BASIC=basic.env
export ENVIRONMENT=development
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}


@test "Given templated value with special characters and bash output, should escape correctly" {
  result="$(../envy.sh templating-escape.env)"
  expected='export PASSWORD=\$\\#GOD#\'\''\"\ =\/\$
export TEMPLATED_PASSWORD=templated-\$\\#GOD#\'\''\"\ =\/\$'

  assert_equal "${result}" "${expected}"
}

@test "Given templated value and non-existant variable, should throw error" {
  run ../envy.sh templating-error.env
  assert_failure
}

@test "Given output file, should write to file" {
  ../envy.sh basic.env env-file test-out.env
  result="$(cat test-out.env)"
  expected='ENVIRONMENT=development
VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given output file and run twice, should overwrite the first file" {
  ../envy.sh basic.env env-file test-out.env
  ../envy.sh name.env env-file test-out.env
  result="$(cat test-out.env)"
  expected='NAME=envy'

  assert_equal "${result}" "${expected}"
}


load "${BATS_SUPPORT}/load.bash"
load "${BATS_ASSERT}/load.bash"
load "${BATS_FILE}/load.bash"

TEST_FILE1="$out/test-out1.env"
TEST_FILE2="$out/test-out2.env"
teardown() {
  rm -f "${TEST_FILE1}"
  rm -f "${TEST_FILE2}"
}

@test "Given env-file input and bash output, should output variables with export prefix" {
  result="$($ENVY basic.env)"
  expected='export ENVIRONMENT=development
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file with comments, should ignore commented lines" {
  result="$($ENVY comments.env)"
  expected='export ENVIRONMENT=development
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file with empty lines, should ignore empty lines" {
  result="$($ENVY emptylines.env)"
  expected='export ENVIRONMENT=development
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given empty env-file, should not error" {
  result="$($ENVY empty.env)"
}

@test "Given env-file input with unsorted lines, should sort the output" {
  result="$($ENVY sort.env)"
  expected='export A=first
export B=second'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file input and env-file output, should output variables with env-file syntax" {
  result="$($ENVY basic.env env-file)"
  expected='ENVIRONMENT=development
VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file input and make output, should output variables with make syntax" {
  result="$($ENVY basic.env make)"
  expected='export ENVIRONMENT:=development
export VERSION:=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file input and github-actions output, should output variables with github-actions syntax" {
  result="$(GITHUB_ENV=/dev/stdout $ENVY basic.env github-actions)"
  expected='ENVIRONMENT=development
VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given include, should combine output" {
  result="$($ENVY include.env)"
  expected='export ENVIRONMENT=development
export NAME=envy
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given multiple includes, should combine output" {
  result="$($ENVY multiple-include.env)"
  expected='export ENVIRONMENT=development
export NAME=envy
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given include at top of file, should be overriden by following declarations" {
  result="$($ENVY include-override.env)"
  expected='export ENVIRONMENT=production
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env file which matches internally used variable, should not be ignored" {
  result="$($ENVY internal-variable.env)"
  expected='export ENVY_NAMESPACE=test'

  assert_equal "${result}" "${expected}"
}

@test "Given value with special characters and bash output, should escape correctly" {
  result="$($ENVY escape.env)"
  expected='export PASSWORD=\$\\#GOD#\'\''\"\ =\/\$\{\}'

  assert_equal "${result}" "${expected}"
}

@test "Given value with special characters and make output, should escape correctly" {
  result="$($ENVY escape.env make)"
  expected='export PASSWORD:=$$\\#GOD\#'\''" =/$${}'

  assert_equal "${result}" "${expected}"
}

@test "Given relative file locations, should load based on current file location" {
  result="$($ENVY relative/file/loading/relative.env)"
  expected='export FILE=file
export LOADING=loading
export RELATIVE=relative'

  assert_equal "${result}" "${expected}"
}

@test "Given file with spaces, should read file correctly" {
  result="$($ENVY 'path with spaces/file with spaces.env')"
  expected='export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}


@test "Given existing environment variables, should be overridden" {
  export VERSION=2.0.0
  result="$($ENVY basic.env)"
  expected='export ENVIRONMENT=development
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file input with templating, should be evaluated" {
  export VERSION=1.0.0
  result="$($ENVY templating.env)"
  expected='export DOUBLE=envy-1.0.0-pro
export DOUBLE_NO_CLOSE=envy-\{\{VERSION-pro
export DOUBLE_OPEN=\{\{NAME-1.0.0-pro
export NAME=envy
export NOT_TEMPLATE=envy-\{\{\}\}-pro
export NO_CLOSE_END=envy-\{\{
export NO_CLOSE_MIDDLE=envy-\{\{-pro
export NO_CLOSE_START=\{\{-envy
export VAR_END=envy-1.0.0
export VAR_ESCAPE=envy-\{\{NOTVAR\}\}-pro
export VAR_MIDDLE=envy-1.0.0-pro
export VAR_START=1.0.0-pro
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given env-file input with templating and environment variable, should be evaluated" {
  export VERSION=1.0.0
  result="$($ENVY templating-env.env)"
  expected='export NAME=envy-1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given include with tempating, should be evaluated before including" {
  result="$($ENVY include-templating.env)"
  expected='export BASIC=basic.env
export ENVIRONMENT=development
export VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}


@test "Given templated value with special characters and bash output, should escape correctly" {
  result="$($ENVY templating-escape.env)"
  expected='export PASSWORD=\$\\#GOD#\'\''\"\ =\/\$\{\}
export TEMPLATED_PASSWORD=templated-\$\\#GOD#\'\''\"\ =\/\$\{\}'

  assert_equal "${result}" "${expected}"
}

@test "Given templated value and non-existant variable, should throw error" {
  run $ENVY templating-error.env
  assert_failure
}

@test "Given output file, should write to file" {
  $ENVY basic.env env-file $TEST_FILE1
  result="$(cat $TEST_FILE1)"
  expected='ENVIRONMENT=development
VERSION=1.0.0'

  assert_equal "${result}" "${expected}"
}

@test "Given output file and run twice, should overwrite the first file" {
  $ENVY basic.env env-file $TEST_FILE1
  $ENVY name.env env-file $TEST_FILE1
  result="$(cat $TEST_FILE1)"
  expected='NAME=envy'

  assert_equal "${result}" "${expected}"
}


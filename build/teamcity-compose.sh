#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${0}")/teamcity-support.sh"

tc_prepare

tc_start_block "Prepare environment for compose tests"
# Disable global -json flag.
type=$(GOFLAGS=; go env GOOS)
tc_end_block "Prepare environment for compose tests"

tc_start_block "Compile CockroachDB"
# Buffer noisy output and only print it on failure.
run pkg/compose/prepare.sh &> artifacts/compose-compile.log || (cat artifacts/compose-compile.log && false)
rm artifacts/compose-compile.log
tc_end_block "Compile CockroachDB"

tc_start_block "Compile compose tests"
run build/builder.sh mkrelease "$type" -Otarget testbuild PKG=./pkg/compose TAGS=compose
tc_end_block "Compile compose tests"

tc_start_block "Run compose tests"
# NB: we're cheating go test into invoking our `compose.test` over the one it
# builds itself. Note that ./pkg/compose without tags builds an empty test
# binary.
run_json_test go test -json -v -timeout 30m -exec ../../build/teamcity-go-test-precompiled.sh ./compose.test ./pkg/compose
tc_end_block "Run compose tests"

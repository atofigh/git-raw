#!/usr/bin/env bash

set -u
set -o pipefail

test_name=$(basename "${0%.sh}")
[ -n "$test_name" ] || { echo >&2 "error: could not detect test name"; exit 1; }

logfile="$logdir/$test_name.log"

test_init_should_fail_outside_git_repository ()
{
    test_begin "$logfile" "$FUNCNAME"
    mkdir not-repo
    cd not-repo
    git raw init
    expect_fail $?
}

echo -n "$test_name"
ret=0
test_init_should_fail_outside_git_repository; ret=$((ret + $?))


if [ $ret -eq 0 ]; then
    echo pass
    exit 0
else
    echo fail
    exit 1
fi

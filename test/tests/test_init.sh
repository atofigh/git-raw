#!/usr/bin/env bash

set -e
set -u
set -o pipefail

test_name=$(basename "${0%.sh}")
[[ -n "$test_name" ]] || { echo >&2 "error: could not detect test name"; exit 1; }

logfile="$logdir/$test_name.log"
: > "$logfile"
mkdir "$test_name"
cd "$test_name"
testdir=$(pwd)

num_fails=0

test_init_should_fail_outside_git_repository ()
{
    cd "$testdir"
    test_begin "$logfile" "$FUNCNAME"

    mkdir not-repo
    cd not-repo

    set +e
    git raw init
    expect_fail $? || (( num_fails += 1 ))
    set -e
}

test_init_should_create_directory_structure ()
{
    cd "$testdir"
    test_begin "$logfile" "$FUNCNAME"

    git init a-repo
    cd a-repo
    git raw init

    set +e
    [[ -f .git/git-raw/config && -d .git/git-raw/index ]]
    expect_success $? || (( num_fails += 1 ))
    set -e
}

test_init_should_do_nothing_if_already_initialized ()
{
    cd "$testdir"
    test_begin "$logfile" "$FUNCNAME"

    git init b-repo
    cd b-repo
    git raw init
    local before=$(find .)
    git raw init
    local after=$(find .)

    set +e
    [[ $before == $after ]]
    expect_success $? || (( num_fails += 1 ))
    set -e
}

test_init_should_fail_gracefully_when_lacking_write_permissions ()
{
    set -e
    cd "$testdir"
    test_begin "$logfile" "$FUNCNAME"

    git init c-repo
    cd c-repo
    chmod -w .git

    set +e
    git raw init 2>err
    cat err
    { head -n1 err | grep -q '^fatal error:'; } || { head -n1 err | grep -q '^Traceback'; }
    expect_fail $? || (( num_fails += 1 ))
    set -e

    chmod +w .git
}


echo -n "$test_name"
test_init_should_fail_outside_git_repository
test_init_should_create_directory_structure
test_init_should_do_nothing_if_already_initialized
test_init_should_fail_gracefully_when_lacking_write_permissions

cd ..
rm -rf "$test_name"

if [[ $num_fails -eq 0 ]]; then
    echo ' PASS'
    exit 0
else
    echo ' FAIL'
    exit 1
fi

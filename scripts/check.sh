#!/bin/bash

function gh_check_changes {
    git diff-tree --diff-filter=d --dirstat=files,0 -r ${GITHUB_HEAD_REF}..${GITHUB_REF_NAME} -- "*.tf" "*.hcl" "*.tfvars" | sed 's/^[ 0-9.]\+% //g'
}

function clear_caches {
    find $1 -type d -name ".terra*" | xargs rm -rf
    find $1 -type f -name "*.lock*" | xargs rm -rf
}

function test {
    terragrunt init --terragrunt-log-level error --terragrunt-working-dir $1

    if `terragrunt plan --terragrunt-working-dir $1 output-all -json | jq -e '. | select(.type=="change_summary") | .changes | del(.operation) | map(select(. > 0)) | length < 1'`; then
        echo "OK"
    else
        exit 1
    fi
}

function gh_check_states {
    for dir in $(gh_check_changes); do
        clear_caches $dir
        test $dir
    done
}

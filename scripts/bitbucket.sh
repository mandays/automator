#!/bin/bash

function bitbucket_sanitize_branch {
    echo $1 | sed 's/\//-/g' | sed 's/_/-/g'
}

function bitbucket_get_commit_hash {
    echo ${BITBUCKET_COMMIT} | cut -c1-7
}

function bitbucket_get_docker_tag {
    if [[ ! -z "${BITBUCKET_TAG}" ]]; then
        echo ${BITBUCKET_TAG}
    else
        if [[ ! -z "${BITBUCKET_BRANCH}" ]]; then
            bitbucket_sanitize_branch ${BITBUCKET_BRANCH}
        else
            exit 1
        fi
    fi
}

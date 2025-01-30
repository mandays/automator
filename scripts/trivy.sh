#!/bin/bash

ENABLE_TRIVY=`echo "$ENABLE_TRIVY" | awk '{ print tolower($1) }'`

function trivy_env_export {
    export TRIVY_TOKEN=$TRIVY_TOKEN
    export TRIVY_REMOTE=$TRIVY_REMOTE
}

function trivy_scan_image {
    trivy_env_export
    if [[ ${ENABLE_TRIVY} == "true" ]]; then
        trivy client --vuln-type os --severity CRITICAL,HIGH --ignore-unfixed --exit-code 0 $1
    fi
}

function trivy_scan_config {
    if [[ ${ENABLE_TRIVY} == "true" ]]; then
        trivy config --severity CRITICAL,HIGH --exit-code 0 .
    fi
}

function trivy_scan_fs {
    if [[ ${ENABLE_TRIVY} == "true" ]]; then
        trivy fs --severity CRITICAL,HIGH --exit-code 0 .
    fi
}

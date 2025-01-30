#!/bin/bash

source ./bitbucket.sh

function terraform_create_task_definition {
    cd $1
    export TF_VAR_image_tag=$(bitbucket_get_docker_tag)
    export TF_VAR_application_version_hash=$(bitbucket_get_commit_hash)
    terraform init

    i=1
    for arg do
        if [ $i -gt 1 ]; then
            terraform apply -target module.$arg -auto-approve
        fi
        i=$((i + 1))
    done
}

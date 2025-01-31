ARG ALPINE_VERSION=3.20
FROM alpine:${ALPINE_VERSION} AS builder

WORKDIR /tmp

ARG TFLINT_VERSION="0.48.0"
ARG TFSEC_VERSION="1.28.4"
ARG TERRAFORM_DOCS_VERSION="0.16.0"
ARG TRIVY_VERSION="0.45.0"
ARG SNYK_CLI_VERSION="1.1217.0"
ARG GLIBC_VERSION="2.35-r0"
ARG AWSCLI_VERSION="2.17.53"
ARG GO_VERSION="1.22.7-r0"
ARG YQ_VERSION="4.21.1"
ARG CHGLOG_VERSION="0.15.4"
ARG PULUMI_VERSION="3.115.0-r3"
ARG PRE_COMMIT_VERSION="3.7.1-r0"
ARG PIPENV_VERSION="2024.0.1"
ARG TENV_VERSION="4.1.0"

ENV TERRAFORM_LATEST_VERSION="latest"
ENV TERRAGRUNT_LATEST_VERSION="latest"
ENV OPENTOFU_LATEST_VERSION="latest"

RUN apk update && apk upgrade \
    && apk add --no-cache \
        bash \
        build-base \
        ca-certificates \
        curl \
        git \
        gnupg \
        jq \
        libffi-dev \
        make \
        openssh \
        openssl-dev \
        py3-pip \
        pre-commit=${PRE_COMMIT_VERSION} \
        python3 \
        unzip \
        cosign \
        wget \
        binutils \
        pulumi=${PULUMI_VERSION} \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

RUN python -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && pip install --no-cache-dir \
    pipenv==${PIPENV_VERSION}

RUN wget https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64 \
    && mv tfsec-linux-amd64 /usr/local/bin/tfsec \
    && chmod +x /usr/local/bin/tfsec

RUN wget https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz \
    && tar xzf terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz \
    && mv terraform-docs /usr/local/bin/ \
    && chmod +x /usr/local/bin/terraform-docs

RUN wget https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip \
    && unzip tflint_linux_amd64.zip \
    && mv tflint /usr/local/bin/ \
    && chmod +x /usr/local/bin/tflint

RUN wget https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz \
    && tar xzf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz \
    && mv trivy /usr/local/bin/ \
    && chmod +x /usr/local/bin/trivy

RUN wget https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 \
    -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

RUN wget https://github.com/git-chglog/git-chglog/releases/download/v${CHGLOG_VERSION}/git-chglog_${CHGLOG_VERSION}_linux_amd64.tar.gz \
    && tar xzf git-chglog_${CHGLOG_VERSION}_linux_amd64.tar.gz \
    && mv git-chglog /usr/local/bin/ \
    && chmod +x /usr/local/bin/git-chglog


FROM alpine:${ALPINE_VERSION}

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /opt /opt

ARG PULUMI_VERSION="3.115.0-r3"
ARG PRE_COMMIT_VERSION="3.7.1-r0"
ARG AWSCLI_VERSION="2.15.57-r0"
ARG GO_VERSION="1.22.9-r0"
ARG TENV_VERSION="4.1.0"
ENV TENV_AUTO_INSTALL="true"
ARG APP_USER="automator"
ARG APP_GROUP="automator"
ARG WORK_DIR="/automator"

ARG TENV_ROOT="${WORK_DIR}/.tenv"
ARG TOFU_DIR="${TENV_ROOT}/OpenTofu"
ARG TF_DIR="${TENV_ROOT}/Terraform"
ARG TG_DIR="${TENV_ROOT}/Terragrunt"
ARG AT_DIR="${TENV_ROOT}/Atmos"

WORKDIR ${WORK_DIR}


RUN apk update && apk upgrade \
    && apk add --no-cache \
    curl git jq perl cosign \
    pre-commit pulumi aws-cli go \
    tenv --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

ENV PATH=/opt/venv/bin:$PATH

COPY config.yaml ${WORK_DIR}

COPY entrypoint.sh /usr/local/bin/
COPY .pre-commit-config.mandatory.yaml ${WORK_DIR}
COPY scripts ${WORK_DIR}
COPY .chglog ${WORK_DIR}/.chglog

COPY tenv/OpenTofu/version ${TOFU_DIR}/
COPY tenv/Terraform/version ${TF_DIR}/
COPY tenv/Terragrunt/version ${TG_DIR}/
COPY tenv/Atmos/version ${AT_DIR}/

RUN addgroup -S ${APP_GROUP} \
    && adduser -S ${APP_USER} -G ${APP_GROUP} \
    && chown -R ${APP_USER}:${APP_GROUP} ${WORK_DIR}

ENTRYPOINT ["entrypoint.sh"]

USER ${APP_USER}

ARG ALPINE_VERSION=3.22.2
FROM alpine:${ALPINE_VERSION} AS builder

WORKDIR /tmp

ARG TFLINT_VERSION="0.59.1"
ARG TFSEC_VERSION="1.28.14"
ARG TERRAFORM_DOCS_VERSION="0.20.0"
ARG TRIVY_VERSION="0.67.2"
ARG YQ_VERSION="4.48.1"
ARG CHGLOG_VERSION="0.15.4"

ARG PIPENV_VERSION="2025.0.3"

RUN apk update && apk upgrade \
    && apk add --no-cache \
        bash=5.2.37-r0 \
        build-base=0.5-r3 \
        ca-certificates=20250911-r0 \
        curl=8.14.1-r2 \
        git=2.49.1-r0 \
        gnupg=2.4.7-r0 \
        jq=1.8.0-r0 \
        libffi-dev=3.4.8-r0 \
        make=4.4.1-r3 \
        openssh=10.0_p1-r9 \
        openssl-dev=3.5.4-r0 \
        py3-pip=25.1.1-r0 \
        python3=3.12.12-r0 \
        unzip=6.0-r15 \
        cosign=2.4.3-r6 \
        wget=1.25.0-r1 \
        binutils=2.44-r3 \
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

ARG PULUMI_VERSION="3.170.0-r3"
ARG PRE_COMMIT_VERSION="4.2.0-r0"
ARG AWSCLI_VERSION="2.27.25-r0"
ARG GO_VERSION="1.24.9-r0"

ARG TENV_VERSION="4.7.6-r4"
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
    curl=8.14.1-r2 \
    git=2.49.1-r0 \
    jq=1.8.0-r0 \
    perl=5.40.3-r0 \
    cosign=2.4.3-r6 \
    pre-commit=${PRE_COMMIT_VERSION} \
    pulumi=${PULUMI_VERSION} \
    aws-cli=${AWSCLI_VERSION} \
    go=${GO_VERSION} \
    tenv --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

ENV PATH=/opt/venv/bin:$PATH

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

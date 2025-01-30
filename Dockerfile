ARG ALPINE_VERSION=3.20
FROM alpine:${ALPINE_VERSION} AS builder

WORKDIR /tmp

ARG TFENV_PATH="/opt/tfenv"
ARG TFENV_VERSION="3.0.0"
ARG TGENV_PATH="/opt/tgenv"
ARG TGENV_VERSION="0.0.3"
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

ENV TERRAFORM_LATEST_VERSION="latest"
ENV TERRAGRUNT_LATEST_VERSION="latest"

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
        wget \
        binutils \
        pulumi=${PULUMI_VERSION} \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

RUN python -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && pip install --no-cache-dir \
    pipenv==${PIPENV_VERSION}

RUN wget https://github.com/tfutils/tfenv/archive/refs/tags/v${TFENV_VERSION}.tar.gz \
    && mkdir -p ${TFENV_PATH} \
    && tar xzf v${TFENV_VERSION}.tar.gz -C ${TFENV_PATH} --strip-components=1 \
    && ln -s ${TFENV_PATH}/bin/* /usr/local/bin/ \
    && tfenv install ${TERRAFORM_LATEST_VERSION}

RUN wget https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64 \
    && mv tfsec-linux-amd64 /usr/local/bin/tfsec \
    && chmod +x /usr/local/bin/tfsec

RUN wget https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz \
    && tar xzf terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz \
    && mv terraform-docs /usr/local/bin/ \
    && chmod +x /usr/local/bin/terraform-docs

RUN wget https://github.com/cunymatthieu/tgenv/archive/refs/tags/v${TGENV_VERSION}.tar.gz \
    && mkdir -p ${TGENV_PATH} \
    && tar xzf v${TGENV_VERSION}.tar.gz -C ${TGENV_PATH} --strip-components=1 \
    && ln -s ${TGENV_PATH}/bin/* /usr/local/bin/ \
    && tgenv install ${TERRAGRUNT_LATEST_VERSION}

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
ENV TERRAFORM_VERSION="1.9.5"
ENV TERRAGRUNT_VERSION="0.66.9"

ARG TFENV_PATH="/opt/tfenv"
ARG TGENV_PATH="/opt/tgenv"
ARG APP_USER="automator"
ARG APP_GROUP="automator"
ARG WORK_DIR="/automator"
WORKDIR ${WORK_DIR}

RUN apk update && apk upgrade \
    && apk add --no-cache \
    curl git jq perl \
    pre-commit pulumi aws-cli go

ENV PATH=/opt/venv/bin:$PATH

COPY config.yaml ${WORK_DIR}

RUN yq '.packages.terraform' config.yaml | sed 's/- //g' | xargs -n 1 tfenv install \
    && yq '.packages.terragrunt' config.yaml | sed 's/- //g' | xargs -n 1 tgenv install

COPY entrypoint.sh /usr/local/bin/
COPY .pre-commit-config.mandatory.yaml ${WORK_DIR}
COPY scripts ${WORK_DIR}
COPY .chglog ${WORK_DIR}/.chglog

RUN addgroup -S ${APP_GROUP} \
    && adduser -S ${APP_USER} -G ${APP_GROUP} \
    && chown -R ${APP_USER}:${APP_GROUP} ${WORK_DIR} \
    && chown -R ${APP_USER}:${APP_GROUP} ${TFENV_PATH} \
    && chown -R ${APP_USER}:${APP_GROUP} ${TGENV_PATH} \
    && tgenv use ${TERRAGRUNT_VERSION} \
    && tfenv use ${TERRAFORM_VERSION}

ENTRYPOINT ["entrypoint.sh"]

USER ${APP_USER}

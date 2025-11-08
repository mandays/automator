# Copilot Instructions for automator Repository

## Overview

**Purpose**: Docker container for GitHub Actions providing Terraform/Terragrunt/OpenTofu automation with pre-commit hooks and security scanning.
**Type**: Docker container (Alpine Linux 3.22) | **Size**: ~50 files, 500 LOC | **Languages**: Bash, Dockerfile, YAML
**Tools**: Terraform, OpenTofu, Terragrunt, Atmos (tenv), AWS CLI, Pulumi, Trivy, tfsec, tflint, gitleaks, git-chglog

## Validation & Build

### Pre-commit (CRITICAL - only validation method)

**Setup**: `pip install pre-commit && pre-commit install`
**Run**: `pre-commit run --all-files` (2-3 min first run, then 10-30 sec)
**Checks**: merge-conflict, whitespace, EOL, secrets, JSON/YAML, Terraform/Terragrunt (if applicable), gitleaks

**Commit format** (required):
```
<type>(<scope>): <subject>
Types: feat|fix|refactor|chore|docs|test|ci
```

### Docker Build

**Local builds fail** (Alpine network restrictions) - rely on CI. Build command: `docker build -t automator:local .`

### CI Workflows

- **pre-commit.yaml**: Runs pre-commit on PRs/main (container: ghcr.io/mandays/automator:latest as root)
- **release.yaml**: Tags `v*.*.*` → builds image, generates changelog, creates release

## Project Structure

```
├── Dockerfile                        # Multi-stage: builder (downloads tools) + final (runtime)
├── entrypoint.sh                     # Wrapper: bash -c "set -e; set -o pipefail; $1"
├── .pre-commit-config.yaml           # Main hooks: security, linting, formatting
├── .editorconfig                     # 4sp default, 2sp YAML/HCL/TF, tabs Makefile
├── .github/workflows/
│   ├── pre-commit.yaml               # CI: runs pre-commit in container
│   └── release.yaml                  # Builds Docker image, creates release
├── scripts/                          # Bash utilities
│   ├── aws.sh                        # ECR authentication
│   ├── bitbucket.sh                  # Docker tag generation
│   ├── check.sh                      # Terragrunt validation
│   ├── terraform.sh                  # ECS task definitions
│   └── trivy.sh                      # Security scanning
└── tenv/*/version                    # IaC tool versions: Terraform 1.9.5, OpenTofu 1.9.0, Terragrunt 0.72.5, Atmos 1.157.0
```

**Version locations**: Dockerfile ARG (lines 6-13, 76-79), tenv/*/version files

## Common Tasks & Rules

**Update version**:
1. Edit Dockerfile ARG (lines 6-13, 76-79) + tenv/*/version if IaC tool
2. Run pre-commit
3. Commit: `chore(deps): update trivy to v0.65.0`

**Create release**: `git tag v1.2.3 && git push origin v1.2.3` (CI handles rest)

**DO**: Run pre-commit always | Use conventional commits | Pin versions | Sync Dockerfile+tenv versions
**DON'T**: Expect local Docker builds to work | Skip pre-commit | Add tests | Commit secrets

**Known issues**: Docker build fails locally (expected) | First pre-commit slow (normal) | Terraform hooks skip (no .tf files)

**Container usage**:
```yaml
container:
  image: ghcr.io/mandays/automator:latest
  options: --user root
steps:
  - run: git config --global --add safe.directory "$GITHUB_WORKSPACE"
```

**Env vars**: ENABLE_TRIVY, TENV_AUTO_INSTALL, AWS_*, BITBUCKET_*

**Trust these instructions** - only search for undocumented errors or new capabilities.

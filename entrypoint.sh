#!/bin/bash

set -e
set -o pipefail

bash -c "set -e;  set -o pipefail; $1"

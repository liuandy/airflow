#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

SCRIPTS_CI_DIR=$(dirname "${BASH_SOURCE[0]}")

# shellcheck source=scripts/ci/libraries/_initialization.sh
. "${SCRIPTS_CI_DIR}"/../libraries/_initialization.sh
get_environment_for_builds_on_ci

git remote add target "https://github.com/${CI_TARGET_REPO}"
git fetch target "${CI_TARGET_BRANCH}:${CI_TARGET_BRANCH}" --depth=1

echo "Diffing openapi spec against ${CI_TARGET_BRANCH}..."

SPEC_FILE=airflow/api_connexion/openapi/v1.yaml
if ! git diff --name-only "${CI_TARGET_BRANCH}" HEAD | grep "${SPEC_FILE}" ; then
    echo "no openapi spec change detected, going to skip client code gen validation."
    exit 0
fi

echo "openapi spec change detected. comparing codegen diff..."

mkdir -p ./clients/go/airflow
./clients/gen/go.sh ./airflow/api_connexion/openapi/v1.yaml ./clients/go/airflow
mkdir -p ./clients/go_target_branch/airflow
git checkout "${CI_TARGET_BRANCH}" ./airflow/api_connexion/openapi/v1.yaml
./clients/gen/go.sh ./airflow/api_connexion/openapi/v1.yaml ./clients/go_target_branch/airflow
diff ./clients/go_target_branch/airflow ./clients/go/airflow || true

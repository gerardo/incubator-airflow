#!/usr/bin/env bash
#
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
#  specific language governing permissions and limitations
#  under the License.

set -x

DIRNAME=$(cd "$(dirname "$0")"; pwd)
AIRFLOW_ROOT="$DIRNAME/../.."

nose_args=$@
# Fix file permissions
sudo chown -R airflow.airflow . $HOME/.cache $HOME/.wheelhouse/ $HOME/.cache/pip

sudo -H pip3 install --upgrade pip
sudo -H pip3 install tox

cd $AIRFLOW_ROOT && pip3 --version && tox --version

if [ -z "$KUBERNETES_VERSION" ];
then
  tox -e $TOX_ENV $nose_args
else
  if [ ! -d /home/travis ]; then
    sudo mkdir -p /home/travis
  fi
  NOSE_ARGS=("--with-coverage"
            "--cover-erase"
            "--cover-html"
            "--cover-package=airflow"
            "--cover-html-dir=airflow/www/static/coverage"
            "--with-ignore-docstrings"
            "--rednose"
            "--with-timer"
            "-v"
            "--logging-level=INFO")

  ./scripts/ci/kubernetes/setup_kubernetes.sh
  ./scripts/ci/kubernetes/deploy_app.sh -d persistent_mode
  tox -e "$TOX_ENV" -- tests.integration.kubernetes "${NOSE_ARGS[@]}"

  ./scripts/ci/kubernetes/deploy_app.sh -d git_mode
  tox -e "$TOX_ENV" -- tests.integration.kubernetes "${NOSE_ARGS[@]}"
fi

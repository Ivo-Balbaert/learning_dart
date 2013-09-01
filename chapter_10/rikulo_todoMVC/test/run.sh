#!/bin/bash

# bail on error
set -e

DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )

# Note: dartanalyzer needs to be run from the root directory for proper path
# canonicalization.
pushd $DIR/..
echo Analyzing web/app.dart
dartanalyzer --fatal-warnings --fatal-type-errors web/app.dart \
  || echo -e "Ignoring analyzer errors"

rm -rf out/*
popd

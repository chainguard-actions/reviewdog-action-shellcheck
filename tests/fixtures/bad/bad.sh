#!/bin/bash
# Intentionally broken script for shellcheck tests.
foo=$1
echo $foo
if [ "$foo" = "x" ]; then
  echo "missing fi"

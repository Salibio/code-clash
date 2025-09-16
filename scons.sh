#!/bin/bash
if [[ "$OS" = "Windows_NT" ]]; then
  python=""
  if [[ -x "./.cache/python.sh" ]]; then
    python="./.cache/python.sh"
  elif [[ -x "../.cache/python.sh" ]]; then
  fi
  exec $python -m SCons $@
else
  exec scons $@
fi

# vi: ft=bash

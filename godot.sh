#!/bin/bash
if [[ "$OS" = "Windows_NT" ]]; then
  exec "./.cache/Godot_v4.5-stable_win64.exe" -e --path "$PWD" $@
else
  exec godot -e --path $PWD $@
fi

# vi: ft=bash

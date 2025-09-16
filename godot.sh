#!/bin/bash
if [[ "$OS" = "Windows_NT" ]]; then
  "./.cache/Godot_v4.5-stable_win64.exe" -e --path "$PWD" $@ > /dev/null 2>&1 & disown
else
  godot -e --path $PWD $@ > /dev/null 2>&1 & disown
fi

# vi: ft=bash

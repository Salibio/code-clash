#!/bin/bash

set -e

cache_dir="$PWD/.cache"

download() {
  local out=$1
  local url=$2
  echo "downloading $out from $url"
  mkdir -p "$cache_dir"
  echo curl -L -C - -f -o "$out" "$url"
  if [[ ! $(curl -L -C - -f -o "$out" "$url") ]]; then
    echo "error: failed to download $zipfile"
    exit 1
  fi
}

init_addons() {
  local url="https://github.com/limbonaut/limboai/releases/download/v1.4.1/limboai+v1.4.1.gdextension-4.4.zip"
  local addon="$(basename $url)"
  local zipfile="$cache_dir/$addon"
  if [[ ! -d "$PWD/addons/limboai" ]]; then
    if [[ ! -f "$zipfile" ]]; then
      download "$zipfile" "$url"
    fi
    unzip -n "$zipfile" 'addons/**/*'
  fi
}

init_justfile() {
  local url="https://github.com/casey/just/releases/download/1.42.4/just-1.42.4-x86_64-pc-windows-msvc.zip"
  local zipfile="$cache_dir/$(basename $url)"
  if [[ ! -f "$zipfile" ]]; then
    download "$zipfile" "$url"
  fi
  unzip -n "$zipfile" 'just.exe' -d "$cache_dir"
}

init_godot() {
  local url="https://github.com/godotengine/godot/releases/download/4.5-stable/Godot_v4.5-stable_win64.exe.zip"
  local zipfile="$cache_dir/$(basename $url)"
  if [[ ! -f "$zipfile" ]]; then
    download "$zipfile" "$url"
  fi
  unzip -n "$zipfile" -d "$cache_dir"
}

init_submodules() {
  git submodule update --init --recursive
}

init_scons() {
  local url="https://www.python.org/ftp/python/3.13.7/python-3.13.7-amd64.exe"
  local file="$cache_dir/$(basename $url)"
  if [[ ! -f "$file" ]]; then
    download "$file" "$url"
  fi

  local python_bin="python"
  if python --version; then
    python_bin="python"
  elif python3 --version; then
    python_bin="python3"
  elif python313 --version; then
    python_bin="python313"
  elif '/c/Program Files/Python313/python' --version; then
    python_bin="/c/Program Files/Python313/python"
  fi

  if ! type "$python_bin"; then
    cmd //c "$(cygpath -w $file) /passive /norestart InstallAllUsers=1 Include_pip=1 PrependPath=1"
  fi

  if ! "$python_bin" -m SCons --version; then
    "$python_bin" -m pip install scons
  fi
}

init_compiler() {
  local url="https://github.com/msys2/msys2-installer/releases/download/2025-06-22/msys2-x86_64-20250622.exe"
  local file="$cache_dir/$(basename $url)"
  if [[ ! -f "$file" ]]; then
    download "$file" "$url"
  fi
  if [[ ! -d '/c/msys64' ]]; then
    $file in --confirm-command --accept-messages --root 'C:/msys64'
    powershell -Command 'setx PATH "%PATH%;C:/msys64/mingw64/bin"'
  fi
  local pacman="/c/msys64/usr/bin/pacman"
  $pacman -S mingw-w64-x86_64-gcc mingw-w64-i686-gcc --noconfirm --needed

  ./just.sh build-library build-windows-x86_64
  ./just.sh build-windows-x86_64
}

init_addons
init_submodules
if [[ "$OS" = "Windows_NT" ]]; then
  init_justfile
  init_godot
  init_scons
  init_compiler
fi

echo
echo -e "\033[32mInitialized Successfully!\033[0m"
echo -e "Enter './godot.sh' (without quotes) to open godot engine!"

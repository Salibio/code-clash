compiledb := "no"
compile_commands := if compiledb == "yes" { "compiledb" } else { "" }
api_dir := "src/api/"
build_library := "no"
mode := "debug"
flag_target := if mode == "debug" {
  "target=template_debug debug_symbols=yes use_hot_reload=yes generate_bindings=yes"
} else if mode == "release" {
  "target=template_release"
} else {
  error("unknown mode: " + mode)
}
scons := if os() == "windows" {
  "./scons.sh"
} else {
  "scons"
}
just := if os() == "windows" {
  "./just.sh"
} else {
  "just"
}
mingw := if os() == "windows" {
  "mingw_prefix='C:/msys64/mingw64' use_mingw=yes"
} else {
  "mingw_prefix='/' use_mingw=no"
}

build-linux $SCONS_CACHE="build-linux":
  {{scons}} {{compile_commands}} -j4 {{flag_target}} use_llvm=yes gdextension_dir={{api_dir}} build_library={{build_library}} platform=linux

build-android-arm32 $SCONS_CACHE="build-android-arm32":
  {{scons}} {{compile_commands}} -j4 {{flag_target}} use_llvm=yes gdextension_dir={{api_dir}} build_library={{build_library}} platform=android arch=arm32
build-android-arm64 $SCONS_CACHE="build-android-arm64":
  {{scons}} {{compile_commands}} -j4 {{flag_target}} use_llvm=yes gdextension_dir={{api_dir}} build_library={{build_library}} platform=android arch=arm64

build-android-x86_32 $SCONS_CACHE="build-android-x86_32":
  {{scons}} {{compile_commands}} -j4 {{flag_target}} use_llvm=yes gdextension_dir={{api_dir}} build_library={{build_library}} platform=android arch=x86_32
build-android-x86_64 $SCONS_CACHE="build-android-x86_64":
  {{scons}} {{compile_commands}} -j4 {{flag_target}} use_llvm=yes gdextension_dir={{api_dir}} build_library={{build_library}} platform=android arch=x86_64

build-windows-x86_32 $SCONS_CACHE="build-windows-x86_32":
  {{scons}} {{compile_commands}} {{flag_target}} use_llvm=no gdextension_dir={{api_dir}} build_library={{build_library}} mingw_prefix='C:/msys64/mingw64' {{mingw}} platform=windows arch=x86_32
build-windows-x86_64 $SCONS_CACHE="build-windows-x86_64":
  {{scons}} {{compile_commands}} {{flag_target}} use_llvm=no gdextension_dir={{api_dir}} build_library={{build_library}} mingw_prefix='C:/msys64/mingw64' {{mingw}} platform=windows arch=x86_64

build-android: build-android-arm32 build-android-arm64 build-android-x86_32 build-android-x86_64

build-windows: build-windows-x86_32 build-windows-x86_64

build: build-linux build-android build-windows

build-library *args='':
  {{just}} --working-directory godot-cpp --justfile justfile.godot-cpp --set mode debug {{args}}
build-library-release *args='':
  {{just}} --working-directory godot-cpp -f justfile.godot-cpp --set mode release {{args}}

debug godot="godot" *args='':
  gdb --args {{godot}} {{args}}

remove-empty-folders:
  find . -empty -type d ! -path '*/.git*' ! -path '*/.git*/*' ! -path '*/.godot*' ! -path '*/android' -exec rmdir {} \;


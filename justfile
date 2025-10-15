compiledb := "no"
compile_commands := if compiledb == "yes" { "compiledb" } else { "" }
api_dir := "src/api/"
build_library := "no"
mode := "debug"
android_flags := "ndk_version=28.2.13676358"
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
use_llvm := "yes"
job := `nproc`

build-linux *ARGS="":
  {{scons}} {{compile_commands}} -j{{job}} {{flag_target}} use_llvm={{use_llvm}} gdextension_dir={{api_dir}} build_library={{build_library}} platform=linux

build-android-arm32 *ARGS="":
  {{scons}} {{compile_commands}} -j{{job}} {{flag_target}} use_llvm={{use_llvm}} gdextension_dir={{api_dir}} build_library={{build_library}} platform=android {{android_flags}} arch=arm32
build-android-arm64 *ARGS="":
  {{scons}} {{compile_commands}} -j{{job}} {{flag_target}} use_llvm={{use_llvm}} gdextension_dir={{api_dir}} build_library={{build_library}} platform=android {{android_flags}} arch=arm64

build-android-x86_32 *ARGS="":
  {{scons}} {{compile_commands}} -j{{job}} {{flag_target}} use_llvm={{use_llvm}} gdextension_dir={{api_dir}} build_library={{build_library}} platform=android {{android_flags}} arch=x86_32
build-android-x86_64 *ARGS="":
  {{scons}} {{compile_commands}} -j{{job}} {{flag_target}} use_llvm={{use_llvm}} gdextension_dir={{api_dir}} build_library={{build_library}} platform=android {{android_flags}} arch=x86_64

build-windows-x86_32 *ARGS="":
  {{scons}} {{compile_commands}} {{flag_target}} use_llvm=no gdextension_dir={{api_dir}} build_library={{build_library}} mingw_prefix='C:/msys64/mingw64' {{mingw}} platform=windows arch=x86_32
build-windows-x86_64 *ARGS="":
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

build-continue:
  fd --search-path $PWD/src '.*(cpp|hpp|c|h)$' | entr -cr ./just.sh build-linux

build-continue-verbose:
  fd --search-path $PWD/src --search-path=$PWD/godot-cpp '.*(cpp|hpp|c|h)$' | entr -cr ./just.sh build_library=yes build-linux


#!/usr/bin/env python
import os
import sys

env = SConscript("godot-cpp/SConstruct")

# For reference:
# - CCFLAGS are compilation flags shared between C and C++
# - CFLAGS are for C-specific compilation flags
# - CXXFLAGS are for C++-specific compilation flags
# - CPPFLAGS are for pre-processor flags
# - CPPDEFINES are for pre-processor defines
# - LINKFLAGS are for linking flags

# tweak this if you want to use different folders, or more folders, to store your source code in.
env.Append(
  CPPPATH=[
    "src/",
    "./src/deps/cpp-tree-sitter/include/",
    "./src/deps/tree-sitter/lib/include/",
    "./src/deps/tree-sitter/lib/src/",

    "./src/deps/duktape/src/",
  ],
)
sources = Glob("src/*.cpp")
sources += Glob("./src/deps/tree-sitter/lib/src/lib.c")
sources += Glob("./src/deps/duktape/src/duktape.c")

if os.system("command -v ccache > /dev/null 2>&1") == 0:
  print("Using ccache for compilation.")
  env["CC"] = "ccache " + env["CC"]
  env["CXX"] = "ccache " + env["CXX"]

if env["target"] in ["editor", "template_debug"]:
  try:
    doc_data = env.GodotCPPDocData("src/gen/doc_data.gen.cpp", source=Glob("doc_classes/*.xml"))
    sources.append(doc_data)
  except AttributeError:
    print("Not including class reference as we're targeting a pre-4.3 baseline.")

match env["platform"]:
  case "macos":
    name = "bin/libgodotcpp.{}.{}.framework/libgodotcpp.{}.{}".format(
        env["platform"], env["target"], env["platform"], env["target"])
    library = env.SharedLibrary(name, source=sources)
  case "ios":
    if env["ios_simulator"]:
      name = "bin/libgodotcpp.{}.{}.simulator.a".format(
          env["platform"], env["target"])
      library = env.StaticLibrary(name, source=sources)
    else:
      name = "bin/libgodotcpp.{}.{}.a".format(env["platform"], env["target"])
      library = env.StaticLibrary(name, source=sources)
  case _:
    name = "bin/libgodotcpp{}{}".format(env["suffix"], env["SHLIBSUFFIX"])
    library = env.SharedLibrary(name, source=sources)

CacheDir(".cache/build")
Default(library)


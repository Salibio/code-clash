#pragma once

#include "duk_config.h"
#include "godot_cpp/classes/node.hpp"
#include "godot_cpp/classes/ref.hpp"
#include "godot_cpp/classes/resource.hpp"
#include "godot_cpp/classes/semaphore.hpp"
#include "godot_cpp/classes/thread.hpp"
#include "godot_cpp/classes/wrapped.hpp"
#include "godot_cpp/variant/array.hpp"
#include <gdextension_interface.h>
#include <godot_cpp/godot.hpp>

namespace godot {

class JSEnvironment : public Resource {
  GDCLASS(JSEnvironment, Resource)

private:
protected:
  static void _bind_methods();

public:
  JSEnvironment();
  ~JSEnvironment();

  void eval(String code);
  void eval_async(String code);
  void _eval_pending_code(String code);

  void add_method(Ref<Resource> method_info);
  void _method_finished();

  bool is_running() const;

  duk_context *ctx{nullptr};
  Dictionary object_methods{};
  Ref<Semaphore> semaphore;
  Ref<Thread> thread;

  bool running{false};
  bool first_run{true};
  String pending_code{""};
};

} // namespace godot

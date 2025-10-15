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
  void add_method_v2(Ref<Resource> method_info);
  void method(Ref<Resource> resource);
  void _method_finished();

  bool is_paused() const;
  bool is_running() const;

  void pause();
  void resume();

  duk_context *_ctx{nullptr};
  Dictionary _object_methods{};
  Ref<Semaphore> _semaphore;
  Ref<Thread> _thread;
  bool _paused{false};

  bool _running{false};
  bool _first_run{true};
  String _pending_code{""};
};

} // namespace godot

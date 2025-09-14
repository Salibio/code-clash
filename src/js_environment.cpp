#include "js_environment.h"
#include "duk_config.h"
#include "duktape.h"
#include "godot_cpp/classes/object.hpp"
#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/core/math.hpp"
#include "godot_cpp/core/object.hpp"
#include "godot_cpp/core/print_string.hpp"
#include "godot_cpp/core/property_info.hpp"
#include "godot_cpp/variant/callable_method_pointer.hpp"
#include "godot_cpp/variant/char_string.hpp"
#include "godot_cpp/variant/variant.hpp"
#include <array>
#include <cstddef>
#include <functional>

namespace godot {

#define GD_FORMAT(fmt, ...) String(fmt).format(Array::make(__VA_ARGS__))
#define DUK_THROW(fmt, ...)                                                    \
  {                                                                            \
    String error_msg = String(fmt).format(Array::make(__VA_ARGS__));           \
    CharString msg = error_msg.ascii();                                        \
    return duk_error(ctx, DUK_RET_TYPE_ERROR, msg.ptr());                      \
  }
#define TYPE_ERROR_STRING                                                      \
  ("Invalid argument for '{0}()' function: argument {1} "                      \
   "should be '{2}' but is '{3}'.")

void JSEnvironment::_bind_methods() {
  ClassDB::bind_method(D_METHOD("add_method", "method_info"),
                       &JSEnvironment::add_method);
  ClassDB::bind_method(D_METHOD("eval", "code"), &JSEnvironment::eval);
  ClassDB::bind_method(D_METHOD("eval_async", "code"),
                       &JSEnvironment::eval_async);

  ClassDB::bind_method(D_METHOD("is_running"), &JSEnvironment::is_running);

  ADD_SIGNAL(MethodInfo("finished"));
}

bool JSEnvironment::is_running() const { return running; }

void duk_print_error(duk_context *ctx) {
  duk_get_prop_string(ctx, -1, "name");
  const char *name = duk_safe_to_string(ctx, -1);
  duk_pop(ctx);

  duk_get_prop_string(ctx, -1, "message");
  const char *message = duk_safe_to_string(ctx, -1);
  duk_pop(ctx);

  duk_get_prop_string(ctx, -1, "fileName");
  const char *fileName = duk_safe_to_string(ctx, -1);
  duk_pop(ctx);

  duk_get_prop_string(ctx, -1, "lineNumber");
  duk_int_t lineNumber = duk_get_int_default(ctx, -1, -1);
  duk_pop(ctx);

  duk_get_prop_string(ctx, -1, "stack");
  const char *stack = duk_safe_to_string(ctx, -1);
  duk_pop(ctx);

  print_error(
      GD_FORMAT("{0}:{1}: {2}: {3}", fileName, lineNumber, name, message));
  print_error(GD_FORMAT("{0}", stack));
}

void JSEnvironment::eval(String code) {
  CharString code_cs = code.ascii();

  duk_push_string(ctx, code_cs.ptr());
  duk_push_string(ctx, "main");

  if (duk_pcompile(ctx, 0) != DUK_EXEC_SUCCESS) {
    duk_print_error(ctx);
  } else {
    if (duk_pcall(ctx, 0) != DUK_EXEC_SUCCESS) {
      duk_print_error(ctx);
    }
  }
  duk_pop(ctx);
}

void JSEnvironment::eval_async(String code) {
  if (running) {
    WARN_PRINT("Interpreter is already running!");
    return;
  } else if (!first_run) {
    thread->wait_to_finish();
  }

  running = true;
  first_run = false;
  thread->start(
      callable_mp(this, &JSEnvironment::_eval_pending_code).bind(code));
}

void JSEnvironment::_eval_pending_code(String code) {
  eval(code);
  running = false;
  call_deferred("emit_signal", "finished");
}

void JSEnvironment::_method_finished(String full_path) { semaphore->post(); }

Dictionary obj_to_dict(duk_context *ctx);
// Assuming there is [... array]
Array array_to_array(duk_context *ctx) {
  Array array;

  // enumerate
  duk_size_t length = duk_get_length(ctx, -1);

  for (duk_uarridx_t i = 0; i < length; i += 1) {
    duk_get_prop_index(ctx, -1, i);

    duk_int_t value_type = duk_get_type(ctx, -1);
    switch (value_type) {
    case DUK_TYPE_NULL:
      array.append(Variant{});
      break;
    case DUK_TYPE_BOOLEAN:
      array.append(static_cast<bool>(duk_get_boolean(ctx, -1)));
      break;
    case DUK_TYPE_NUMBER:
      array.append(duk_get_number(ctx, -1));
      break;
    case DUK_TYPE_STRING:
      array.append(String(duk_get_string(ctx, -1)));
      break;
    case DUK_TYPE_OBJECT:
      if (duk_is_array(ctx, -1)) {
        array.append(array_to_array(ctx));
      } else {
        array.append(obj_to_dict(ctx));
      }
      break;
    default:
      break;
    }
    duk_pop(ctx);
  }

  return array;
};

// Assuming there is [... object]
Dictionary obj_to_dict(duk_context *ctx) {
  Dictionary dict;

  // enumerate
  duk_enum(ctx, -1, 0); // -> [... obj[name] enum]

  while (duk_next(ctx, -1, 1)) {
    const char *key_c = duk_to_string(ctx, -2);
    String key(key_c);

    duk_int_t value_type = duk_get_type(ctx, -1);
    switch (value_type) {
    case DUK_TYPE_NULL:
      dict[key] = Variant{};
      break;
    case DUK_TYPE_BOOLEAN:
      dict[key] = static_cast<bool>(duk_get_boolean(ctx, -1));
      break;
    case DUK_TYPE_NUMBER:
      dict[key] = duk_get_number(ctx, -1);
      break;
    case DUK_TYPE_STRING:
      dict[key] = String(duk_get_string(ctx, -1));
      break;
    case DUK_TYPE_OBJECT:
      if (duk_is_array(ctx, -1)) {
        dict[key] = array_to_array(ctx);
      } else {
        dict[key] = obj_to_dict(ctx);
      }
      break;
    default:
      break;
    }

    duk_pop_2(ctx); // pop value + key
  }

  duk_pop(ctx); // pop enum

  return dict;
};

duk_ret_t c_function(duk_context *ctx) {
  duk_get_global_string(ctx, "__this");
  JSEnvironment *self = (JSEnvironment *)duk_to_pointer(ctx, -1);
  duk_pop(ctx);

  duk_push_this(ctx);
  duk_get_prop_string(ctx, -1, "__name");
  const char *object_name = duk_safe_to_string(ctx, -1);
  duk_pop_2(ctx);

  duk_push_current_function(ctx);
  duk_get_prop_string(ctx, -1, "__name");
  const char *method_name = duk_safe_to_string(ctx, -1);
  duk_pop_2(ctx);

  String full_path = GD_FORMAT("{0}.{1}", object_name, method_name);

  Dictionary method_info = self->object_methods[full_path];
  String dispatch_name = method_info["dispatch_name"];

  Node *end_state = Object::cast_to<Node>((Object *)method_info["end_state"]);
  Node *cmd = Object::cast_to<Node>((Object *)method_info["cmd"]);
  RefCounted *context =
      Object::cast_to<RefCounted>((Object *)end_state->get("ctx"));
  context->call("set_var", "method_name", method_name);

  Dictionary arguments{};
  Array params = method_info["params"];
  int expected_argc = 0;
  for (Dictionary schema : params) {
    expected_argc += 1;
    if (!schema.has("default_value")) {
      break;
    }
  }

  auto type_to_string = [](duk_int_t type, bool is_array = false) -> String {
    switch (type) {
    case DUK_TYPE_NULL:
      return "null";
    case DUK_TYPE_BOOLEAN:
      return "boolean";
    case DUK_TYPE_NUMBER:
      return "number";
    case DUK_TYPE_STRING:
      return "string";
    case DUK_TYPE_OBJECT:
      if (is_array) {
        return "array";
      } else {
        return "object";
      }
    default:
      return "undefined";
    }
  };

  // TODO: user might add argument even if the method didnt accept any
  // arguments.
  int argc = duk_get_top(ctx);
  for (int i = 0; i < argc; i += 1) {
    Dictionary schema = params[i];
    String name = schema["name"];
    duk_int_t type = duk_get_type(ctx, i);
    switch (type) {
    case DUK_TYPE_UNDEFINED:
      if (schema.has("default_value")) {
        arguments[name] = schema["default_value"];
      } else {
        DUK_THROW("Too few arguments for '{0}' call. Expected at "
                  "least {1} but received {2}.",
                  full_path, expected_argc, i);
      }
      break;
    case DUK_TYPE_NULL:
      if (schema["type"] == "Nil") {
        arguments[name] = Variant{};
      } else {
        DUK_THROW(TYPE_ERROR_STRING, full_path, i + 1, "null",
                  type_to_string(type));
      }
      break;
    case DUK_TYPE_BOOLEAN:
      if (schema["type"] == "bool") {
        arguments[name] = duk_get_boolean(ctx, i);
      } else {
        DUK_THROW(TYPE_ERROR_STRING, full_path, i + 1, "bool",
                  type_to_string(type));
      }
      break;
    case DUK_TYPE_NUMBER:
      if (schema["type"] == "int" || schema["type"] == "float") {
        arguments[name] = duk_get_number(ctx, i);
      } else {
        DUK_THROW(TYPE_ERROR_STRING, full_path, i + 1, "number",
                  type_to_string(type));
      }
      break;
    case DUK_TYPE_STRING:
      if (schema["type"] == "String") {
        arguments[name] = duk_get_string(ctx, i);
      } else {
        DUK_THROW(TYPE_ERROR_STRING, full_path, i + 1, "string",
                  type_to_string(type));
      }
      break;
    case DUK_TYPE_OBJECT:
      if (schema["type"] == "Array" && duk_is_array(ctx, i)) {
        arguments[name] = array_to_array(ctx);
      } else if (schema["type"] == "Dictionary" && duk_is_object(ctx, i)) {
        arguments[name] = obj_to_dict(ctx);
      } else {
        if (schema["type"] == "Array") {
          DUK_THROW(TYPE_ERROR_STRING, full_path, i + 1, "Array",
                    type_to_string(type));
        } else if (schema["type"] == "Dictionary") {
          DUK_THROW(TYPE_ERROR_STRING, full_path, i + 1, "Map",
                    type_to_string(type));
        }
      }
      break;
    }
  }

  context->call_deferred("set_var", "args", arguments);
  // end_state->call_deferred(
  //     "connect", "exited",
  //     callable_mp(self, &JSEnvironment::_method_finished).bind(full_path),
  //     Object::ConnectFlags::CONNECT_ONE_SHOT);
  cmd->call_deferred(
      "connect", "idled",
      callable_mp(self, &JSEnvironment::_method_finished).bind(full_path),
      Object::ConnectFlags::CONNECT_ONE_SHOT);
  end_state->call_deferred("transition_to", dispatch_name);
  print_line("dispatch_name: ", dispatch_name);

  self->semaphore->wait();
  return 0;
}

void JSEnvironment::add_method(Dictionary method_info) {
  CharString object_name = ((String)method_info["object_name"]).ascii();
  CharString method_name = ((String)method_info["method_name"]).ascii();

  String full_path =
      GD_FORMAT("{0}.{1}", String(object_name), String(method_name));

  duk_push_global_object(ctx);

  duk_push_pointer(ctx, this);
  duk_put_prop_string(ctx, -2, "__this");

  if (object_methods.has(full_path)) {
    print_error(full_path, " already exist. overriding it.");
  }
  object_methods[full_path] = method_info;

  if (duk_has_prop_string(ctx, -1, object_name.ptr()) != 1) {
    duk_push_object(ctx);
    duk_push_string(ctx, object_name.ptr());
    duk_put_prop_string(ctx, -2, "__name");
    duk_put_prop_string(ctx, -2, object_name.ptr());
  }

  duk_get_prop_string(ctx, -1, object_name.ptr());
  {
    duk_int_t argc = ((Array)method_info["params"]).size();
    print_line(GD_FORMAT("{0}({1})", String(method_name), argc));
    duk_push_c_function(ctx, c_function, argc);
    duk_push_string(ctx, method_name.ptr());
    duk_put_prop_string(ctx, -2, "__name");
    duk_put_prop_string(ctx, -2, method_name.ptr());
  }
  duk_pop_2(ctx);
}

JSEnvironment::JSEnvironment() {
  ctx = duk_create_heap_default();
  semaphore.instantiate();
  thread.instantiate();
}

JSEnvironment::~JSEnvironment() {
  if (thread->is_started()) {
    thread->wait_to_finish();
    thread.unref();
  }
  semaphore.unref();
  duk_destroy_heap(ctx);
}

} // namespace godot

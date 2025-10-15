#include "js_environment.h"
#include "duk_config.h"
#include "duktape.h"
#include "godot_cpp/classes/object.hpp"
#include "godot_cpp/classes/ref.hpp"
#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/resource.hpp"
#include "godot_cpp/core/object.hpp"
#include "godot_cpp/core/print_string.hpp"
#include "godot_cpp/variant/callable_method_pointer.hpp"
#include "godot_cpp/variant/char_string.hpp"
#include "godot_cpp/variant/variant.hpp"

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
#define FOR_EACH(TYPE, NAME, ARRAY, BODY) \
  { \
    Array array = ARRAY; \
    TYPE NAME; \
    for (int __i = 0; __i < array.size(); __i++, NAME = array[__i]) BODY \
  }

void JSEnvironment::_bind_methods() {
  ClassDB::bind_method(D_METHOD("add_method", "method_info"),
                       &JSEnvironment::add_method);
  ClassDB::bind_method(D_METHOD("add_method_v2", "method_info"),
                       &JSEnvironment::add_method_v2);
  ClassDB::bind_method(D_METHOD("method", "resource"), &JSEnvironment::method);
  ClassDB::bind_method(D_METHOD("eval", "code"), &JSEnvironment::eval);
  ClassDB::bind_method(D_METHOD("eval_async", "code"),
                       &JSEnvironment::eval_async);
  ClassDB::bind_method(D_METHOD("pause"), &JSEnvironment::pause);
  ClassDB::bind_method(D_METHOD("resume"), &JSEnvironment::resume);

  ClassDB::bind_method(D_METHOD("is_running"), &JSEnvironment::is_running);
  ClassDB::bind_method(D_METHOD("is_paused"), &JSEnvironment::is_paused);

  ADD_SIGNAL(MethodInfo("started"));
  ADD_SIGNAL(MethodInfo("finished"));
  ADD_SIGNAL(MethodInfo("function_invoked"));
}

bool JSEnvironment::is_paused() const { return _paused; }

bool JSEnvironment::is_running() const { return _running; }

void JSEnvironment::pause() {
  if (_paused) {
    WARN_PRINT("Environment is already paused.");
  } else {
    _paused = true;
    while (_semaphore->try_wait())
      ;
    _semaphore->wait();
  }
}

void JSEnvironment::resume() {
  if (_paused) {
    _semaphore->post();
    _paused = false;
  } else {
    WARN_PRINT("Environment isn't paused.");
  }
}

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

  duk_push_string(_ctx, code_cs.ptr());
  duk_push_string(_ctx, "main");

  if (duk_pcompile(_ctx, 0) != DUK_EXEC_SUCCESS) {
    duk_print_error(_ctx);
  } else {
    if (duk_pcall(_ctx, 0) != DUK_EXEC_SUCCESS) {
      duk_print_error(_ctx);
    }
  }
  duk_pop(_ctx);
}

void JSEnvironment::eval_async(String code) {
  if (_running) {
    WARN_PRINT("Interpreter is already running!");
    return;
  } else if (!_first_run) {
    _thread->wait_to_finish();
  }

  _running = true;
  _first_run = false;
  _thread->start(
      callable_mp(this, &JSEnvironment::_eval_pending_code).bind(code));
}

void JSEnvironment::_eval_pending_code(String code) {
  call_deferred("emit_signal", "started");
  eval(code);
  _running = false;
  call_deferred("emit_signal", "finished");
}

void JSEnvironment::_method_finished() {
  if (_paused) {
    _semaphore->post();
    _paused = false;
  } else {
    WARN_PRINT("Environment isn't paused.");
  }
}

void JSEnvironment::method(Ref<Resource> resource) {}

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

  Ref<Resource> method_info = self->_object_methods[full_path];
  String dispatch_name = method_info->get("dispatch_name");

  // Node *end_state = Object::cast_to<Node>((Object
  // *)method_info["end_state"]); Node *cmd = Object::cast_to<Node>((Object
  // *)method_info["cmd"]); RefCounted *context =
  //     Object::cast_to<RefCounted>((Object *)end_state->get("ctx"));
  // context->call("set_var", "method_name", method_name);

  Dictionary arguments{};
  Array params = method_info->get("params_schema");
  int expected_argc = 0;
  FOR_EACH(Dictionary, schema, params, {
    expected_argc += 1;
    if (!schema.has("default_value")) {
      break;
    }
  })

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

  Callable cb = method_info->get("callable");
  if (cb.is_valid()) {
    cb.call_deferred(method_info, arguments);
  }
  // context->call_deferred("set_var", "args", arguments);
  // // end_state->call_deferred(
  // //     "connect", "exited",
  // //     callable_mp(self, &JSEnvironment::_method_finished).bind(full_path),
  // //     Object::ConnectFlags::CONNECT_ONE_SHOT);
  // cmd->call_deferred(
  //     "connect", "idled",
  //     callable_mp(self, &JSEnvironment::_method_finished).bind(full_path),
  //     Object::ConnectFlags::CONNECT_ONE_SHOT);
  // end_state->call_deferred("transition_to", dispatch_name);
  // print_line("dispatch_name: ", dispatch_name);

  while (self->_semaphore->try_wait())
    ;
  self->call_deferred("emit_signal", "function_invoked");
  self->_semaphore->wait();
  return 0;
}

duk_ret_t c_function_v2(duk_context *ctx) {
  duk_push_current_function(ctx);

  duk_get_prop_string(ctx, -1, "__this");
  JSEnvironment *self = static_cast<JSEnvironment *>(duk_to_pointer(ctx, -1));
  duk_pop(ctx);

  duk_get_prop_string(ctx, -1, "__path");
  const char *path = duk_safe_to_string(ctx, -1);
  duk_pop(ctx);

  duk_get_prop_string(ctx, -1, "__name");
  const char *method_name = duk_safe_to_string(ctx, -1);
  duk_pop(ctx);

  // pop current function
  duk_pop(ctx);

  Ref<Resource> method_info = self->_object_methods[String(path)];
  String dispatch_name = method_info->get("dispatch_name");

  Dictionary arguments{};
  Array params = method_info->get("params_schema");
  int expected_argc = 0;
  FOR_EACH(Dictionary, schema, params, {
    expected_argc += 1;
    if (!schema.has("default_value")) {
      break;
    }
  })

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
                  path, expected_argc, i);
      }
      break;
    case DUK_TYPE_NULL:
      if (schema["type"] == "Nil") {
        arguments[name] = Variant{};
      } else {
        DUK_THROW(TYPE_ERROR_STRING, path, i + 1, "null", type_to_string(type));
      }
      break;
    case DUK_TYPE_BOOLEAN:
      if (schema["type"] == "bool") {
        arguments[name] = duk_get_boolean(ctx, i);
      } else {
        DUK_THROW(TYPE_ERROR_STRING, path, i + 1, "bool", type_to_string(type));
      }
      break;
    case DUK_TYPE_NUMBER:
      if (schema["type"] == "int" || schema["type"] == "float") {
        arguments[name] = duk_get_number(ctx, i);
      } else {
        DUK_THROW(TYPE_ERROR_STRING, path, i + 1, "number",
                  type_to_string(type));
      }
      break;
    case DUK_TYPE_STRING:
      if (schema["type"] == "String") {
        arguments[name] = duk_get_string(ctx, i);
      } else {
        DUK_THROW(TYPE_ERROR_STRING, path, i + 1, "string",
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
          DUK_THROW(TYPE_ERROR_STRING, path, i + 1, "Array",
                    type_to_string(type));
        } else if (schema["type"] == "Dictionary") {
          DUK_THROW(TYPE_ERROR_STRING, path, i + 1, "Map",
                    type_to_string(type));
        }
      }
      break;
    }
  }
  print_line(GD_FORMAT("invoking {0} with {1} arguments, with {2}", path, argc,
                       arguments.size()));

  Callable cb = method_info->get("callable");

  Variant result = cb.call(method_info, arguments);
  if (result.get_type() == Variant::Type::BOOL) {
    if (result.booleanize()) {
      print_line_rich("[color=green]JSEnv[/color]: paused");
      self->pause();
    }
  }
  self->call("emit_signal", "function_invoked");
  print_line(GD_FORMAT("callable invoked: {0}, {1}", path, cb));

  return 0;
}

void JSEnvironment::add_method(Ref<Resource> method_info) {
  CharString object_name = ((String)method_info->get("object_name")).ascii();
  CharString method_name = ((String)method_info->get("method_name")).ascii();

  String full_path =
      GD_FORMAT("{0}.{1}", String(object_name), String(method_name));
  print_line("registering: ", full_path);

  if (_object_methods.has(full_path)) {
    print_error(full_path, " already exist. overriding it.");
  }
  _object_methods[full_path] = method_info;

  duk_push_global_object(_ctx);

  duk_push_pointer(_ctx, this);
  duk_put_prop_string(_ctx, -2, "__this");

  if (duk_has_prop_string(_ctx, -1, object_name.ptr()) != 1) {
    duk_push_object(_ctx);
    duk_push_string(_ctx, object_name.ptr());
    duk_put_prop_string(_ctx, -2, "__name");
    duk_put_prop_string(_ctx, -2, object_name.ptr());
  }

  duk_get_prop_string(_ctx, -1, object_name.ptr());
  {
    duk_int_t argc = ((Array)method_info->get("params_schema")).size();
    print_line(GD_FORMAT("{0}.{1}({2})", String(object_name),
                         String(method_name), argc));
    duk_push_c_function(_ctx, c_function, argc);
    duk_push_string(_ctx, method_name.ptr());
    duk_put_prop_string(_ctx, -2, "__name");
    duk_put_prop_string(_ctx, -2, method_name.ptr());
  }
  duk_pop_2(_ctx);
  duk_push_global_object(_ctx);
  print_line("registered: ", full_path, " = ",
             duk_has_prop_string(_ctx, -1, object_name.ptr()));
  duk_pop(_ctx);
}

void JSEnvironment::add_method_v2(Ref<Resource> method_info) {
  const String path = (String)method_info->get("path");

  print_line(GD_FORMAT("registering {0}()", path));

  if (_object_methods.has(path)) {
    print_error(path, " already exist. overriding it.");
  }
  _object_methods[path] = method_info;
  print_line(GD_FORMAT("  method_info: {0}", method_info));

  Array method_path = path.split(".", false);
  const String method_name = method_path.pop_back();

  duk_push_global_object(_ctx);

  // TODO: put full path of object to object itself.
  FOR_EACH(String, component, method_path, {
    if (duk_has_prop_string(_ctx, -1, component.ascii()) != 1) {
      duk_push_object(_ctx);

      // object.__name = component
      duk_push_string(_ctx, component.ascii());
      duk_put_prop_string(_ctx, -2, "__name");

      duk_put_prop_string(_ctx, -2, component.ascii());
    }
    duk_get_prop_string(_ctx, -1, component.ascii());
  });

  {
    const duk_int_t argc = ((Array)method_info->get("params_schema")).size();
    print_line(GD_FORMAT("  {0}({2})", path, argc));

    // &method_path.method_name
    duk_push_c_function(_ctx, c_function_v2, argc);

    // method_name.__this = this
    duk_push_pointer(_ctx, static_cast<void *>(this));
    duk_put_prop_string(_ctx, -2, "__this");

    // method_name.__path = path
    duk_push_string(_ctx, path.ascii());
    duk_put_prop_string(_ctx, -2, "__path");

    // method_name.__name = method_name
    duk_push_string(_ctx, method_name.ascii());
    duk_put_prop_string(_ctx, -2, "__name");

    // method_path.method_name = c_function_v2
    duk_put_prop_string(_ctx, -2, method_name.ascii());
  }

  duk_pop_n(_ctx, duk_get_top(_ctx));
  print_line(GD_FORMAT("  stack top {0}", path));
  print_line(GD_FORMAT("registered {0}()", path));
}

JSEnvironment::JSEnvironment() {
  _ctx = duk_create_heap_default();
  _semaphore.instantiate();
  _thread.instantiate();
}

JSEnvironment::~JSEnvironment() {
  if (_thread->is_started()) {
    _thread->wait_to_finish();
    _thread.unref();
  }
  _semaphore.unref();
  duk_destroy_heap(_ctx);
}

} // namespace godot

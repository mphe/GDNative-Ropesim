#include "NativeRopeServer.hpp"
#include "NativeRopeContext.hpp"
#include <godot_cpp/classes/window.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/classes/curve.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

NativeRopeServer* NativeRopeServer::_singleton = nullptr;


NativeRopeServer::NativeRopeServer() :
    _tree(nullptr),
    _last_time(0.0),
    _update_in_editor(false),
    _is_running(false)
{
    _singleton = this;
}

NativeRopeServer::~NativeRopeServer()
{
    _singleton = nullptr;
}

NativeRopeServer* NativeRopeServer::get_singleton()
{
    return _singleton;
}

void NativeRopeServer::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("register_rope", "rope"), &NativeRopeServer::register_rope);
    ClassDB::bind_method(D_METHOD("unregister_rope", "rope"), &NativeRopeServer::unregister_rope);
    ClassDB::bind_method(D_METHOD("get_num_ropes"), &NativeRopeServer::get_num_ropes);
    ClassDB::bind_method(D_METHOD("get_computation_time"), &NativeRopeServer::get_computation_time);
    ClassDB::bind_method(D_METHOD("set_update_in_editor", "value"), &NativeRopeServer::set_update_in_editor);
    ClassDB::bind_method(D_METHOD("get_update_in_editor"), &NativeRopeServer::get_update_in_editor);
    ClassDB::bind_method(D_METHOD("_on_physics_frame"), &NativeRopeServer::_on_physics_frame);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "update_in_editor"), "set_update_in_editor", "get_update_in_editor");
    ADD_SIGNAL(MethodInfo("on_post_update"));
    ADD_SIGNAL(MethodInfo("on_pre_update"));
    ADD_SIGNAL(MethodInfo("on_post_post_update"));
    ADD_SIGNAL(MethodInfo("on_pre_pre_update"));
}

void NativeRopeServer::register_rope(Node2D* rope)
{
    _ropes.push_back(rope);
    _start_stop_process();
    // UtilityFunctions::print("Rope registered: " + String::num_int64(_ropes.size()));
}

void NativeRopeServer::unregister_rope(Node2D* rope)
{
    const int64_t idx = _ropes.find(rope);

    if (idx < 0)
    {
        UtilityFunctions::push_warning("Unregistering non-registered Rope");
        return;
    }

    // Swap and pop
    const int64_t last_idx = _ropes.size() - 1;
    _ropes.set(idx, _ropes[last_idx]);
    _ropes.remove_at(last_idx);

    _start_stop_process();
    // UtilityFunctions::print("Rope unregistered: " + String::num_int64(_ropes.size()));
}

void NativeRopeServer::set_update_in_editor(bool value)
{
    _update_in_editor = value;
    _start_stop_process();
}

bool NativeRopeServer::get_update_in_editor() const
{
    return _update_in_editor;
}

void NativeRopeServer::_start_stop_process()
{
    // Since this node is not part of the tree itself, we need to grab the scene tree from outside.
    if (!_tree)
    {
        _tree = Object::cast_to<SceneTree>(Engine::get_singleton()->get_main_loop());

        if (!_tree)
        {
            UtilityFunctions::push_error("MainLoop is not a SceneTree");
            return;
        }
    }

    _last_time = 0.f;
    const bool should_run = !_ropes.is_empty() && (!Engine::get_singleton()->is_editor_hint() || _update_in_editor);

    if (should_run != _is_running)
    {
        if (should_run)
        {
            _tree->connect("physics_frame", Callable(this, "_on_physics_frame"));
            _is_running = true;
        }
        else
        {
            _tree->disconnect("physics_frame", Callable(this, "_on_physics_frame"));
            _is_running = false;
        }
    }
}

void NativeRopeServer::_on_physics_frame()
{
    emit_signal("on_pre_pre_update");
    emit_signal("on_pre_update");
    const double delta = _tree->get_root()->get_physics_process_delta_time();
    NativeRopeContext context;

    const uint64_t start = Time::get_singleton()->get_ticks_usec();

    for (Node2D* rope : _ropes)
    {
        context.load_context(rope);

        if (!context.validate()) [[unlikely]]
        {
            UtilityFunctions::push_warning("Inconsistent rope data detected -> Skipped");
            continue;
        }

        context.simulate(delta);
    }

    _last_time = (float)(Time::get_singleton()->get_ticks_usec() - start) / 1000.f;
    emit_signal("on_post_update");
    emit_signal("on_post_post_update");
}

float NativeRopeServer::get_computation_time() const
{
    return _last_time;
}

int64_t NativeRopeServer::get_num_ropes() const
{
    return _ropes.size();
}

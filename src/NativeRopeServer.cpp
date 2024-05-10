#include "NativeRopeServer.hpp"
#include "godot_cpp/classes/window.hpp"
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/classes/curve.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

const Vector2 VECTOR_ZERO = Vector2();
const Vector2 VECTOR_DOWN = Vector2(0, 1);


NativeRopeServer* NativeRopeServer::_singleton = nullptr;


float get_point_perc(int index, const PackedVector2Array& points)
{
    return index / (points.size() > 0 ? float(points.size() - 1) : 0.f);
}

Vector2 damp_vec(Vector2 value, float damping_factor, float delta)
{
    return value.lerp(VECTOR_ZERO, 1.0 - exp(-damping_factor * delta));
}


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
}

void NativeRopeServer::register_rope(Node2D* rope)
{
    _ropes.push_back(rope);
    _start_stop_process();
    // UtilityFunctions::print("Rope registered: " + String::num_int64(_ropes.size()));
}

void NativeRopeServer::unregister_rope(Node2D* rope)
{
    const int idx = _ropes.find(rope);

    if (idx < 0)
    {
        UtilityFunctions::push_warning("Unregistering non-registered Rope");
        return;
    }

    // Swap and pop
    const int last_idx = _ropes.size() - 1;
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
    bool should_run = !_ropes.is_empty() && (!Engine::get_singleton()->is_editor_hint() || _update_in_editor);

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
    emit_signal("on_pre_update");
    double delta = _tree->get_root()->get_physics_process_delta_time();
    auto start = Time::get_singleton()->get_ticks_usec();

    for (Node2D* rope : _ropes)
        _simulate(rope, delta);

    _last_time = (Time::get_singleton()->get_ticks_usec() - start) / 1000.f;
    emit_signal("on_post_update");
}

void NativeRopeServer::_simulate(Node2D* rope, float delta)
{
    PackedVector2Array points = rope->call("get_points");
    if (points.size() < 2)
        return;

    PackedVector2Array oldpoints = rope->call("get_old_points");
    Ref<Curve> damping_curve = rope->get("damping_curve");
    float gravity = rope->get("gravity");
    Vector2 gravity_direction = rope->get("gravity_direction");
    float damping = rope->get("damping");
    float stiffness = rope->get("stiffness");
    int num_constraint_iterations = rope->get("num_constraint_iterations");
    PackedFloat32Array seg_lengths = rope->call("get_segment_lengths");
    Vector2 parent_seg_dir = rope->get_global_transform().basis_xform(VECTOR_DOWN).normalized();
    Vector2 last_stiffness_force;

    // Simulate
    for (size_t i = 1; i < points.size(); ++i)
    {
        Vector2 vel = points[i] - oldpoints[i];
        float dampmult = damping_curve.is_valid() ? damping_curve->sample_baked(get_point_perc(i, points)) : 1.0;

        // NOTE: Asked a physicist to confirm this computation is physically accurate.
        // He mentioned that, while it is technically correct, there is a material-dependent limit
        // how far an object can bend before bending properties (stiffness) changes.
        // E.g. a material might be less inclined to snap back into place at smaller bend angles, or
        // a material might stop bending at some point, i.e. when it breaks.
        // This implementation should probably suffice in most cases, but a more advanced
        // implementation would include curves for stiffness in relation to segment position and
        // for stiffness in relation to bend angle.
        if (stiffness > 0)
        {
            //  |  parent_seg_dir     --->  parent_seg_dir.orthogonal()
            //  |                     \
            //  V                      \   seg_dir
            //  \  seg_dir              V
            //   \
            //    V
            Vector2 seg_dir = (points[i] - points[i - 1]).normalized();
            float angle = seg_dir.angle_to(parent_seg_dir);

            // The force directs orthogonal to the current segment
            Vector2 force_dir = seg_dir.orthogonal();

            // Scale the force the further the segment bends.
            // angle is signed and can be used to determine the force direction
            last_stiffness_force += force_dir * (-angle / 3.1415) * stiffness;
            vel += last_stiffness_force;
            parent_seg_dir = seg_dir;
        }

        oldpoints.set(i, points[i]);
        points.set(i, points[i] + damp_vec(vel, damping * dampmult, delta) + gravity_direction * gravity * delta);
    }

    // Constraint
    for (int _ = 0; _ < num_constraint_iterations; ++_)
    {
        points.set(0, rope->get_global_position());
        points.set(1, points[0] + (points[1] - points[0]).normalized() * seg_lengths[0]);

        for (size_t i = 1; i < points.size() - 1; ++i)
        {
            Vector2 diff = points[i + 1] - points[i];
            float distance = diff.length();
            Vector2 dir = diff / distance;
            float error = (seg_lengths[i] - distance) * 0.5;
            points.set(i, points[i] - error * dir);
            points.set(i + 1, points[i + 1] + error * dir);
        }
    }

    rope->call("set_points", points);
    rope->call("set_old_points", oldpoints);
}

float NativeRopeServer::get_computation_time() const
{
    return _last_time;
}

int NativeRopeServer::get_num_ropes() const
{
    return _ropes.size();
}

#include "NativeRopeServer.hpp"
#include <PoolArrays.hpp>
#include <Vector2.hpp>
#include <Curve.hpp>
#include <algorithm>
#include <OS.hpp>
#include <Engine.hpp>

using namespace godot;

float get_point_perc(int index, const PoolVector2Array& points)
{
    return index / (points.size() > 0 ? float(points.size() - 1) : 0.f);
}

Vector2 damp_vec(Vector2 value, float damping_factor, float delta)
{
    return value.linear_interpolate(value.ZERO, 1.0 - exp(-damping_factor * delta));
}


void NativeRopeServer::_register_methods()
{
    register_method("_physics_process", &NativeRopeServer::_physics_process);
    register_method("register_rope", &NativeRopeServer::register_rope);
    register_method("unregister_rope", &NativeRopeServer::unregister_rope);
    register_method("get_num_ropes", &NativeRopeServer::get_num_ropes);
    register_method("get_computation_time", &NativeRopeServer::get_computation_time);
    register_method("set_update_in_editor", &NativeRopeServer::set_update_in_editor);
    register_method("get_update_in_editor", &NativeRopeServer::get_update_in_editor);
    register_property<NativeRopeServer, bool>("update_in_editor", &NativeRopeServer::set_update_in_editor, &NativeRopeServer::get_update_in_editor, false);
}

NativeRopeServer::NativeRopeServer()
{
}

NativeRopeServer::~NativeRopeServer()
{
    // add your cleanup here
}

void NativeRopeServer::_init()
{
    _last_time = 0.0;
    _update_in_editor = false;
    _start_stop_process();
}

void NativeRopeServer::_physics_process(float delta)
{
    auto start = OS::get_singleton()->get_ticks_usec();
    for (Node2D* rope : _ropes)
        _simulate(rope, delta);
    _last_time = (OS::get_singleton()->get_ticks_usec() - start) / 1000.f;
}

void NativeRopeServer::register_rope(Node2D* rope)
{
    _ropes.emplace_back(rope);
    // Godot::print("Rope registered: " + String::num_int64(_ropes.size()));
    _start_stop_process();
}

void NativeRopeServer::unregister_rope(Node2D* rope)
{
    if (!_ropes.empty() && rope == _ropes.back())
    {
        _ropes.pop_back();
        _start_stop_process();
        // Godot::print("Rope unregistered: " + String::num_int64(_ropes.size()));
        return;
    }

    auto it = std::find(_ropes.begin(), _ropes.end(), rope);
    if (it == _ropes.end())
    {
        WARN_PRINT("Unregistering non-registered Rope");
        return;
    }

    // Swap and pop
    (*it) = _ropes.back();
    _ropes.pop_back();

    // Godot::print("Rope unregistered: " + String::num_int64(_ropes.size()));
    _start_stop_process();
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
    if (_ropes.empty())
    {
        _last_time = 0.f;
        set_physics_process(false);
    }
    else if (!Engine::get_singleton()->is_editor_hint() || get_update_in_editor())
        set_physics_process(true);

    // if (is_physics_processing())
    //     Godot::print("RopeServer deactivated");
    // else
    //     Godot::print("RopeServer activated");
}

void NativeRopeServer::_simulate(Node2D* rope, float delta)
{
    PoolVector2Array points = rope->call("get_points");
    if (points.size() < 2)
        return;

    PoolVector2Array oldpoints = rope->call("get_old_points");
    Ref<Curve> damping_curve = rope->get("damping_curve");
    float gravity = rope->get("gravity");
    float damping = rope->get("damping");
    float stiffness = rope->get("stiffness");
    int num_constraint_iterations = rope->get("num_constraint_iterations");
    PoolRealArray seg_lengths = rope->call("get_segment_lengths");
    Vector2 parent_seg_dir = rope->get_global_transform().xform(Vector2::DOWN).normalized();

    // Simulate
    for (size_t i = 1; i < points.size(); ++i)
    {
        Vector2 vel = points[i] - oldpoints[i];
        float dampmult = damping_curve.is_valid() ? damping_curve->interpolate_baked(get_point_perc(i, points)) : 1.0;

        if (stiffness > 0)
        {
            //  parent_seg_dir        parent_seg_tangent
            //  |                     -->
            //  |                     \   seg_dir
            //  V                      \
            //  \  seg_dir              V
            //   \
            //    V
            Vector2 seg_dir = (points[i] - oldpoints[i - 1]).normalized();
            Vector2 parent_seg_tangent = parent_seg_dir.tangent();
            float angle = std::abs(seg_dir.dot(parent_seg_dir));

            // The force directs orthogonal to the current segment
            // TODO: Ask a physicist if this is physically correct.
            Vector2 force_dir = seg_dir.tangent();

            // Check the direction to the parent segment and flip the vector so ensure it always
            // points into the right direction.
            if (parent_seg_tangent.dot(seg_dir) > 0)
                force_dir = -force_dir;

            // Scale the force the further the segment bends.
            vel += force_dir * (angle / 3.1415) * stiffness;
            parent_seg_dir = seg_dir;
        }

        oldpoints.set(i, points[i]);
        points.set(i, points[i] + damp_vec(vel, damping * dampmult, delta) + Vector2(0, gravity * delta));
    }

    // Constraint
    for (size_t _ = 0; _ < num_constraint_iterations; ++_)
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

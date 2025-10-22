#include "NativeRopeContext.hpp"
#include <godot_cpp/classes/physics_direct_space_state2d.hpp>
#include <godot_cpp/classes/physics_server2d.hpp>
#include <godot_cpp/classes/world2d.hpp>
#include <godot_cpp/classes/time.hpp>

using namespace godot;

const Vector2 VECTOR_ZERO = Vector2();   // NOLINT(cert-err58-cpp)
const Vector2 VECTOR_DOWN = Vector2(0, 1);   // NOLINT(cert-err58-cpp)


constexpr static float get_point_perc(int64_t index, int64_t num_points)
{
    return static_cast<float>(index) / static_cast<float>(num_points - 1);
}

static Vector2 exp_decay(Vector2 value, Vector2 target, float damping_factor, double delta)
{
    return value.lerp(target, static_cast<float>(1.0 - exp(-damping_factor * delta)));
}

static Vector2 damp_vec(Vector2 value, float damping_factor, double delta)
{
    return exp_decay(value, VECTOR_ZERO, damping_factor, delta);
}


NativeRopeContext::NativeRopeContext() :
    _shape_query(memnew(PhysicsShapeQueryParameters2D))
{
    PhysicsServer2D* physics_server = PhysicsServer2D::get_singleton();
    _cast_shape_rid = physics_server->circle_shape_create();
    _shape_query->set_shape_rid(_cast_shape_rid);
}

NativeRopeContext::~NativeRopeContext()
{
    PhysicsServer2D* physics_server = PhysicsServer2D::get_singleton();
    physics_server->free_rid(_cast_shape_rid);
}

bool NativeRopeContext::validate() const
{
    return oldpoints.size() == num_points
        && simulation_weights.size() == num_points
        && seg_lengths.size() == num_points - 1;
}

void NativeRopeContext::load_context(Node2D* rope)
{
    this->rope = rope;
    points = rope->call("get_points");
    num_points = points.size();
    oldpoints = rope->call("get_old_points");
    damping_curve = rope->get("damping_curve");
    gravity = rope->get("gravity");
    gravity_direction = rope->get("gravity_direction");
    wind = rope->get("wind");
    damping = rope->get("damping");
    stiffness_params = rope->get("stiffness_settings");
    max_endpoint_distance = rope->get("max_endpoint_distance");
    num_constraint_iterations = rope->get("num_constraint_iterations");
    seg_lengths = rope->call("get_segment_lengths");
    simulation_weights = rope->get("_simulation_weights");
    fixate_begin = rope->get("fixate_begin");
    resolve_to_begin = rope->get("resolve_to_begin");
    resolve_to_end = rope->get("resolve_to_end");
    enable_collisions = rope->get("enable_collisions");
    collision_radius = rope->get("collision_radius");
    collision_mask = rope->get("collision_mask");
    collision_damping = rope->get("collision_damping");
    report_contact_points = rope->get("report_contact_points");
    resolve_collisions_while_constraining = rope->get("resolve_collisions_while_constraining");

    if (data_buffer.size() < num_points)
        data_buffer.resize(num_points * 2);
}

void NativeRopeContext::simulate(double delta)
{
    if (num_points < 2)
        return;

    const float backup_multiplier_begin = simulation_weights[0];

    if (fixate_begin)
    {
        simulation_weights[0] = 0;
        points[0] = rope->get_global_position();
    }

    // Calculate new velocities and swap point buffers
    _simulate_velocities(delta);
    std::swap(oldpoints, points);

    // Compute new point positions
    for (int64_t i = 0; i < num_points; ++i)
        points[i] = oldpoints[i] + simulation_weights[i] * data_buffer[i];

    // Constraint step
    _simulate_stiffness(delta);
    _constraint(delta);

    if (!resolve_collisions_while_constraining)
        _resolve_collisions(delta, false);

    if (fixate_begin)
        simulation_weights[0] = backup_multiplier_begin;

    _writeback();
}

void NativeRopeContext::_writeback()
{
    // PackedArrays are pass-by-reference in Godot 4.x but not when being passed to a C++ function.
    // See https://github.com/godotengine/godot/pull/36492#issue-569558185.
    rope->call("set_points", points);
    rope->call("set_old_points", oldpoints);

    if (report_contact_points)
        rope->set("_contact_points", _contact_points);
}

void NativeRopeContext::_simulate_velocities(double delta)
{
    const bool use_damping_curve = damping_curve.is_valid() && damping_curve->get_point_count() > 0;
    const Vector2 frame_gravity = gravity_direction * static_cast<float>(gravity * delta);

    // Init velocities using delta + damping + gravity
    for (int64_t i = 0; i < num_points; ++i)
    {
        const Vector2 vel = points[i] - oldpoints[i];
        const float dampmult = use_damping_curve ? damping_curve->sample_baked(get_point_perc(i, num_points)) : 1.0f;
        data_buffer[i] = damp_vec(vel, damping * dampmult, delta) + frame_gravity;
    }

    // Apply other forces
    _simulate_wind();
}

void NativeRopeContext::_simulate_wind()
{
    if (wind.is_null() || !wind->get_enable_wind() || wind->get_noise().is_null())
        return;

    const float time = static_cast<float>(Time::get_singleton()->get_ticks_msec());
    const Vector2 wind_velocity = wind->get_direction_vector() * wind->get_wind_strength();
    const Vector2 orth_strength = wind->get_direction_vector().orthogonal() *  wind->get_oscillation_strength();

    for (int i = 0; i < num_points; ++i)
    {
        const float noise = wind->get_noise()->get_noise_3d(points[i].x, points[i].y, time);
        const Vector2 noise_velocity = orth_strength * noise;
        data_buffer[i] += wind_velocity + noise_velocity;
    }
}

void NativeRopeContext::_simulate_stiffness(double delta)
{
    if (stiffness_params.is_null() || stiffness_params->get_stiffness() <= 0)
        return;

    const auto initial_seg_dir = rope->get_global_transform().basis_xform(VECTOR_DOWN).normalized();
    _simulate_stiffness_forward(delta, initial_seg_dir);
}

void NativeRopeContext::_simulate_stiffness_forward(double delta, Vector2 last_stiffness_dir)
{
    const float stiffness = stiffness_params->get_stiffness();
    const auto stiffness_curve = stiffness_params->get_stiffness_curve();
    const auto stiffness_bend_curve = stiffness_params->get_stiffness_bend_curve();
    const bool use_stiffness_curve = stiffness_curve.is_valid() && stiffness_curve->get_point_count() > 0;
    const bool use_bend_curve = stiffness_bend_curve.is_valid() && stiffness_bend_curve->get_point_count() > 0;

    //             |
    //             | last_stiffness_dir
    //             V
    //             o  last_point
    //             . \
    //             .  \  seg_dir
    //             .   V
    // target_pos  o....o  current_point
    //               diff

    Vector2 last_point = points[0];
    Vector2 force_vec;

    for (int64_t i = 1; i < num_points; ++i)
    {
        const Vector2 current_point = points[i];
        const Vector2 seg_dir = (current_point - last_point).normalized();
        const Vector2 target_pos = last_point + last_stiffness_dir * seg_lengths[i - 1];
        const Vector2 diff = target_pos - current_point;

        float force = stiffness;

        if (use_stiffness_curve)
        {
            force *= stiffness_curve->sample_baked(get_point_perc(i, num_points));
        }

        if (use_bend_curve)
        {
            // angle is signed and can be used to determine the force direction
            const float angle = seg_dir.angle_to(last_stiffness_dir);
            const float bend_factor = Math::absf(angle / static_cast<float>(Math_PI));
            force *= stiffness_bend_curve->sample_baked(bend_factor);
        }

        force_vec += exp_decay(VECTOR_ZERO, diff, force, delta);

        // Weights must be applied now to not accumulate an incorrect force
        force_vec *= simulation_weights[i];

        // The point can be directly overwritten because the old value is no longer relevant in
        // successive iterations.
        points[i] += force_vec;

        last_stiffness_dir = seg_dir;
        last_point = current_point;
    }
}

static void constraint_segment(Vector2* point_a, Vector2* point_b, float weight_a, float weight_b, float seg_length)
{
    const Vector2 diff = *point_b - *point_a;
    const float distance = diff.length();
    const float error = (seg_length - distance) * 0.5f;
    const Vector2 dir = error * (diff / Math::max(distance, 0.001f));

    // If one point has a weight < 1.0, the other point must compensate the difference in
    // relation to its own weight.
    // This is especially relevant with fixate_begin = true or with arbitrary weights = 0.0.
    // In that case non-fixed point should be constrained by the whole error distance, not
    // just half of it, because the other one can obviously not move.
    // It actually works quite fine without this compensation, but this is more correct and
    // produces better results.
    *point_a -= (weight_a + weight_a * (1.0 - weight_b)) * dir;
    *point_b += (weight_b + weight_b * (1.0 - weight_a)) * dir;
}

void NativeRopeContext::_constraint(double delta)
{
    const bool use_euclid_constraint = max_endpoint_distance > 0;

    if (use_euclid_constraint)
    {
        Vector2* const first_point = &points[0];
        Vector2* const last_point = &points[num_points - 1];
        const float max_stretch_length_sqr = max_endpoint_distance * max_endpoint_distance;
        const float rope_length_sqr = first_point->distance_squared_to(*last_point);

        if (rope_length_sqr > max_stretch_length_sqr)
        {
            float weight_a;
            float weight_b;

            // Always has priority
            if (fixate_begin)
            {
                weight_a = 0.0;
                weight_b = 1.0;
            }
            else if (resolve_to_begin == resolve_to_end)
            {
                weight_a = 1.0;
                weight_b = 1.0;
            }
            else
            {
                weight_a = resolve_to_begin ? 0.0 : 1.0;
                weight_b = resolve_to_end ? 0.0 : 1.0;
            }

            constraint_segment(first_point, last_point, weight_a, weight_b, max_endpoint_distance);
        }
    }

    for (int i = 0; i < num_constraint_iterations; ++i)
    {
        for (int i = 0; i < num_points - 1; ++i)
            constraint_segment(&points[i], &points[i + 1], simulation_weights[i], simulation_weights[i + 1], seg_lengths[i]);

        if (resolve_collisions_while_constraining)
            _resolve_collisions(delta, i != num_constraint_iterations - 1);
    }
}

void NativeRopeContext::_resolve_collisions(double delta, bool disable_contact_reporting)
{
    if (!enable_collisions)
        return;

    const bool report_contacts = report_contact_points && !disable_contact_reporting;
    PhysicsDirectSpaceState2D* space = rope->get_world_2d()->get_direct_space_state();
    PhysicsServer2D* physics_server = PhysicsServer2D::get_singleton();
    Transform2D transform;

    if (report_contacts)
        _contact_points.clear();

    physics_server->shape_set_data(_cast_shape_rid, collision_radius);
    _shape_query->set_collision_mask(collision_mask);

    for (int i = 0; i < num_points; ++i)
    {
        transform.set_origin(points[i]);
        _shape_query->set_transform(transform);
        const Dictionary rest_info = space->get_rest_info(_shape_query);

        if (rest_info.is_empty())
            continue;

        const Vector2 intersect_point = rest_info["point"];
        const Vector2 intersect_normal = rest_info["normal"];
        const Vector2 safe_point = intersect_point + intersect_normal * (collision_radius + CMP_EPSILON);
        const Vector2 safe_motion = (safe_point - points[i]) * simulation_weights[i];
        const Vector2 new_point = points[i] + safe_motion;

        points[i] = oldpoints[i] + damp_vec(new_point - oldpoints[i], collision_damping, delta);

        if (report_contacts)
            _contact_points.push_back(intersect_point);
    }
}


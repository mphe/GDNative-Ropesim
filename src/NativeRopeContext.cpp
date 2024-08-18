#include "NativeRopeContext.hpp"

using namespace godot;

const Vector2 VECTOR_ZERO = Vector2();
const Vector2 VECTOR_DOWN = Vector2(0, 1);


static float get_point_perc(int index, const PackedVector2Array& points)
{
    return (float)index / (points.size() > 0 ? float(points.size() - 1) : 0.f);
}

static Vector2 damp_vec(Vector2 value, float damping_factor, double delta)
{
    return value.lerp(VECTOR_ZERO, (float)(1.0 - exp(-damping_factor * delta)));
}


void NativeRopeContext::_bind_methods()
{
}

bool NativeRopeContext::validate() const
{
    const int64_t size = points.size();
    return oldpoints.size() == size
        && simulation_weights.size() == size
        && seg_lengths.size() == size - 1;
}

void NativeRopeContext::load_context(Node2D* rope)
{
    this->rope = rope;
    points = rope->call("get_points");
    oldpoints = rope->call("get_old_points");
    damping_curve = rope->get("damping_curve");
    gravity = rope->get("gravity");
    gravity_direction = rope->get("gravity_direction");
    damping = rope->get("damping");
    stiffness = rope->get("stiffness");
    max_endpoint_distance = rope->get("max_endpoint_distance");
    num_constraint_iterations = rope->get("num_constraint_iterations");
    seg_lengths = rope->call("get_segment_lengths");
    simulation_weights = rope->get("_simulation_weights");
    fixate_begin = rope->get("fixate_begin");
    resolve_to_begin = rope->get("resolve_to_begin");
    resolve_to_end = rope->get("resolve_to_end");
}

void NativeRopeContext::simulate(double delta)
{
    if (points.size() < 2)
        return;

    const float backup_multiplier_begin = simulation_weights[0];

    if (fixate_begin)
    {
        simulation_weights[0] = 0;
        points[0] = rope->get_global_position();
    }

    _simulate_velocities(delta);
    _constraint();

    if (fixate_begin)
        simulation_weights[0] = backup_multiplier_begin;

    // PackedArrays are pass-by-reference in Godot 4.x but not when being passed to a C++ function.
    // See https://github.com/godotengine/godot/pull/36492#issue-569558185.
    rope->call("set_points", points);
    rope->call("set_old_points", oldpoints);
}

void NativeRopeContext::_simulate_velocities(double delta)
{
    const int first_idx = fixate_begin ? 1 : 0;
    const int size = (int)points.size();

    // NOTE: The following is a little ugly but it reduces memory usage by reusing existing buffers.
    // It is also faster than allocating a new temporary buffer and also likely more cache efficient.

    // oldpoints is no longer needed after initial velocity computation, so we reuse it to store velocities.
    PackedVector2Array& velocities = oldpoints;
    // Afterwards we use oldpoints to store the new points and finally swap points and oldpoints
    PackedVector2Array& new_points = oldpoints;

    // Compute velocities
    for (int i = first_idx; i < size; ++i)
        velocities[i] = points[i] - oldpoints[i];

    // Stiffness
    _simulate_stiffness(&velocities);

    // Apply velocity and damping
    const float frame_gravity = (float)(gravity * delta);
    const bool use_damping_curve = damping_curve.is_valid() && damping_curve->get_point_count() > 0;

    for (int i = first_idx; i < size; ++i)
    {
        const float dampmult = use_damping_curve ? (float)damping_curve->sample_baked(get_point_perc(i, points)) : 1.0f;
        const Vector2 final_vel = simulation_weights[i] * (
                damp_vec(velocities[i], damping * dampmult, delta)
                + gravity_direction * frame_gravity
                );

        new_points[i] = points[i] + final_vel;
    }

    std::swap(oldpoints, points);
}

void NativeRopeContext::_simulate_stiffness(PackedVector2Array* velocities) const
{
    // NOTE: oldpoints should not be used here, see comments in simulate_velocities().

    if (stiffness <= 0)
        return;

    Vector2 parent_seg_dir = rope->get_global_transform().basis_xform(VECTOR_DOWN).normalized();
    Vector2 last_stiffness_force;

    for (int i = 1; i < points.size(); ++i)
    {
        // NOTE: Asked a physicist to confirm this computation is physically accurate.
        // He mentioned that, while it is technically correct, there is a material-dependent limit
        // how far an object can bend before bending properties (stiffness) changes.
        // E.g. a material might be less inclined to snap back into place at smaller bend angles, or
        // a material might stop bending at some point, i.e. when it breaks.
        // This implementation should probably suffice in most cases, but a more advanced
        // implementation would include curves for stiffness in relation to segment position and
        // for stiffness in relation to bend angle.
        //
        //  |  parent_seg_dir     --->  parent_seg_dir.orthogonal()
        //  |                     \
        //  V                      \   seg_dir
        //  \  seg_dir              V
        //   \
        //    V
        const Vector2 seg_dir = (points[i] - points[i - 1]).normalized();
        const float angle = seg_dir.angle_to(parent_seg_dir);

        // The force directs orthogonal to the current segment
        const Vector2 force_dir = seg_dir.orthogonal();

        // Scale the force the further the segment bends.
        // angle is signed and can be used to determine the force direction
        last_stiffness_force += force_dir * (-angle / 3.1415f) * stiffness;
        parent_seg_dir = seg_dir;

        // Update velocity
        (*velocities)[i] += last_stiffness_force;
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

void NativeRopeContext::_constraint()
{
    const bool use_euclid_constraint = max_endpoint_distance > 0;

    if (use_euclid_constraint)
    {
        Vector2* const first_point = &points[0];
        Vector2* const last_point = &points[(int)points.size() - 1];
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


    for (int _ = 0; _ < num_constraint_iterations; ++_)
    {
        for (int i = 0; i < points.size() - 1; ++i)
            constraint_segment(&points[i], &points[i + 1], simulation_weights[i], simulation_weights[i + 1], seg_lengths[i]);
    }
}

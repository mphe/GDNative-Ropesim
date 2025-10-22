#pragma once

#include "RopeStiffnessParameters.hpp"
#include "RopeWindParameters.hpp"
#include <godot_cpp/classes/curve.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/physics_shape_query_parameters2d.hpp>

namespace godot {

// Caches properties of a rope node and performs simulation.
// TODO: Could be used as base class in the future to manage rope data in C++ and not in GDScript.
class NativeRopeContext  // NOLINT(cppcoreguidelines-special-member-functions)
{
public:
    NativeRopeContext();
    ~NativeRopeContext();

    void load_context(Node2D* rope);
    void simulate(double delta);
    bool validate() const;

protected:
    /// Reads point data from `points` and `oldpoints` and writes velocities to `data_buffer`.
    void _simulate_velocities(double delta);

    /// Reads point data from `points` and adds velocities to `data_buffer`.
    void _simulate_wind();

    /// Simulates stiffness. Reads and writes from/to `points`.
    void _simulate_stiffness(double delta);
    void _simulate_stiffness_forward(double delta, Vector2 last_stiffness_dir);

    /// Resolves collisions. Reads and writes to `points`.
    void _resolve_collisions(double delta, bool disable_contact_reporting);

    /// Constrains points iteratively. Reads and writes to `points`.
    void _constraint(double delta);

    /// Write point data back to the rope node.
    void _writeback();

private:
    // TODO: These are "buffer" variables that are (re)used globally across all ropes. Consider moving them to a parent scope.
    Ref<PhysicsShapeQueryParameters2D> _shape_query;
    RID _cast_shape_rid;
    PackedVector2Array _contact_points;

public:
    /// Internal buffer for intermediate results during point and velocity calculations.
    /// Will be resized on demand to be at least as large as the current `points` vector.
    /// It will not be cleared.
    PackedVector2Array data_buffer;

    Node2D* rope = nullptr;

    PackedVector2Array points;
    PackedVector2Array oldpoints;
    PackedFloat32Array seg_lengths;
    PackedFloat32Array simulation_weights;

    /// Number of rope points. Same as `points.size()` but cached.
    int64_t num_points = 0;

    float gravity = 0.0;
    Vector2 gravity_direction;
    Ref<RopeWindParameters> wind;
    float damping = 0.0;
    Ref<Curve> damping_curve;
    Ref<RopeStiffnessParameters> stiffness_params;
    float max_endpoint_distance = 0.0;
    int num_constraint_iterations = 0;

    float collision_radius = 1.0;
    float collision_damping = 0.0;
    int collision_mask = 0;

    bool fixate_begin = true;
    bool resolve_to_begin = false;
    bool resolve_to_end = false;
    bool enable_collisions = false;
    bool resolve_collisions_while_constraining = false;
    bool report_contact_points = false;
};

}

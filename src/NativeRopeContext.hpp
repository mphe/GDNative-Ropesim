#ifndef NATIVE_ROPE_CONTEXT_HPP
#define NATIVE_ROPE_CONTEXT_HPP

#include "godot_cpp/classes/curve.hpp"
#include "godot_cpp/classes/node2d.hpp"

namespace godot
{
    // Caches properties of a rope node and implements simulation functionality.
    // TODO: Could be used in the future for a data driven approach where rope data is managed by NativeRopeServer and not in GDScript.
    class NativeRopeContext : public Object
    {
        GDCLASS(NativeRopeContext, Object)  // NOLINT

        public:
            void load_context(Node2D* rope);
            void simulate(double delta);
            bool validate() const;

        protected:
            static void _bind_methods();
            void _simulate_velocities(double delta);
            void _simulate_stiffness(PackedVector2Array* velocities) const;
            void _constraint();

        public:
            Node2D* rope;
            PackedVector2Array points;
            PackedVector2Array oldpoints;
            PackedFloat32Array seg_lengths;
            PackedFloat32Array simulation_weights;
            float gravity;
            Vector2 gravity_direction;
            float damping;
            float stiffness;
            int num_constraint_iterations;
            Ref<Curve> damping_curve;
            bool fixate_begin;
    };
}

#endif

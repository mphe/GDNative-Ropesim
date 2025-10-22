#pragma once

#include <godot_cpp/classes/curve.hpp>
#include <godot_cpp/classes/resource.hpp>

namespace godot {

class RopeStiffnessParameters : public Resource  // NOLINT(cppcoreguidelines-special-member-functions)
{
    GDCLASS(RopeStiffnessParameters, Resource)  // NOLINT

public:
    float get_stiffness() const;
    void set_stiffness(float value);

    Ref<Curve> get_stiffness_curve() const;
    void set_stiffness_curve(Ref<Curve> curve);

    Ref<Curve> get_stiffness_bend_curve() const;
    void set_stiffness_bend_curve(Ref<Curve> curve);

protected:
    static void _bind_methods();

private:
    float stiffness = 0.0;
    Ref<Curve> stiffness_curve;
    Ref<Curve> stiffness_bend_curve;
    // TODO: Stiffness direction for back and front
    // TODO: Stiffness initial direction for back and front
};

}

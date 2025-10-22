#include "RopeStiffnessParameters.hpp"
#include "godot_cpp/core/class_db.hpp"

using namespace godot;

float RopeStiffnessParameters::get_stiffness() const
{
    return stiffness;
}

void RopeStiffnessParameters::set_stiffness(float value)
{
    stiffness = value;
    emit_changed();
}

Ref<Curve> RopeStiffnessParameters::get_stiffness_curve() const
{
    return stiffness_curve;
}

void RopeStiffnessParameters::set_stiffness_curve(Ref<Curve> curve)
{
    stiffness_curve = curve;
    emit_changed();
}

Ref<Curve> RopeStiffnessParameters::get_stiffness_bend_curve() const
{
    return stiffness_bend_curve;
}

void RopeStiffnessParameters::set_stiffness_bend_curve(Ref<Curve> curve)
{
    stiffness_bend_curve = curve;
    emit_changed();
}


void RopeStiffnessParameters::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("get_stiffness"), &RopeStiffnessParameters::get_stiffness);
    ClassDB::bind_method(D_METHOD("set_stiffness", "value"), &RopeStiffnessParameters::set_stiffness);
    ClassDB::bind_method(D_METHOD("get_stiffness_curve"), &RopeStiffnessParameters::get_stiffness_curve);
    ClassDB::bind_method(D_METHOD("set_stiffness_curve", "curve"), &RopeStiffnessParameters::set_stiffness_curve);
    ClassDB::bind_method(D_METHOD("get_stiffness_bend_curve"), &RopeStiffnessParameters::get_stiffness_bend_curve);
    ClassDB::bind_method(D_METHOD("set_stiffness_bend_curve", "curve"), &RopeStiffnessParameters::set_stiffness_bend_curve);

    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "stiffness"), "set_stiffness", "get_stiffness");
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "stiffness_curve", PROPERTY_HINT_RESOURCE_TYPE, "Curve"), "set_stiffness_curve", "get_stiffness_curve");
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "stiffness_bend_curve", PROPERTY_HINT_RESOURCE_TYPE, "Curve"), "set_stiffness_bend_curve", "get_stiffness_bend_curve");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "stiffness_damping"), "set_stiffness_damping", "get_stiffness_damping");
}

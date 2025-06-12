#include "RopeWindParameters.hpp"

using namespace godot;

void RopeWindParameters::set_direction(float angle)
{
    if (_angle == angle)
        return;

    _angle = angle;
    _wind_direction = Vector2::from_angle(angle);
    emit_changed();
}

float RopeWindParameters::get_direction() const
{
    return _angle;
}

Vector2 RopeWindParameters::get_direction_vector() const
{
    return _wind_direction;
}

void RopeWindParameters::set_wind_strength(float strength)
{
    if (_wind_strength == strength)
        return;

    _wind_strength = strength;
    emit_changed();
}

float RopeWindParameters::get_wind_strength() const
{
    return _wind_strength;
}

void RopeWindParameters::set_oscillation_strength(float oscillation_strength)
{
    if (_oscillation_strength == oscillation_strength)
        return;

    _oscillation_strength = oscillation_strength;
    emit_changed();
}

float RopeWindParameters::get_oscillation_strength() const
{
    return _oscillation_strength;
}

void RopeWindParameters::set_noise(Ref<FastNoiseLite> noise)
{
    if (_noise == noise)
        return;

    _noise = noise;
    emit_changed();
}

Ref<FastNoiseLite> RopeWindParameters::get_noise() const
{
    return _noise;
}

void RopeWindParameters::set_enable_wind(bool wind_enabled)
{
    if (_enable_wind == wind_enabled)
        return;

    _enable_wind = wind_enabled;
    emit_changed();
}

bool RopeWindParameters::get_enable_wind() const
{
    return _enable_wind;
}

void RopeWindParameters::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_direction", "direction"), &RopeWindParameters::set_direction);
    ClassDB::bind_method(D_METHOD("get_direction"), &RopeWindParameters::get_direction);
    ClassDB::bind_method(D_METHOD("set_wind_strength", "strength"), &RopeWindParameters::set_wind_strength);
    ClassDB::bind_method(D_METHOD("get_wind_strength"), &RopeWindParameters::get_wind_strength);
    ClassDB::bind_method(D_METHOD("set_oscillation_strength", "strength"), &RopeWindParameters::set_oscillation_strength);
    ClassDB::bind_method(D_METHOD("get_oscillation_strength"), &RopeWindParameters::get_oscillation_strength);
    ClassDB::bind_method(D_METHOD("set_noise", "noise"), &RopeWindParameters::set_noise);
    ClassDB::bind_method(D_METHOD("get_noise"), &RopeWindParameters::get_noise);
    ClassDB::bind_method(D_METHOD("set_enable_wind", "enabled"), &RopeWindParameters::set_enable_wind);
    ClassDB::bind_method(D_METHOD("get_enable_wind"), &RopeWindParameters::get_enable_wind);

    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "direction", PROPERTY_HINT_RANGE, "0,360,0.1,radians_as_degrees"), "set_direction", "get_direction");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "wind_strength"), "set_wind_strength", "get_wind_strength");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "oscillation_strength"), "set_oscillation_strength", "get_oscillation_strength");
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "noise", PROPERTY_HINT_RESOURCE_TYPE, "FastNoiseLite"), "set_noise", "get_noise");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "enable_wind"), "set_enable_wind", "get_enable_wind");
}

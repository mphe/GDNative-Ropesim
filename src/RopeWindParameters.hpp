#ifndef NATIVE_ROPE_WIND_PARAMETERS_HPP
#define NATIVE_ROPE_WIND_PARAMETERS_HPP

#include <godot_cpp/classes/fast_noise_lite.hpp>
#include <godot_cpp/classes/resource.hpp>

namespace godot
{
    class RopeWindParameters : public Resource  // NOLINT(cppcoreguidelines-special-member-functions)
    {
        GDCLASS(RopeWindParameters, Resource) // NOLINT

        public:
            void set_direction(float angle);
            float get_direction() const;
            Vector2 get_direction_vector() const;
            void set_wind_strength(float strength);
            float get_wind_strength() const;
            void set_oscillation_strength(float strength);
            float get_oscillation_strength() const;
            void set_noise(Ref<FastNoiseLite> noise);
            Ref<FastNoiseLite> get_noise() const;
            void set_enable_wind(bool wind_enabled);
            bool get_enable_wind() const;

        protected:
            static void _bind_methods();

        private:
            Vector2 _wind_direction = {1.0f, 0.0f};
            float _angle = 0.0f;
            float _wind_strength = 0.0f;
            float _oscillation_strength = 0.0f;
            Ref<FastNoiseLite> _noise = nullptr;
            bool _enable_wind = true;
    };
}

#endif

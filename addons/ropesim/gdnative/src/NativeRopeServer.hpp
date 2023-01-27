#ifndef NATIVE_ROPE_SERVER_HPP
#define NATIVE_ROPE_SERVER_HPP

#include <Godot.hpp>
#include <Node.hpp>
#include <Sprite.hpp>
#include <vector>

namespace godot
{
    class NativeRopeServer : public Node
    {
        GODOT_CLASS(NativeRopeServer, Node)

        public:
            NativeRopeServer();
            ~NativeRopeServer();

            static void _register_methods();

            void _init();

            void _physics_process(float delta);

            void register_rope(Node2D* rope);
            void unregister_rope(Node2D* rope);

            void set_update_in_editor(bool value);
            bool get_update_in_editor() const;

            int get_num_ropes() const;
            float get_computation_time() const;

        private:
            void _start_stop_process();
            void _simulate(Node2D* rope, float delta);

        private:
            std::vector<Node2D*> _ropes;
            float _last_time;
            bool _update_in_editor;
    };

}

#endif

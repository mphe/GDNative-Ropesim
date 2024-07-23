#ifndef NATIVE_ROPE_SERVER_HPP
#define NATIVE_ROPE_SERVER_HPP

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/templates/vector.hpp>
#include <godot_cpp/classes/curve.hpp>

namespace godot
{
    class NativeRopeServer : public Object
    {
        GDCLASS(NativeRopeServer, Object)  // NOLINT

        public:
            NativeRopeServer();
            ~NativeRopeServer() override;

            static NativeRopeServer* get_singleton();

            void register_rope(Node2D* rope);
            void unregister_rope(Node2D* rope);

            void set_update_in_editor(bool value);
            bool get_update_in_editor() const;

            int get_num_ropes() const;
            float get_computation_time() const;

        protected:
            static void _bind_methods();

        private:
            void _start_stop_process();
            void _on_physics_frame();

        private:
            static NativeRopeServer* _singleton;
            SceneTree* _tree;
            Vector<Node2D*> _ropes;
            float _last_time;
            bool _update_in_editor;
            bool _is_running;
    };

}

#endif

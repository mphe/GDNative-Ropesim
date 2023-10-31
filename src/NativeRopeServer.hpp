#ifndef NATIVE_ROPE_SERVER_HPP
#define NATIVE_ROPE_SERVER_HPP

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/sprite2d.hpp>
#include <vector>

namespace godot
{
    class NativeRopeServer : public Node
    {
        GDCLASS(NativeRopeServer, Node)

        public:
            NativeRopeServer();

            void _enter_tree() override;
            void _physics_process(double delta) override;

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
            void _simulate(Node2D* rope, float delta);

        private:
            std::vector<Node2D*> _ropes;
            float _last_time;
            bool _update_in_editor;
    };

}

#endif

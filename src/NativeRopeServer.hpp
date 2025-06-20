#pragma once

#include <godot_cpp/classes/curve.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/templates/vector.hpp>

namespace godot {

class NativeRopeServer : public Object // NOLINT(cppcoreguidelines-special-member-functions)
{
    GDCLASS(NativeRopeServer, Object) // NOLINT

public:
    NativeRopeServer();
    ~NativeRopeServer() override;

    static NativeRopeServer* get_singleton();

    void register_rope(Node2D* rope);
    void unregister_rope(Node2D* rope);

    void set_update_in_editor(bool value);
    bool get_update_in_editor() const;

    int64_t get_num_ropes() const;
    float get_computation_time() const;

protected:
    static void _bind_methods();

private:
    void _start_stop_process();
    void _on_physics_frame();

private:
    static NativeRopeServer* _singleton;
    SceneTree* _tree = nullptr;
    Vector<Node2D*> _ropes;
    float _last_time = 0.0;
    bool _update_in_editor = false;
    bool _is_running = false;
};

}

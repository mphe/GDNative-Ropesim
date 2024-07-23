#include "gdlibrary.hpp"
#include "NativeRopeContext.hpp"
#include "NativeRopeServer.hpp"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/engine.hpp>

using namespace godot;

static NativeRopeServer* rope_server = nullptr;


void initialize_libropesim(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    ClassDB::register_class<NativeRopeServer>();
    ClassDB::register_class<NativeRopeContext>();
    rope_server = memnew(NativeRopeServer);  // NOLINT
    Engine::get_singleton()->register_singleton("NativeRopeServer", rope_server);
}

void uninitialize_libropesim(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    Engine::get_singleton()->unregister_singleton("NativeRopeServer");
    memdelete(rope_server);
    rope_server = nullptr;
}

extern "C" {
    // Initialization.
    GDExtensionBool GDE_EXPORT libropesim_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
        const godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

        init_obj.register_initializer(initialize_libropesim);
        init_obj.register_terminator(uninitialize_libropesim);
        init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

        return init_obj.init();
    }
}

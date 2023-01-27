extends Node

# 25 + Array     -> 10-20 fps
# 25 + PoolArray -> 40-60 fps
# 25 + Server    -> 50-70 fps
# 25 + Server + Threading -> ?

var _ropes := []  # List[Rope]
var _threads = []
var _is_multithreading: bool = false

const min_threads: int = 1
const max_threads: int = 4
const min_ropes_per_thread: int = 50
var _num_threads: int = min_threads


func _ready() -> void:
    for _i in max_threads:
        _threads.append(Thread.new())


# Does not check for multiple registrations of the same Rope!
func register_rope(rope: Rope):
    if _is_multithreading:
        call_deferred("_register_rope", rope)
    else:
        _register_rope(rope)

# Unregistrations of non-registered Ropes produce a warning.
func unregister_rope(rope: Rope):
    # Call function immediately when not currently running threaded execution..
    # We can't just always use call_deferred(), because otherwise, Ropes that
    # unregister after being queue_free()ed will be deleted before
    # _unregister_rope is called, leaving invalid references.
    if _is_multithreading:
        call_deferred("_unregister_rope", rope)
    else:
        _unregister_rope(rope)


func _register_rope(rope: Rope):
    _ropes.append(rope)
    _start_stop_process()

func _unregister_rope(rope: Rope):
    var idx := _ropes.find(rope)
    if idx == -1:
        push_warning("Unregistering non-registered Rope")
        return

    if _ropes.size() > 1 and idx != _ropes.size() - 1:
        _ropes[idx] = _ropes.pop_back()  # Swap and pop
    else:
        _ropes.pop_back()

    _start_stop_process()


func get_num_threads() -> int:
    return _num_threads

func get_num_ropes() -> int:
    return _ropes.size()


func _physics_process(delta: float) -> void:
    _num_threads = int(clamp(1 + _ropes.size() / min_ropes_per_thread, min_threads, max_threads))  # warning-ignore: integer_division

    if _num_threads > 1:
        _is_multithreading = true
        var num_per_thread := _ropes.size() / _num_threads  # warning-ignore: integer_division

        for i in _num_threads:
            var start = i * num_per_thread
            var stop = start + num_per_thread if i != _num_threads - 1 else _ropes.size()
            _threads[i].start(self, "_thread_func", [ start, stop, delta])

        for i in _num_threads:
            _threads[i].wait_to_finish()

        _is_multithreading = false
    else:
        _rope_process_range(0, _ropes.size(), delta)


func _thread_func(userdata) -> void:
    var start: int = userdata[0]
    var stop: int = userdata[1]
    var delta: float = userdata[2]
    _rope_process_range(start, stop, delta)


func _rope_process_range(start: int, stop: int, delta: float):
    for i in range(start, stop):
        var rope: Rope = _ropes[i]
        # _simulate(rope, delta)
        rope._rope_process(delta)


func _start_stop_process():
    set_physics_process(_ropes.size() > 0)


# func _simulate(rope: Rope, delta: float) -> void:
#     var _points := rope._points
#     var _oldpoints := rope._oldpoints
#
#     # Simulate
#     for i in range(1, _points.size()):
#         var vel := (_points[i] - _oldpoints[i])
#         _oldpoints[i] = _points[i]
#         var dampmult := rope.damping_curve.interpolate_baked(rope.get_point_perc(i)) if rope.damping_curve else 1.0
#         _points[i] += damp_vec(vel, rope.damping * dampmult, delta) + Vector2(0, rope.gravity * delta)
#
#     # Constraint
#     for _i in rope.num_constraint_iterations:
#         _points[0] = rope.global_position
#         _points[1] = _points[0] + (_points[1] - _points[0]).normalized() * rope._seg_length
#
#         for i in range(1, _points.size() - 1):
#             var diff = _points[i + 1] - _points[i]
#             var distance: float = diff.length()
#             var dir: Vector2 = diff / distance
#             var error := (rope._seg_length - distance) * 0.5
#             _points[i] -= error * dir
#             _points[i + 1] += error * dir
#
#     rope._points = _points
#     rope._oldpoints = _oldpoints
#
#
# static func damp_vec(value: Vector2, damping_factor: float, delta: float) -> Vector2:
#     return value.linear_interpolate(Vector2.ZERO, 1.0 - exp(-damping_factor * delta))

tool
extends Node2D
class_name RopeBase

# This class exists solely to prevent dependencies issues when loading the Editor Plugin.
# plugin.gd -> Rope.gd -> NativeRopeServer -> NativeRopeServer hasn't been loaded yet
# -> Rope.gd Error -> plugin.gd Error

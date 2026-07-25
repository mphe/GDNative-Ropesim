shader_type canvas_item;

// This shader is part of the GDNative-Ropesim addon.
// It is used by RopeRendererLine2D.
// If needed, it can be replaced with a custom shader as long as it provides the same uniforms.

uniform float tilings = 1.0;

void vertex()
{
    UV.x *= tilings;
}

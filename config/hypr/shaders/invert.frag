#version 300 es
precision highp float;
in vec2 v_texcoord;
out vec4 fragColor;

// Mirror Hyprland's built-in sample() so this works across versions.
uniform sampler2D tex;

vec3 sample_hlsl(in sampler2D s, in vec2 uv) { return texture(s, uv).rgb; }

void main() {
    vec3 c = sample_hlsl(tex, v_texcoord);
    // Invert RGB, keep alpha.
    fragColor = vec4(1.0 - c.r, 1.0 - c.g, 1.0 - c.b, 1.0);
}

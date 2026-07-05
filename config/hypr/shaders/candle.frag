#version 300 es
precision highp float;
in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

// Warm candlelight tint — desaturates slightly and adds a golden glow.
void main() {
    vec3 c = texture(tex, v_texcoord).rgb;
    float g = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 warm = vec3(1.07, 0.95, 0.78);
    vec3 out_ = mix(vec3(g), c, 0.55) * warm;
    fragColor = vec4(clamp(out_, 0.0, 1.0), 1.0);
}

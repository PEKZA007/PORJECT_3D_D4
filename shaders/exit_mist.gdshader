shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;
uniform vec4 mist_color : source_color = vec4(0.23, 0.29, 0.28, 1.0);
uniform float density : hint_range(0.0, 1.0) = 0.38;
uniform float layer_seed = 0.0;
uniform sampler2D cloud_texture : repeat_enable, filter_linear;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float cloud(vec2 p) { return noise(p)*0.55+noise(p*2.07)*0.30+noise(p*4.03)*0.15; }
void fragment() {
    vec2 drift = vec2(TIME*0.055, -TIME*0.025);
    float n = texture(cloud_texture, UV*1.6+drift+vec2(layer_seed*.13)).r;
    float curls = texture(cloud_texture, UV*2.8-drift*.65+vec2(n*.12,layer_seed*.17)).r;
    float edge = smoothstep(0.0,0.10,UV.x)*smoothstep(0.0,0.10,1.0-UV.x);
    edge *= smoothstep(0.0,0.06,UV.y)*smoothstep(0.0,0.06,1.0-UV.y);
    float scene_depth = texture(depth_texture, SCREEN_UV).r;
    vec4 world_depth = INV_PROJECTION_MATRIX * vec4(vec3(SCREEN_UV,scene_depth)*2.0-1.0,1.0);
    world_depth.xyz /= world_depth.w;
    float soft_contact = clamp((-world_depth.z + VERTEX.z)*1.8,0.0,1.0);
    ALBEDO = mist_color.rgb * mix(0.45,1.45,n);
    ALPHA = clamp(density*smoothstep(0.1,0.8,n*.7+curls*.3)*edge*soft_contact,0.0,0.94);
}


shader_type spatial;
render_mode clustered;

uniform sampler2D albedo_texture;

void fragment() {
    vec3 normal = normalize(NORMAL);
    vec3 albedo = texture(albedo_texture, UV).rgb;
    vec3 diffuse_light = vec3(0.0);

    for (int i = 0; i < LIGHT_COUNT; i++) {
        vec3 light_dir = normalize(LIGHT_DIRECTION[i]);
        float diff = max(dot(normal, -light_dir), 0.0);
        diffuse_light += LIGHT_COLOR[i].rgb * diff;
    }

    ALBEDO = albedo;
    DIFFUSE_LIGHT = diffuse_light;
}

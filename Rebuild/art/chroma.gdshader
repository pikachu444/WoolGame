shader_type canvas_item;
render_mode unshaded;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float green = tex.g - max(tex.r, tex.b);
    float matte = 1.0 - smoothstep(0.16, 0.52, green);
    vec3 clean = tex.rgb;
    clean.g = min(clean.g, max(clean.r, clean.b) + 0.06);
    float neutral = 1.0 - smoothstep(0.06,0.18,max(clean.r,max(clean.g,clean.b))-min(clean.r,min(clean.g,clean.b)));
    clean = mix(clean,sqrt(max(clean,vec3(0.0))),neutral*0.36);
    COLOR = vec4(clean * tint.rgb, tex.a * tint.a * matte);
}

shader_type canvas_item;
render_mode unshaded;
void fragment(){
	vec4 sample_color=texture(TEXTURE,UV);
	float matte=smoothstep(0.12,0.27,distance(sample_color.rgb,vec3(0.,1.,0.)));
	COLOR=vec4(sample_color.rgb,sample_color.a*matte)*COLOR;
}

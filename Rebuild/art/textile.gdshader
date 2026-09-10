shader_type canvas_item;
render_mode unshaded;
varying vec2 position;
varying vec4 tint;
uniform float stage_bottom=552.;
uniform float dock_bottom=706.;
void vertex(){position=VERTEX;tint=COLOR;}
float segment(vec2 p,vec2 a,vec2 b){vec2 v=b-a;return length(p-a-v*clamp(dot(p-a,v)/dot(v,v),0.,1.));}
void fragment(){
	float row=floor(position.y/7.);
	vec2 p=mod(position+vec2(mod(row,2.)*3.5,0),7.)-3.5;
	float stitch=min(segment(p,vec2(-2.,-1.7),vec2(0.,1.5)),segment(p,vec2(0.,1.5),vec2(2.,-1.7)));
	float fine=1.-smoothstep(.15,1.,stitch);
	float weave=position.y<stage_bottom?.065:position.y<dock_bottom?.023:.011;
	vec3 base=mix(tint.rgb,vec3(1.),fine*weave);
	base-=weave*.10*(.5+.5*sin(position.y*1.57));
	COLOR=vec4(base,tint.a);
}

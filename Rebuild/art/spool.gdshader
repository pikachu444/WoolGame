shader_type canvas_item;
render_mode unshaded;
uniform vec4 yarn_color:source_color=vec4(.2,.5,1.,1.);
uniform float span=83.;
uniform float fill=0.;
uniform float opacity=1.;
varying vec2 p;
void vertex(){p=VERTEX;}
void fragment(){
	float h=(span-10.)*.5;
	vec4 out_color=vec4(0.);
	float rod=max(abs(p.x)-h,abs(p.y)-7.);
	float rod_alpha=1.-smoothstep(-.6,.6,rod);
	float round_y=sqrt(max(0.,1.-pow(p.y/8.,2.)));
	out_color=vec4(yarn_color.rgb*(.63+.45*round_y-.10*p.y/8.),rod_alpha);
	float start=-h+7.;
	float winding=7.+(span-21.)*fill;
	float coil_x=clamp(p.x,start,start+winding);
	float end_distance=abs(p.x-coil_x);
	float phase=(p.x-start)*.78-p.y*.05;
	float radius=21.5+.35*cos(phase);
	float yarn_edge=length(vec2(end_distance/5.,p.y/radius))-1.;
	float yarn_alpha=1.-smoothstep(-.025,.025,yarn_edge);
	float surface=sqrt(max(0.,1.-pow(p.y/23.,2.)));
	float strand=.045*cos(phase)+.009*cos(phase*2.);
	vec3 yarn=yarn_color.rgb*(.62+.42*surface+strand-.10*p.y/23.);
	out_color=mix(out_color,vec4(yarn,1.),yarn_alpha);
	for(int i=0;i<2;i++){
		float side=i==0?-1.:1.;
		vec2 q=(p-vec2(h*side,0.))/vec2(4.8,23.);
		float cap_alpha=1.-smoothstep(.92,1.06,length(q));
		float normal=sqrt(max(0.,1.-dot(q,q)));
		float light=.67+.40*normal-.16*q.x-.12*q.y;
		out_color=mix(out_color,vec4(yarn_color.rgb*light,1.),cap_alpha);
	}
	COLOR=out_color;COLOR.a*=opacity;
}

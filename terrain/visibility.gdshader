shader_type canvas_item;
// x,y - pos, z - active
uniform vec3[255] discoveries;
uniform float time: hint_range(0.0,10.0);
uniform float discovery_size: hint_range(0.0,1.0);
uniform float box_rounding: hint_range(0.0,1.0);
uniform float blurriness: hint_range(0.0,1.0);
uniform float blending: hint_range(0.0,1.0);

// https://iquilezles.org/articles/distfunctions2d/
float sdCircle( vec2 p, float r )
{
    return length(p) - r;
}

float sdRoundedBox( in vec2 p, in vec2 b, in vec4 r )
{
    r.xy = (p.x>0.0)?r.xy : r.zw;
    r.x  = (p.y>0.0)?r.x  : r.y;
    vec2 q = abs(p)-b+r.x;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}

float smin( float a, float b, float k )
{
    k *= 1.0;
    float r = exp2(-a/k) + exp2(-b/k);
    return -k*log2(r);
}

vec4 construct( in vec2 uv) {
	vec4 m = vec4(0.0,0.0,0.0,1.0);	
	for (int i = 0; i < discoveries.length();  i++) {
		if (discoveries[i].z != 1.) continue;
		m.w = smin(m.w, smoothstep(0.0,blurriness,sdRoundedBox(vec2(uv.x - discoveries[i].x, uv.y - discoveries[i].y),vec2(discovery_size,discovery_size),vec4(box_rounding))), blending) * 1.6;
	}
	return m;
}

void fragment() {
	float map = 1.0;
	
	vec2 uv = vec2((UV.x - 0.5) * (1920. / 1080.), UV.y - 0.5);
	COLOR = construct(uv);
}
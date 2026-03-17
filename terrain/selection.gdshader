shader_type canvas_item;
uniform float dash_length: hint_range(0., 2.);
uniform float dash_size: hint_range(0., 0.1);
uniform float dash_rounding: hint_range(0.0, 0.1);
uniform float dash_distance: hint_range(0.0,1.0);
uniform float circle_radius: hint_range(0.0,1.0);
uniform float time: hint_range(0.0,10.0);

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

vec4 construct( in vec2 uv) {
	vec4 m = vec4(0.0,0.0,0.0,1.0);	
	float t = uv.x;
	float r = (circle_radius);
	float l = 2. * PI / r;
	uv = vec2(
		r * cos(2. * PI * t / l),
		r * sin(2. * PI * t / l)
	);
	m.x = sdCircle(vec2(uv),0.1);
	m.y = 1.0 - smoothstep(0.0,0.0005,sdRoundedBox(vec2(uv.x - 0.8, uv.y - dash_distance * round(uv.y / dash_distance)),vec2(dash_size*dash_length,dash_size),vec4(dash_rounding)));
	return m;
}

void fragment() {
	COLOR = vec4(1.0);
	float map = 1.0;
	
	vec2 uv = vec2((UV.x - 0.5) * (1920. / 1080.), UV.y - 0.5);
	COLOR = construct(uv);
}
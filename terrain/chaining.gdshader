shader_type canvas_item;
uniform float circle_size;
uniform float outline_width;
uniform float outline_fuzziness;
uniform vec2[100] structure_positions;

// https://iquilezles.org/articles/distfunctions2d/
float sdCircle( vec2 p, float r )
{
    return length(p) - r;
}

float smin( float a, float b, float k )
{
    k *= 4.0;
    float h = max( k-abs(a-b), 0.0 )/k;
    return min(a,b) - h*h*k*(1.0/4.0);
}

void fragment() {
	vec2 n_uv = vec2((UV.x) * 1920./1080., UV.y);
	COLOR = vec4(1.0);
	float map = 1.;
	for (int i = 0; i < structure_positions.length(); i++) {
		map = smin(map, sdCircle(n_uv-structure_positions[i], circle_size), 0.005);
	}
	COLOR.a = smoothstep(0.0, outline_fuzziness, smoothstep(-outline_fuzziness, 0.0, map) - smoothstep(0.0, outline_width, map));;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

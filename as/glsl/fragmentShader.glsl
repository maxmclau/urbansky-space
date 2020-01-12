// Original fragment shader noise work written
// by Arno Di Nunzio <https://github.com/aqro>

const float spores_size = 0.3; // diameter of the spore ellipse - 1.0 represents the full width and height of the scene
const float spores_int = 2.0; // the higher this number, the more noise introduced

const float ex_int = 1.1; // the higher this number, the more noise introduced to the eclusion zone
const float ex_en = -1.0; // set to -1.0 to activate exlusion zone, otherwise set it to 1.0 to view it as a normal tear

const float mouse_size = 0.05; // size of mouse spore
const float mouse_int = 4.0; // the higher this number, the more noise introduced to the mouse zone

const float sharpness = 0.485; // typically between 0.4 and 0.5 with 0.5 being the max

uniform sampler2D u_image; // satellite image to be masked

uniform vec2 u_mouse_c; // mouse position in THREE.js coords
uniform vec2 u_res; // width and height of screen

uniform vec2 u_exclusion_c; // center of exclusion zone
uniform float u_exclusion_s; // width of exclusion zone

uniform float u_time; // time in animation used to seed noise

uniform float u_itensity; // global intensity multiplier - used to fade in our animation after loading is complete

varying vec2 v_uv;

const vec4 contrast = vec4(0.0, 0.0, 0.0, 0.0);

float circle(in vec2 _st, in float _radius, in float blur) {
  return 1. - smoothstep(_radius - (_radius * blur), _radius + (_radius * blur), dot(_st, _st) * 4.0);
}

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
  return mod289(((x * 34.0) + 1.0) * x);
}

vec4 taylorInvSqrt(vec4 r) {
  return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise3(vec3 v) {
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

  // first corner
  vec3 i  = floor(v + dot(v, C.yyy));
  vec3 x0 =   v - i + dot(i, C.xxx);

  // other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min(g.xyz, l.zxy);
  vec3 i2 = max(g.xyz, l.zxy);

  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

  // permutations
  i = mod289(i);
  vec4 p = permute(permute(permute(
      i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
    + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
    + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

  // gradients: 7x7 points over a square, mapped onto an octahedron.
  // ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  float n_ = 0.142857142857; // 1.0/7.0
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_); // mod(j,N)

  vec4 x = x_ * ns.x + ns.yyyy;
  vec4 y = y_ * ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4(x.xy, y.xy);
  vec4 b1 = vec4(x.zw, y.zw);

  vec4 s0 = floor(b0) * 2.0 + 1.0;
  vec4 s1 = floor(b1) * 2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww ;

  vec3 p0 = vec3(a0.xy, h.x);
  vec3 p1 = vec3(a0.zw, h.y);
  vec3 p2 = vec3(a1.xy, h.z);
  vec3 p3 = vec3(a1.zw, h.w);

  // normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

  // mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
  m = m * m;
  return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1),
                                dot(p2, x2), dot(p3, x3)));
}

void main() {
	// we manage the device ratio by passing dPR constant
	vec2 res = u_res * dPR;
	vec2 st = gl_FragCoord.xy / res.xy - vec2(0.5);

	// tip: use the following formula to keep the good ratio of your coordinates
	// st.y *= u_res.y / u_res.x;

	float spore_a = circle(st + vec2(-0.2, 0.3), spores_size * u_itensity, spores_int) * 1.9;
  float spore_b = circle(st + vec2(0, -0.2), .1 * u_itensity, spores_int) * 2.1;

  vec2 exclusion_c = st + (u_exclusion_c * -0.5);
	float exclusion = circle(exclusion_c, u_exclusion_s, ex_int) * 2.0;

  vec2 mouse_c = st + (u_mouse_c * -0.5);
	float mouse = circle(mouse_c, mouse_size * u_itensity, mouse_int) * 2.0;

	float offx = v_uv.x + sin(v_uv.y + u_time * 0.1);
	float offy = v_uv.y - u_time * 0.1 - cos(u_time * .001) * .01;

	float noise = snoise3(vec3(offx, offy, u_time * 0.1) * 8.0) - 1.0;

  float elements = noise + (pow(exclusion, 2.0) * ex_en) + pow(mouse, 2.0) + pow(spore_a, 2.0) + pow(spore_b, 2.0);

	float mask = smoothstep(sharpness, 0.5, elements);

  vec4 image = texture2D(u_image, v_uv);

	gl_FragColor = mix(contrast, image, mask);
}
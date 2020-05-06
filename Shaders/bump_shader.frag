#version 120

uniform int active_lights_n; // Number of active lights (< MG_MAX_LIGHT)
uniform vec3 scene_ambient; // Scene ambient light

struct material_t {
	vec3  diffuse;
	vec3  specular;
	float alpha;
	float shininess;
};

struct light_t {
	vec4 position;    // Camera space
	vec3 diffuse;     // rgb
	vec3 specular;    // rgb
	vec3 attenuation; // (constant, lineal, quadratic)
	vec3 spotDir;     // Camera space
	float cosCutOff;  // cutOff cosine
	float exponent;
};

uniform light_t theLights[4];
uniform material_t theMaterial;

uniform sampler2D texture0;
uniform sampler2D bumpmap;

varying vec2 f_texCoord;
varying vec3 f_viewDirection;     // tangent space
varying vec3 f_lightDirection[4]; // tangent space
varying vec3 f_spotDirection[4];  // tangent space

vec3 get_light_value(vec3 n, vec3 l, vec3 v, int i) {
			float dotnl = dot(n, l);
			vec3 r = 2*dotnl*n - l;
			vec3 i_diff = theMaterial.diffuse * theLights[i].diffuse;
			vec3 i_spec = pow(max(0, dot(r, v)), theMaterial.shininess) * theMaterial.specular * theLights[i].specular;
			return max(0, dotnl) * (i_diff + i_spec);
}

void main() {
	// Base color
	vec4 baseColor = texture2D(texture0, f_texCoord);

	// Decode the tangent space normal (from [0..1] to [-1 ... +1])
	vec3 N = texture2D(bumpmap, f_texCoord).rgb * 2.0 - 1.0;

	// Compute ambient, diffuse and specular contribution
	vec3 i_tot = vec3(0, 0, 0);
	vec3 v = normalize(f_viewDirection);

	for (int i = 0; i < active_lights_n; i++) 
	{
		if (theLights[i].position.w == 0.0f) 
		{
			// directional
			i_tot += get_light_value(N, f_lightDirection[i], f_viewDirection, i);
		} 
		else if (theLights[i].cosCutOff == 0.0f) 
		{
			// positional
			float d = 1.0; // ahuldurarik ez

			i_tot += d * get_light_value(N, f_lightDirection[i], f_viewDirection, i);
		} 
		else 
		{
			// spotlight
			float c = max(dot(-f_lightDirection[i], normalize(theLights[i].spotDir)), 0);
			if (c > theLights[i].cosCutOff)
				i_tot += pow(c, theLights[i].exponent) * get_light_value(N, f_lightDirection[i], f_viewDirection, i);
		}
	}

	vec4 f_color = vec4(scene_ambient + i_tot, 1.0);

	// Final color
	gl_FragColor = f_color * baseColor;
}

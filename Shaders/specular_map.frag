#version 120

uniform int active_lights_n; // Number of active lights (< MG_MAX_LIGHT)
uniform vec3 scene_ambient; // Scene ambient light

uniform struct light_t {
	vec4 position;    // Camera space
	vec3 diffuse;     // rgb
	vec3 specular;    // rgb
	vec3 attenuation; // (constant, lineal, quadratic)
	vec3 spotDir;     // Camera space
	float cosCutOff;  // cutOff cosine
	float exponent;
} theLights[4];     // MG_MAX_LIGHTS

uniform struct material_t {
	vec3  diffuse;
	vec3  specular;
	float alpha;
	float shininess;
} theMaterial;

uniform sampler2D texture0;
uniform sampler2D specmap;    // specular map

varying vec3 f_position;      // camera space
varying vec3 f_viewDirection; // camera space
varying vec3 f_normal;        // camera space
varying vec2 f_texCoord;

vec3 get_light_value(vec3 n, vec3 l, vec3 v, vec3 m_spec, int i) {
			float dotnl = dot(n, l);
			vec3 r = 2*dotnl*n - l;
			vec3 i_diff = theMaterial.diffuse * theLights[i].diffuse;
			vec3 i_spec = pow(max(0, dot(r, v)), theMaterial.shininess) * m_spec * theLights[i].specular;
			return max(0, dotnl) * (i_diff + i_spec);
}

void main() {
	vec3 i_tot = vec3(0, 0, 0);

	vec3 p = f_position;
	vec3 n = normalize(f_normal);
	vec3 v = normalize(f_viewDirection);

	vec3 m_spec = texture2D(specmap, f_texCoord).xyz;

	for (int i = 0; i < active_lights_n; i++) 
	{
		if (theLights[i].position.w == 0.0f) 
		{
			// directional
			vec3 l = -normalize(theLights[i].position.xyz);

			i_tot += get_light_value(n, l, v, m_spec, i);
		} 
		else if (theLights[i].cosCutOff == 0.0f) 
		{
			// positional
			vec3 l_dir = theLights[i].position.xyz - p;
			float l_mod2 = dot(l_dir, l_dir);
			float l_mod = sqrt(l_mod2);
			vec3 l = l_dir / l_mod;
			float d = 1.f / (
				theLights[i].attenuation[0] + 
				theLights[i].attenuation[1] * l_mod + 
				theLights[i].attenuation[2] * l_mod2);

			i_tot += d * get_light_value(n, l, v, m_spec, i);
		} 
		else 
		{
			// spotlight
			vec3 l = normalize(theLights[i].position.xyz - p);

			float c = max(dot(-l, normalize(theLights[i].spotDir)), 0);
			if (c > theLights[i].cosCutOff)
				i_tot += pow(c, theLights[i].exponent) * get_light_value(n, l, v, m_spec, i);
		}
	}

	vec4 f_color = vec4(scene_ambient + i_tot, 1.0);

	vec4 texColor = texture2D(texture0, f_texCoord);
	gl_FragColor = f_color * texColor;
}

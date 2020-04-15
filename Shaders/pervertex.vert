#version 120

uniform mat4 modelToCameraMatrix;
uniform mat4 cameraToClipMatrix;
uniform mat4 modelToWorldMatrix;
uniform mat4 modelToClipMatrix;

uniform int active_lights_n; // Number of active lights (< MG_MAX_LIGHT)
uniform vec3 scene_ambient;  // rgb

uniform struct light_t {
	vec4 position;    // Camera space --> theLights[0].position.xyz == l, argiaren norabidea
	vec3 diffuse;     // rgb	--> s_dif
	vec3 specular;    // rgb	--> s_spec
	vec3 attenuation; // (constant, lineal, quadratic)
	vec3 spotDir;     // Camera space
	float cosCutOff;  // cutOff cosine
	float exponent;
} theLights[4];     // MG_MAX_LIGHTS

uniform struct material_t {
	vec3  diffuse;		// m_dif
	vec3  specular;		// m_spec
	float alpha;		// 1
	float shininess;	// m
} theMaterial;

// GARRANTZITSUA: Kalkulu guztiak kameraren espazioan.
// dot(theLights[0].position.xyz, v_normal) GAIZKI
// GLSL apunteetan espazio-aldaketen inguruko gardenkia.

attribute vec3 v_position; // Model space
attribute vec3 v_normal;   // Model space
attribute vec2 v_texCoord;

varying vec4 f_color;
varying vec2 f_texCoord;

vec3 get_light_value(vec3 n, vec3 l, vec3 v, struct light_t theLight) {
			float dotnl = dot(n, l);
			vec3 r = 2*dotnl*n - l;
			vec3 i_diff = theMaterial.diffuse * theLight.diffuse;
			vec3 i_spec = pow(max(0, dot(r, v)), theMaterial.shininess) * theMaterial.specular * theLight.specular;
			return max(0, dotnl) * (i_diff + i_spec);
}

void main() {
	gl_Position = modelToClipMatrix * vec4(v_position, 1);
	f_texCoord = v_texCoord;

	vec3 i_tot = vec3(0, 0, 0);

	vec3 p = (modelToCameraMatrix * vec4(v_position, 1.0)).xyz;
	vec3 n = normalize((modelToCameraMatrix * vec4(v_normal, 0.0)).xyz);
	vec3 v = -normalize(p);

	for (int i = 0; i < active_lights_n; i++) 
	{
		if (theLights[i].position.w == 0.0f) 
		{
			// directional
			vec3 l = -normalize(theLights[i].position.xyz);

			i_tot += get_light_value(n, l, v, theLights[i]);
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

			i_tot += d * get_light_value(n, l, v, theLights[i]);
		} 
		else 
		{
			// spotlight
			vec3 l = normalize(theLights[i].position.xyz - p);

			float c = max(dot(-l, normalize(theLights[i].spotDir)), 0);
			if (c > theLights[i].cosCutOff)
				i_tot += pow(c, theLights[i].exponent) * get_light_value(n, l, v, theLights[i]);
		}
	}

	f_color = vec4(scene_ambient + i_tot, 1.0);
}

/*
void get_light_value(in vec3 n, in vec3 l, in struct light_t theLight, out float dotnl, out vec3 i_diff, out vec3 i_spec) {
			dotnl = dot(n, l);
			vec3 r = 2*dotnl*n - l;
			i_diff = theMaterial.diffuse * theLight.diffuse;
			i_spec = pow(max(0, dot(r, v)), theMaterial.shininess) * theMaterial.specular * theLight.specular;
}
*/
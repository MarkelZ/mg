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


void main() {
	gl_Position = modelToClipMatrix * vec4(v_position, 1);
	// Argiztatzea
	vec3 n = normalize((modelToCameraMatrix * vec4(v_normal, 0.0)).xyz);
	vec3 l = normalize(-theLights[0].position.xyz);
	float dotnl = dot(n, l);
	vec3 r = 2*dotnl*n - l;
	vec3 v = normalize((modelToCameraMatrix * vec4(v_position, 0.0)).xyz);
	vec3 i_diff = theMaterial.diffuse * theLights[0].diffuse;
	vec3 i_spec = pow(max(0, dot(r, v)), theMaterial.shininess) * (theMaterial.specular * theLights[0].specular);
	f_color = vec4(scene_ambient + max(0, dotnl)*(i_diff + i_spec), 1.0);

	// norabidezko argiaren kalkuluak
	// vec4 position_cs = modelToCameraMatrix * vec4(v_position, 1.0);
	// vec3 l = (theLights[0].position - position_cs).xyz;
	// l = normalize(l.xyz);
}

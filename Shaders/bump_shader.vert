#version 120

// Bump mapping with many lights.

// all attributes in model space
attribute vec3 v_position;
attribute vec3 v_normal;
attribute vec2 v_texCoord;
attribute vec3 v_TBN_t;
attribute vec3 v_TBN_b;

uniform mat4 modelToCameraMatrix;
uniform mat4 modelToWorldMatrix;
uniform mat4 cameraToClipMatrix;
uniform mat4 modelToClipMatrix;

uniform int active_lights_n; // Number of active lights (< MG_MAX_LIGHT)

uniform struct light_t {
	vec4 position;    // Camera space
	vec3 diffuse;     // rgb
	vec3 specular;    // rgb
	vec3 attenuation; // (constant, lineal, quadratic)
	vec3 spotDir;     // Camera space
	float cosCutOff;  // cutOff cosine
	float exponent;
} theLights[4];     // MG_MAX_LIGHTS

// All bump computations are performed in tangent space; therefore, we need to
// convert all light (and spot) directions and view directions to tangent space
// and pass them the fragment shader.

varying vec2 f_texCoord;
varying vec3 f_viewDirection;     // tangent space
varying vec3 f_lightDirection[4]; // tangent space
varying vec3 f_spotDirection[4];  // tangent space

void main() {
	gl_Position = modelToClipMatrix * vec4(v_position, 1.0);

	// get 3x3 modelview matrix
	mat3 MV3x3 = mat3(modelToCameraMatrix);

	// Normal, tangent and bitangent in camera coordinates
	// (object space -> camera space)
	vec3 t = normalize((modelToCameraMatrix * vec4(v_TBN_t, 0.0)).xyz);
	vec3 b = normalize((modelToCameraMatrix * vec4(v_TBN_b, 0.0)).xyz);
	vec3 n = normalize((modelToCameraMatrix * vec4(v_normal, 0.0)).xyz);

	// matrix to transform from camera space to tangent space
	mat3 cameraToTangent = mat3(t, b, n); 

	// Ligth direction, f_viewDirection, f_spotDirection are in camera space
	// (camera space -> tangent space)
	vec3 p = (modelToCameraMatrix * vec4(v_position, 1.0)).xyz;
	vec3 l;

	for (int i = 0; i < active_lights_n; i++) {
		if (theLights[i].position.w == 0.0f) 
		{
			// directional
			l = -normalize(theLights[i].position.xyz);
		} 
		else if (theLights[i].cosCutOff == 0.0f) {
			// positional
			l = normalize(theLights[i].position.xyz - p);
		} 
		else {
			// spotlight
			l = normalize(theLights[i].position.xyz - p);
			f_spotDirection[i] = theLights[i].spotDir * cameraToTangent;
		}
		f_lightDirection[i] = l * cameraToTangent;
	}
	vec3 v = -normalize(p);
	f_viewDirection = v * cameraToTangent;
}

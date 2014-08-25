#version 130

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*!	PP_DeferredLighting - Shader for calculating lighting based on geometry data
	                      packed into textures.
	2009-12-09 - Benjamin Eikel
 */

in vec2 texCoord;

out vec4 fragColor;

uniform sampler2D sg_texture0; // Position, w contains gl_FragCoord.z
uniform sampler2D sg_texture1; // Normal, w contains shininess
uniform sampler2D sg_texture2; // Ambient
uniform sampler2D sg_texture3; // Diffuse
uniform sampler2D sg_texture4; // Specular

struct sg_LightSourceParameters {
	int type; // has to be DIRECTIONAL, POINT or SPOT
	
	vec3 position; // position of the light
	vec3 direction; // direction of the light, has to be normalized
	
	// light colors for all lights
	vec4 ambient;
	vec4 diffuse;
	vec4 specular;
	
	// attenuations for point & spot lights
	float constant;
	float linear;
	float quadratic;
	
	// spot light parameters
	float exponent;
	float cosCutoff;
	
};
uniform sg_LightSourceParameters sg_LightSource[8];
uniform int sg_lightCount;

uniform mat4 sg_matrix_worldToCamera;

void main(void) {
	vec4 position = texture(sg_texture0, texCoord);
	
	// No calculations for the background.
	// position.w == 1.0 if pixel belongs to the background.
	if(position.w == 1.0) {
		discard;
	}
	
	vec4 normal = texture(sg_texture1, texCoord);
	
	vec4 materialAmbient = texture(sg_texture2, texCoord);
	vec4 materialDiffuse = texture(sg_texture3, texCoord);
	vec4 materialSpecular = texture(sg_texture4, texCoord);
	float shininess = normal.w;
	
	vec4 ambient = vec4(0.0);
	vec4 diffuse = vec4(0.0);
	vec4 specular = vec4(0.0);
	
// 	Old format: Light sources data packed into a texture
// 	
// 	float size = 5.0 * float(sg_lightCount);
// 
// 	for(int l = 0; l < sg_lightCount; l++) {
// 		// Light texture format
// 		// 1.0: | position.x 	| position.y	| position.z	|
// 		// 2.0: | ambient.r		| ambient.g		| ambient.b		|
// 		// 3.0: | diffuse.r		| diffuse.g		| diffuse.b		|
// 		// 4.0: | specular.r	| specular.g	| specular.b	|
// 		// 5.0: | constantAtt	| linearAtt		| quadraticAtt	|
// 		vec4 lightPos = vec4(texture1D(sg_lightData, (float(5 * l) + 0.5) / size).xyz, 1.0);
// 		vec4 lightAmbient = vec4(texture1D(sg_lightData, (float(5 * l) + 1.5) / size).rgb, 1.0);
// 		vec4 lightDiffuse = vec4(texture1D(sg_lightData, (float(5 * l) + 2.5) / size).rgb, 1.0);
// 		vec4 lightSpecular = vec4(texture1D(sg_lightData, (float(5 * l) + 3.5) / size).rgb, 1.0);
// 		//vec4 lightAttenuation = vec4(texture1D(sg_lightData, (float(5 * l) + 4.5) / size).rgb, 1.0);
// 		
// 		...
// 	}

	for(int l = 0; l < sg_lightCount; l++) {
		vec4 lightPos = vec4(sg_LightSource[l].position, 1.0);

		lightPos = sg_matrix_worldToCamera * lightPos;
		lightPos /= lightPos.w;

		vec3 lightDir = lightPos.xyz - position.xyz;
		
		float lightDist = length(lightDir);
		
		lightDir = normalize(lightDir);
		
		float attenuation = 1.0 /	(sg_LightSource[l].constant + 
									sg_LightSource[l].linear * lightDist +
									sg_LightSource[l].quadratic * lightDist * lightDist);
		
		vec3 halfVector = normalize(lightDir + normalize(-1.0 * position.xyz));
		
		float nDotLightDir = max(0.0, dot(normal.xyz, lightDir));
		
		float specPower = 0.0;
		if(nDotLightDir > 0.0) {
			float nDotHalfVec = max(0.0, dot(normal.xyz, halfVector));
			specPower = pow(nDotHalfVec, shininess);
		}
		
		ambient += sg_LightSource[l].ambient * attenuation;
		diffuse += sg_LightSource[l].diffuse * nDotLightDir * attenuation;
		specular += sg_LightSource[l].specular * specPower * attenuation;
	}

	fragColor = (	materialAmbient * ambient + 
					materialDiffuse * diffuse + 
					materialSpecular * specular);
}

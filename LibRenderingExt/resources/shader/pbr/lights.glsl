/*
	This file is part of the open source part of the
	Platform for Algorithm Development and Rendering (PADrend).
	Web page: http://www.padrend.de/
	Copyright (C) 2020-2021 Sascha Brandt <sascha@brandt.graphics>

	PADrend consists of an open source part and a proprietary part.
	The open source part of PADrend is subject to the terms of the Mozilla
	Public License, v. 2.0. You should have received a copy of the MPL along
	with this library; see the file LICENSE. If not, you can obtain one at
	http://mozilla.org/MPL/2.0/.
*/
#ifndef RENDERING_SHADER_LIGHTS_GLSL_
#define RENDERING_SHADER_LIGHTS_GLSL_

#include "structs.glsl"

#define DIRECTIONAL 1
#define POINT 2
#define SPOT 3

#ifndef MAX_LIGHTS
#define MAX_LIGHTS 8
#endif

struct sg_LightSourceParameters {
	int type;														// has to be DIRECTIONAL, POINT or SPOT
	vec3 position;											// position of the light
	vec3 direction;											// direction of the light, has to be normalized ????????????????????????????????
	vec4 ambient, diffuse, specular;		// light colors for all lights
	float constant, linear, quadratic;	// attenuations for point & spot lights
	float exponent, cosCutoff;					// spot light parameters
};

uniform sg_LightSourceParameters sg_LightSource[MAX_LIGHTS];
uniform int sg_lightCount;

LightSample evalLight(in SurfaceSample surface, in sg_LightSourceParameters light) {
	LightSample ls;

	// for DIRECTIONAL lights
	vec3 L = -light.direction;
	float falloff = 1.0;
			
	// for POINT & SPOT lights
	if(light.type != DIRECTIONAL) { 
		L = light.position - surface.position;
		float dist = length(L); 
		L = normalize(L);
		falloff /= (light.constant + light.linear * dist + light.quadratic * dist * dist);
	}

	// for SPOT lights
	if(light.type == SPOT) {
		float cosTheta = dot(L, -light.direction); // cos of angle of light orientation
		if(cosTheta < light.cosCutoff) {
			falloff = 0.0;
		} else {
			falloff *= pow(cosTheta, light.exponent);
		}
	}
	
	vec3 H = normalize(normalize(-surface.position) + L);
	ls.NdotL = clamp(dot(surface.normal, L), 0.0, 1.0);
	ls.NdotH = clamp(dot(surface.normal, H), 0.0, 1.0);
	ls.LdotH = clamp(dot(L, H), 0.0, 1.0);
	ls.VdotH = clamp(dot(-surface.position, H), 0.0, 1.0);
	//ls.intensity = light.ambient + light.diffuse * falloff;
	ls.intensity = light.diffuse.rgb * falloff;
	ls.ambient = light.ambient.rgb;
	return ls;
}

#endif /* end of include guard: RENDERING_SHADER_LIGHTS_GLSL_ */
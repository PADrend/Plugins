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
#ifndef RENDERING_SHADER_IBL_GLSL_
#define RENDERING_SHADER_IBL_GLSL_

#ifdef USE_IBL
#include "structs.glsl"
#include "tonemapping.glsl"

layout(binding=7) uniform samplerCube sg_irradianceMap;
layout(binding=8) uniform samplerCube sg_prefilteredEnvMap;
layout(binding=9) uniform sampler2D sg_brdfLUT;
uniform int sg_envMipCount = 5;
uniform bool sg_envEnabled = false;
uniform mat4 sg_matrix_cameraToWorld;

vec3 getIBLSpecular(in SurfaceSample surface, in MaterialSample material) {
	if(!sg_envEnabled)
		return vec3(0.0);
	float lod = material.roughness * float(sg_envMipCount - 1);
	vec4 worldView = sg_matrix_cameraToWorld * vec4(surface.view, 0.0);
	vec4 worldNormal = sg_matrix_cameraToWorld * vec4(surface.normal, 0.0);
	vec3 reflection = normalize(reflect(-worldView.xyz, worldNormal.xyz));

	vec2 brdfSamplePoint = clamp(vec2(surface.NdotV, material.roughness), vec2(0.0, 0.0), vec2(1.0, 1.0));
	vec2 f_ab = texture(sg_brdfLUT, brdfSamplePoint).rg;
	vec3 specularLight = linearTosRGB(textureLod(sg_prefilteredEnvMap, reflection, lod).rgb);
	
	vec3 Fr = max(vec3(1.0 - material.roughness), material.specular) - material.specular;
	vec3 k_S = material.specular + Fr * pow(1.0 - surface.NdotV, 5.0);
	vec3 FssEss = k_S * f_ab.x + f_ab.y;

	return specularLight * FssEss;
}

vec3 getIBLDiffuse(in SurfaceSample surface, in MaterialSample material) {
	if(!sg_envEnabled)
		return vec3(0.0);
	vec4 worldNormal = sg_matrix_cameraToWorld * vec4(surface.normal, 0.0);

	vec2 brdfSamplePoint = clamp(vec2(surface.NdotV, material.roughness), vec2(0.0, 0.0), vec2(1.0, 1.0));
	vec2 f_ab = texture(sg_brdfLUT, brdfSamplePoint).rg;

	vec3 irradiance = linearTosRGB(texture(sg_irradianceMap, worldNormal.xyz).rgb);

	vec3 Fr = max(vec3(1.0 - material.roughness), material.specular) - material.specular;
	vec3 k_S = material.specular + Fr * pow(1.0 - surface.NdotV, 5.0);
	vec3 FssEss = k_S * f_ab.x + f_ab.y;

	float Ems = (1.0 - (f_ab.x + f_ab.y));
	vec3 F_avg = (material.specular + (1.0 - material.specular) / 21.0);
	vec3 FmsEms = Ems * FssEss * F_avg / (1.0 - F_avg * Ems);
	vec3 k_D = material.diffuse * (1.0 - FssEss + FmsEms);

	return (FmsEms + k_D) * irradiance;
}

#else

vec3 getIBLSpecular(in SurfaceSample surface, in MaterialSample material) {
	return vec3(0.0);
}

vec3 getIBLDiffuse(in SurfaceSample surface, in MaterialSample material) {
	return vec3(0.0);
}

#endif

#endif /* end of include guard: RENDERING_SHADER_IBL_GLSL_ */
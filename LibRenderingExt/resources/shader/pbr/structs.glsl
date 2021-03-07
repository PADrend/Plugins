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
#ifndef RENDERING_SHADER_COMMON_GLSL_
#define RENDERING_SHADER_COMMON_GLSL_

struct VertexData {
	vec3 position;
	vec3 normal;
	vec4 color;
	vec2 texCoord0;
	vec2 texCoord1;
};

struct SurfaceSample {
	vec3 position;
	vec3 geometricNormal;
	vec3 normal;
	vec3 tangent;
	vec3 bitangent;
	float NdotV;
};

struct LightSample {
	vec3 intensity;
	vec3 ambient;
	float NdotL;
	float NdotH;
	float LdotH;
	float VdotH;
};

struct MaterialSample {
	vec4 baseColor;
	vec3 diffuse;
	vec3 specular;
	vec3 specular_f90;
	vec3 emissive;
	float metallic;
	float roughness;
	float alphaRoughness;
	float occlusion;
};

struct CompositeColor {
	vec3 diffuse;
	vec3 specular;
	vec3 emissive;
};

#endif /* end of include guard: RENDERING_SHADER_COMMON_GLSL_ */
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
#ifndef RENDERING_SHADER_MATERIALS_GLSL_
#define RENDERING_SHADER_MATERIALS_GLSL_

#include "structs.glsl"
#include "brdf.glsl"

// The default index of refraction of 1.5 yields a dielectric normal incidence reflectance of 0.04.
const float ior = 1.5;
const float f0_ior = 0.04;

uniform vec4 sg_pbrBaseColorFactor;
#ifdef HAS_BASECOLOR_TEXTURE
uniform int sg_pbrBaseColorTexCoord;
layout(binding=BASECOLOR_TEXUNIT) uniform sampler2D sg_baseColorTexture;
#endif

uniform float sg_pbrMetallicFactor;
uniform float sg_pbrRoughnessFactor;
#ifdef HAS_METALLICROUGHNESS_TEXTURE
uniform int sg_pbrMetallicRoughnessTexCoord;
layout(binding=METALLICROUGHNESS_TEXUNIT) uniform sampler2D sg_metallicRoughnessTexture;
#endif

uniform float sg_pbrNormalScale;
uniform int sg_pbrNormalTexCoord;
#ifdef HAS_NORMAL_TEXTURE
layout(binding=NORMAL_TEXUNIT) uniform sampler2D sg_normalTexture;
#endif

uniform float sg_pbrOcclusionStrength;
#ifdef HAS_OCCLUSION_TEXTURE
uniform int sg_pbrOcclusionTexCoord;
layout(binding=OCCLUSION_TEXUNIT) uniform sampler2D sg_occlusionTexture;
#endif

uniform vec3 sg_pbrEmissiveFactor;
#ifdef HAS_EMISSIVE_TEXTURE
uniform int sg_pbrEmissiveTexCoord;
layout(binding=EMISSIVE_TEXUNIT) uniform sampler2D sg_emissiveTexture;
#endif

#ifdef ALPHA_MODE_MASK
uniform float sg_pbrAlphaCutoff;
#endif

vec4 getBaseColor(in VertexData vertex) {
	vec4 baseColor = sg_pbrBaseColorFactor;
	#ifdef HAS_BASECOLOR_TEXTURE
		vec2 uv = sg_pbrBaseColorTexCoord < 1 ? vertex.texCoord0 : vertex.texCoord1;
		baseColor *= texture(sg_baseColorTexture, uv);
	#endif
	baseColor *= vertex.color;
	
	#ifdef ALPHA_MODE_OPAQUE
		baseColor.a = 1.0;
	#endif
	
	return baseColor;
}

vec2 getMetallicRoughness(in VertexData vertex) {
	vec2 metallicRoughness = vec2(sg_pbrMetallicFactor, sg_pbrRoughnessFactor);
	#ifdef HAS_METALLICROUGHNESS_TEXTURE
		vec2 uv = sg_pbrBaseColorTexCoord < 1 ? vertex.texCoord0 : vertex.texCoord1;
		metallicRoughness *= texture(sg_metallicRoughnessTexture, uv).bg;
	#endif
	return metallicRoughness;
}

float getOcclusion(in VertexData vertex) {
	float occlusion = 1.0;
	#ifdef HAS_OCCLUSION_TEXTURE
		vec2 uv = sg_pbrOcclusionTexCoord < 1 ? vertex.texCoord0 : vertex.texCoord1;
		occlusion = mix(1.0, texture(sg_occlusionTexture, uv).r, sg_pbrOcclusionStrength);
	#endif
	return occlusion;
}

vec3 getEmissive(in VertexData vertex) {
	vec3 emissive = sg_pbrEmissiveFactor;
	#ifdef HAS_EMISSIVE_TEXTURE
		vec2 uv = sg_pbrEmissiveTexCoord < 1 ? vertex.texCoord0 : vertex.texCoord1;
		emissive *= texture(sg_emissiveTexture, uv).rgb;
	#endif
	return emissive;
}

MaterialSample initMaterial(in VertexData vertex) {
	MaterialSample material;
	material.baseColor = getBaseColor(vertex);
	vec2 metallicRoughness = getMetallicRoughness(vertex);
	material.metallic = clamp(metallicRoughness.x, 0.0, 1.0);
	material.roughness = clamp(metallicRoughness.y, 0.0, 1.0);
	material.emissive = getEmissive(vertex);
	material.alphaRoughness = material.roughness * material.roughness;
	material.occlusion = getOcclusion(vertex);

	vec3 f0 = vec3(f0_ior);
	material.diffuse = mix(material.baseColor.rgb * (vec3(1.0) - f0), vec3(0.0), material.metallic);
	material.specular = mix(f0, material.baseColor.rgb, material.metallic);
	
	float reflectance = max(max(material.specular.r, material.specular.g), material.specular.b);
	material.specular_f90 = vec3(clamp(reflectance * 50.0, 0.0, 1.0));
	return material;
}

#endif /* end of include guard: RENDERING_SHADER_MATERIALS_GLSL_ */
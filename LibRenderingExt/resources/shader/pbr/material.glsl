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

#ifndef BASECOLOR_TEXUNIT
#define BASECOLOR_TEXUNIT 0
#endif
#ifndef METALLICROUGHNESS_TEXUNIT
#define METALLICROUGHNESS_TEXUNIT 1
#endif
#ifndef NORMAL_TEXUNIT
#define NORMAL_TEXUNIT 2
#endif
#ifndef OCCLUSION_TEXUNIT
#define OCCLUSION_TEXUNIT 3
#endif
#ifndef EMISSIVE_TEXUNIT
#define EMISSIVE_TEXUNIT 4
#endif

#include "structs.glsl"
#include "brdf.glsl"

// The default index of refraction of 1.5 yields a dielectric normal incidence reflectance of 0.04.
uniform float sg_pbrIOR = 1.5;

uniform vec4 sg_pbrBaseColorFactor;
#ifdef HAS_BASECOLOR_TEXTURE
uniform int sg_pbrBaseColorTexCoord;
uniform mat3 sg_pbrBaseColorTexTransform;
layout(binding=BASECOLOR_TEXUNIT) uniform sampler2D sg_baseColorTexture;
#endif

uniform float sg_pbrMetallicFactor;
uniform float sg_pbrRoughnessFactor;
#ifdef HAS_METALLICROUGHNESS_TEXTURE
uniform int sg_pbrMetallicRoughnessTexCoord;
uniform mat3 sg_pbrMetallicRoughnessTexTransform;
layout(binding=METALLICROUGHNESS_TEXUNIT) uniform sampler2D sg_metallicRoughnessTexture;
#endif

uniform float sg_pbrNormalScale;
uniform int sg_pbrNormalTexCoord;
uniform mat3 sg_pbrNormalTexTransform;
#ifdef HAS_NORMAL_TEXTURE
layout(binding=NORMAL_TEXUNIT) uniform sampler2D sg_normalTexture;
#endif

uniform float sg_pbrOcclusionStrength;
#ifdef HAS_OCCLUSION_TEXTURE
uniform int sg_pbrOcclusionTexCoord;
uniform mat3 sg_pbrOcclusionTexTransform;
layout(binding=OCCLUSION_TEXUNIT) uniform sampler2D sg_occlusionTexture;
#endif

uniform vec3 sg_pbrEmissiveFactor;
#ifdef HAS_EMISSIVE_TEXTURE
uniform int sg_pbrEmissiveTexCoord;
uniform mat3 sg_pbrEmissiveTexTransform;
layout(binding=EMISSIVE_TEXUNIT) uniform sampler2D sg_emissiveTexture;
#endif

#ifdef ALPHA_MODE_MASK
uniform float sg_pbrAlphaCutoff;
#endif

vec4 getBaseColor(in VertexData vertex) {
	vec4 baseColor = sg_pbrBaseColorFactor;
	#ifdef HAS_BASECOLOR_TEXTURE
		vec2 uv = sg_pbrBaseColorTexCoord < 1 ? vertex.texCoord0 : vertex.texCoord1;
		uv = (sg_pbrBaseColorTexTransform * vec3(uv, 1)).xy;
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
		vec2 uv = sg_pbrMetallicRoughnessTexCoord < 1 ? vertex.texCoord0 : vertex.texCoord1;
		uv = (sg_pbrMetallicRoughnessTexTransform * vec3(uv, 1)).xy;
		metallicRoughness *= texture(sg_metallicRoughnessTexture, uv).bg;
	#endif
	return metallicRoughness;
}

float getOcclusion(in VertexData vertex) {
	float occlusion = 1.0;
	#ifdef HAS_OCCLUSION_TEXTURE
		vec2 uv = sg_pbrOcclusionTexCoord < 1 ? vertex.texCoord0 : vertex.texCoord1;
		uv = (sg_pbrOcclusionTexTransform * vec3(uv, 1)).xy;
		occlusion = mix(1.0, texture(sg_occlusionTexture, uv).r, sg_pbrOcclusionStrength);
	#endif
	return occlusion;
}

vec3 getEmissive(in VertexData vertex) {
	vec3 emissive = sg_pbrEmissiveFactor;
	#ifdef HAS_EMISSIVE_TEXTURE
		vec2 uv = sg_pbrEmissiveTexCoord < 1 ? vertex.texCoord0 : vertex.texCoord1;
		uv = (sg_pbrEmissiveTexTransform * vec3(uv, 1)).xy;
		emissive *= texture(sg_emissiveTexture, uv).rgb;
	#endif
	return emissive;
}

vec3 getTangentSpaceNormal(in VertexData vertex) {
	vec3 normal = vec3(0.0,0.0,1.0);
	#ifdef HAS_NORMAL_TEXTURE
		vec2 uv = sg_pbrNormalTexCoord < 1 ? vertex.texCoord0 : vertex.texCoord1;
		uv = (sg_pbrNormalTexTransform * vec3(uv, 1)).xy;
		normal = texture(sg_normalTexture, uv).xyz * 2.0 - vec3(1.0);
		normal *= vec3(sg_pbrNormalScale, sg_pbrNormalScale, 1.0);
		normal = normalize(normal);
	#endif
	return normal;
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
	material.tangentSpaceNormal = getTangentSpaceNormal(vertex);

	const float f0_ior_2 = ((sg_pbrIOR - 1)/(sg_pbrIOR + 1));
	vec3 f0 = vec3(f0_ior_2 * f0_ior_2);
	material.diffuse = mix(material.baseColor.rgb * (vec3(1.0) - f0), vec3(0.0), material.metallic);
	material.specular = mix(f0, material.baseColor.rgb, material.metallic);
	
	float reflectance = max(max(material.specular.r, material.specular.g), material.specular.b);
	material.specular_f90 = vec3(clamp(reflectance * 50.0, 0.0, 1.0));
	return material;
}

SurfaceSample initSurface(in VertexData vertex, in MaterialSample material) {
	SurfaceSample surface;
	surface.position = vertex.position;
	// get normal, tangent, bitangent
	surface.geometricNormal = normalize(vertex.normal);
	surface.shadowCoord = vertex.shadowCoord;
	
	vec2 uv = sg_pbrNormalTexCoord < 1 ? vertex.texCoord0 : vertex.texCoord1;
	uv = (sg_pbrNormalTexTransform * vec3(uv, 1)).xy;
	vec3 uv_dx = dFdx(vec3(uv, 0.0));
	vec3 uv_dy = dFdy(vec3(uv, 0.0));

	vec3 t_ = (uv_dy.t * dFdx(surface.position) - uv_dx.t * dFdy(surface.position)) / (uv_dx.s * uv_dy.t - uv_dy.s * uv_dx.t);
	surface.tangent = normalize(t_ - surface.geometricNormal * dot(surface.geometricNormal, t_));
	surface.bitangent = cross(surface.geometricNormal, surface.tangent);

	// For a back-facing surface, the tangential basis vectors are negated.
	if (gl_FrontFacing == false) {
		surface.tangent *= -1.0;
		surface.bitangent *= -1.0;
		surface.geometricNormal *= -1.0;
	}

	// apply normal map
	surface.normal = surface.geometricNormal;
	surface.normal = mat3(surface.tangent, surface.bitangent, surface.geometricNormal) * material.tangentSpaceNormal;
	surface.view = normalize(vertex.camera - surface.position);
	surface.NdotV = clamp(dot(surface.normal, surface.view), 0.0, 1.0);
	return surface;
}

#endif /* end of include guard: RENDERING_SHADER_MATERIALS_GLSL_ */
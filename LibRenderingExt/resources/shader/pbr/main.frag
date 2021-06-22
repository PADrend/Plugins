#version 450
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
#include "structs.glsl"
#include "material.glsl"
#include "lights.glsl"
#include "ibl.glsl"
#include "shadow.glsl"
#include "tonemapping.glsl"

in VertexInterface {
	vec4 position;
	vec3 normal;
	vec4 color;
	vec2 texCoord0;
	vec2 texCoord1;
	vec4 shadowCoord;
	vec4 camera;
} fsIn;

layout(location=0) out vec4 fragColor;

SurfaceSample initSurface(in VertexData vertex) {
	SurfaceSample surface;
	surface.position = vertex.position;
	// get normal, tangent, bitangent
	surface.geometricNormal = normalize(vertex.normal);
	surface.shadowCoord = vertex.shadowCoord;
	
	vec2 uv = sg_pbrNormalTexCoord < 1 ? vertex.texCoord0 : vertex.texCoord1;
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
	#ifdef HAS_NORMAL_TEXTURE
		surface.normal = texture(sg_normalTexture, uv).xyz * 2.0 - vec3(1.0);
		surface.normal *= vec3(sg_pbrNormalScale, sg_pbrNormalScale, 1.0);
		surface.normal = mat3(surface.tangent, surface.bitangent, surface.geometricNormal) * normalize(surface.normal);
	#endif

	surface.view = normalize(vertex.camera - surface.position);
	surface.NdotV = clamp(dot(surface.normal, surface.view), 0.0, 1.0);
	return surface;
}

void main() {
	VertexData vertex;
	vertex.position = fsIn.position.xyz / fsIn.position.w;
	vertex.normal = fsIn.normal;
	vertex.color = fsIn.color;
	vertex.texCoord0 = fsIn.texCoord0;
	vertex.texCoord1 = fsIn.texCoord1;
	vertex.shadowCoord = fsIn.shadowCoord;
	vertex.camera = fsIn.camera.xyz / fsIn.camera.w;
	SurfaceSample surface = initSurface(vertex);
	MaterialSample material = initMaterial(vertex);

	float shadow = getShadow(surface);
	vec3 diffuse = vec3(0.0);
	vec3 specular = vec3(0.0);

	#ifdef SHADING_MODEL_UNLIT
		diffuse = material.diffuse * material.occlusion * shadow;
		specular = material.specular * material.occlusion * shadow;
		for(int i = 0; i < sg_lightCount; ++i){
			LightSample light = evalLight(surface, sg_LightSource[i]);
			diffuse += material.diffuse * light.ambient.rgb * material.occlusion;
			specular += material.specular * light.ambient.rgb * material.occlusion;
		}
	#else // SHADING_MODEL_UNLIT
		#ifdef USE_IBL
			if(sg_envEnabled) {
				diffuse += getIBLDiffuse(surface, material) * material.occlusion;
				specular += getIBLSpecular(surface, material) * material.occlusion;
			}
		#endif

		for(int i = 0; i < sg_lightCount; ++i){
			LightSample light = evalLight(surface, sg_LightSource[i]);
				
			// ambient light
			#ifdef USE_IBL
				if(!sg_envEnabled) {
					diffuse += material.diffuse * light.ambient.rgb * material.occlusion;
					specular += material.specular * light.ambient.rgb * material.occlusion;
				}
			#else
				diffuse += material.diffuse * light.ambient.rgb * material.occlusion;
				specular += material.specular * light.ambient.rgb * material.occlusion;
			#endif

			// If the light doesn't hit the surface or we are viewing the surface from the back, return
			if (light.NdotL > 0.0 || surface.NdotV > 0.0) {
				// Calculate the diffuse term
				vec3 diffuseBrdf = evalDiffuseBRDF(material.specular, material.specular_f90, material.diffuse, light.VdotH);
				diffuse += diffuseBrdf * light.intensity.rgb * light.NdotL * shadow;

				// Calculate the specular term
				vec3 specularBrdf = evalSpecularBRDF(material.specular, material.specular_f90, material.alphaRoughness, light.VdotH, light.NdotL, surface.NdotV, light.NdotH);
				specular += specularBrdf * light.intensity.rgb * light.NdotL * shadow;
			}
		}
	#endif // SHADING_MODEL_UNLIT

	vec3 color = diffuse + specular + material.emissive;

	#ifdef ALPHA_MODE_MASK
		if(material.baseColor.a < sg_pbrAlphaCutoff) {
			discard;
		}
		material.baseColor.a = 1.0;
	#endif

	fragColor = vec4(computeToneMapping(color), material.baseColor.a);

}
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

void main() {
	VertexData vertex;
	vertex.position = fsIn.position.xyz / fsIn.position.w;
	vertex.normal = fsIn.normal;
	vertex.color = fsIn.color;
	vertex.texCoord0 = fsIn.texCoord0;
	vertex.texCoord1 = fsIn.texCoord1;
	vertex.shadowCoord = fsIn.shadowCoord;
	vertex.camera = fsIn.camera.xyz / fsIn.camera.w;
	MaterialSample material = initMaterial(vertex);
	SurfaceSample surface = initSurface(vertex, material);

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
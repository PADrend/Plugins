
/*
	This file is part of the open source part of the
	Platform for Algorithm Development and Rendering (PADrend).
	Web page: http://www.padrend.de/
	Copyright (C) 2021 Sascha Brandt <sascha@brandt.graphics>
	Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>

	PADrend consists of an open source part and a proprietary part.
	The open source part of PADrend is subject to the terms of the Mozilla
	Public License, v. 2.0. You should have received a copy of the MPL along
	with this library; see the file LICENSE. If not, you can obtain one at
	http://mozilla.org/MPL/2.0/.
*/
#ifndef RENDERING_SHADER_SHADOW_GLSL_
#define RENDERING_SHADER_SHADOW_GLSL_

#ifdef RECEIVE_SHADOW

layout(binding=6) uniform sampler2D sg_shadowTexture;
uniform bool sg_shadowEnabled;

uniform vec2 _shadowSamplingPoints[16] = vec2[16](
	vec2(-0.573297,0.39484),
	vec2(-0.00673674,0.810868),
	vec2(-0.545758,-0.298327),
	vec2(-0.420092,-0.284146),
	vec2(-0.0740884,-0.321956),
	vec2(0.528959,-0.640733),
	vec2(-0.241788,0.662894),
	vec2(-0.167344,0.155723),
	vec2(0.555928,-0.820999),
	vec2(-0.781556,-0.506979),
	vec2(-0.434296,0.0980303),
	vec2(-0.403425,0.265021),
	vec2(-0.721056,-0.106324),
	vec2(-0.366311,-0.174337),
	vec2(0.541415,0.630838),
	vec2(0.0607513,0.528244)
);

float getSingleShadowSample(in sampler2D shadowTexture, in vec3 coord, in vec2 offset, in vec2 size) {
	float depth = texture(shadowTexture, coord.xy + (offset / size)).r;
	return (depth < coord.z) ? 0.0 : 1.0;
}

//! smoot_step implementation
float smooth2(in float edge0,in float edge1,in float x){
	float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
	return t * t * (3.0 - 2.0 * t);
}

//! \see universal.fs
float getShadow(in SurfaceSample surface) {
	if(!sg_shadowEnabled) 
		return 1.0;
	vec3 shadowPersp = surface.shadowCoord.xyz / surface.shadowCoord.w;
	ivec2 shadowTextureSize = textureSize(sg_shadowTexture, 0);
	float sum = 0.0;
	
	sum += getSingleShadowSample(sg_shadowTexture, shadowPersp, vec2(0.0,0.0), shadowTextureSize);
	if(sum==1.0) // sample is lit
		return 1.0;
	
	sum += getSingleShadowSample(sg_shadowTexture, shadowPersp, vec2(0.0,4.0), shadowTextureSize);
	sum += getSingleShadowSample(sg_shadowTexture, shadowPersp, vec2(0.0,-4.0), shadowTextureSize);
	sum += getSingleShadowSample(sg_shadowTexture, shadowPersp, vec2(4.0,0.0), shadowTextureSize);
	sum += getSingleShadowSample(sg_shadowTexture, shadowPersp, vec2(-4.0,0.0), shadowTextureSize);
	
	if(sum<0.01) { // fully inside shadow
		return 0.0;
	}
	// shadow border -> do some sampling to reduce aliasing
//		color.ambient.g = sum/4.0; // debug, show border
	for(int i=0;i<16;++i)
		sum += getSingleShadowSample(sg_shadowTexture, shadowPersp, _shadowSamplingPoints[i]*1.5, shadowTextureSize);

	// adjust the gradient
	sum = smooth2(0.0,11.0,sum);
	return sum;
}

#else

float getShadow(in SurfaceSample surface) {
	return 1.0;
}

#endif

#endif /* end of include guard: RENDERING_SHADER_SHADOW_GLSL_ */
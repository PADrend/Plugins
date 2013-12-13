#version 120

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010-2013 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

uniform bool sg_shadowEnabled;
uniform sampler2D sg_shadowTexture;
uniform int sg_shadowTextureSize;

varying vec4 shadowCoord;

uniform vec2 points[16] = vec2[16](
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

float getSingleShadowSample(in sampler2D shadowTexture, in vec3 coord, in vec2 offset) {
	float depth = texture2D(shadowTexture, coord.xy + (offset / sg_shadowTextureSize)).r;
	return (depth < coord.z) ? 0.2 : 1.0; 
}

void addShadow(inout vec4 color) {
	if(sg_shadowEnabled) {
		vec3 shadowPersp = shadowCoord.xyz / shadowCoord.w;
		float sum = 0.0;
		
		for(int i=0;i<16;++i){
			sum += getSingleShadowSample(sg_shadowTexture, shadowPersp, vec2(points[i].xy));
		}
		color.grb *= sum / 16.0;
	}
}

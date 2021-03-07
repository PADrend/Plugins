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

//#define TONEMAPPING_ENABLED 1

const float GAMMA = 2.2;
const float INV_GAMMA = 1.0 / GAMMA;

uniform float sg_exposure = 1.0;
uniform bool sg_toneMapping = true;

// linear to sRGB approximation
// see http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
vec3 sRGBToLinear(vec3 color) {
  return pow(color, vec3(INV_GAMMA));
}

// sRGB to linear approximation
// see http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
vec3 linearTosRGB(vec3 color) {
  return pow(color, vec3(GAMMA));
}

// ACES tone map
// see http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
vec3 tonemapACESFilm(vec3 color) {
	const float a = 2.51;
	const float b = 0.03;
	const float c = 2.43;
	const float d = 0.59;
	const float e = 0.14;
	return clamp((color*(a*color+b))/(color*(c*color+d)+e), 0.0, 1.0);
}

vec3 computeToneMapping(vec3 color) {
	color *= sg_exposure;

	if(sg_toneMapping) {
		return linearTosRGB(tonemapACESFilm(color));
	} else {
		return linearTosRGB(color);
	}
}

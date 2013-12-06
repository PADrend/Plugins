/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Robert Gmyr
 * Copyright (C) 2011 Sascha Brandt
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/**
 * Vertex Shader of the InfiniteGround plugin.
 */
#define TYPE_MEADOW 0
#define TYPE_SIMPLE_TEXTURE 1
#define TYPE_CHESSBOARD 2
#define TYPE_WATER 3
#define TYPE_WHITE 4

uniform float time;
uniform int type;

varying vec3 worldDir;  // negative normal of vertex of the dome
varying vec4 wave0;
varying vec4 wave1;

void main(void) {
	worldDir = normalize(gl_Vertex.xyz);

	gl_Position = ftransform();

	if(type == TYPE_WATER) {
		// used for type == WATER
		vec2 fTranslation = vec2( mod(time, 100.0) * 0.01, 0.0);
		vec2 fSinTranslation = sin(fTranslation * 20.0) * 0.01;
		wave0.xy = (fTranslation + fSinTranslation) * 3.0;
		wave0.zw = fTranslation * 3.0;
		wave1.yz = fTranslation * 2.0;
		wave1.xw = (fTranslation - fSinTranslation);
	}
}

#version 120

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011-2013 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

uniform bool sg_textureEnabled[8];
uniform sampler2D sg_texture0;
uniform sampler2D sg_texture1;

varying vec2 texCoord0;
varying vec2 texCoord1;

void addTexture(inout vec4 color) {
	if(sg_textureEnabled[0]) 
		color *= texture2D(sg_texture0, texCoord0);
	if(sg_textureEnabled[1]) 
		color *= texture2D(sg_texture1, texCoord1);
}

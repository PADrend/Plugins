#version 130

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011-2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

//uniform layout(binding=0) sampler2D colorTexture;
uniform sampler2D colorTexture;

out vec4 fragColor;

void main(void){

	ivec2 pos = ivec2(gl_FragCoord.xy);
	
	vec4 color = texelFetch(colorTexture, pos, 0);
	
	fragColor = vec4( 0.0, color.g, 0.0, 1.0);
}

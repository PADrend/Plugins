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

/*
	code taken from http://www.geeks3d.com/geexlab/shader_library.php
	minor changes to get it working with MinSG
*/

uniform sampler2D color; // 0
uniform float gamma; // 0.6
uniform float numColors; // 8.0
uniform float  border;
out vec4 fragColor;
uniform int[4] sg_viewport;

vec4 getColor(sampler2D tex, ivec2 pos){
	return texelFetch(tex, pos, 0);
}

vec4 addEffect(in ivec2 pos){
	vec4 c = getColor(color, pos);
	c = pow(c, vec4(gamma));
	c = c * numColors;
	c = floor(c);
	c = c / numColors;
	c = pow(c, vec4(1.0/gamma));
	return c;
}

void main(void){

	ivec2 pos = ivec2(gl_FragCoord.xy)-ivec2(sg_viewport[0],sg_viewport[1]);

	int b = int(float(sg_viewport[2]) * border);

	if(pos.x < b)
		fragColor = addEffect(pos);
	else if(pos.x == b)
		fragColor = vec4(1,0,0,1);
	else
		fragColor = getColor(color, pos);
}
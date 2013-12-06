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

uniform sampler2D color;
uniform float border = 1.0;
uniform int[4] sg_viewport;
out vec4 fragColor;

uniform sampler2D noise;
uniform float sg_time; // seconds
uniform float lumThres; // 0.2
uniform float colorAmp; // 4.0
uniform float maskSize;

vec4 getColor(in sampler2D tex, in ivec2 pos){
	return texelFetch(tex, pos, 0);
}

vec4 addEffect(in ivec2 pos){

	vec2 texCoord = vec2(pos) / vec2(sg_viewport[2], sg_viewport[3]);
    vec2 uv;
    uv.x = 0.4*sin(sg_time*50.0);
    uv.y = 0.4*cos(sg_time*50.0);
    vec3 n = texture2D(noise, (texCoord*3.5) + uv).rgb;
    vec3 c = texture2D(color, texCoord + (n.xy*0.005)).rgb;

    float lum = dot(vec3(0.30, 0.59, 0.11), c);
    if (lum < lumThres)
      c *= colorAmp; 

    vec3 visionColor = vec3(0.1, 0.95, 0.2);
    vec3 finalColor = (c + (n*0.2)) * visionColor;
    
    vec2 xy = vec2(
	    min(float(pos.x), float(sg_viewport[2] - pos.x)),
	    min(float(pos.y), float(sg_viewport[3] - pos.y))
	   	) / maskSize;
	   	
	if(xy.x<1.0)
		finalColor *= xy.x*xy.x;
	if(xy.y<1.0)
		finalColor *= xy.y*xy.y;

	return vec4(finalColor, 1.0);
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
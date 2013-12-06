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

uniform sampler2D color;
uniform float border = 1.0;
uniform int[4] sg_viewport;
out vec4 fragColor;

uniform float sg_time;
uniform sampler2D numbers;
const int numberheight = 32;

vec4 getColor(in sampler2D tex, in ivec2 pos){
	return texelFetch(tex, pos, 0);
}

vec4 getNumberColor(in int n, in vec2 uv){
	return texture2D(numbers, uv * vec2(1.0/12.0, 1) +vec2(n/12.0,0) );
}

vec4 addEffect(in ivec2 pos){

	int x = pos.x/numberheight;
	if(x <= 8 && pos.y < numberheight){
	
		int[9] digits;
		
		float t = sg_time/60;
		int m = int(floor(t));
		digits[0] = m/10;
		digits[1] = m-digits[0]*10;
		digits[2] = 10; // :
		
		t = (t-floor(t))*60;
		int s = int(floor(t));
		digits[3] = s/10;
		digits[4] = s-digits[3]*10;
		digits[5] = 11; // .
		
		t = (t-floor(t))*10;
		digits[6] = int(floor(t));
		t = (t-floor(t))*10;
		digits[7] = int(floor(t));
		t = (t-floor(t))*10;
		digits[8] = int(floor(t));
		
		int myDigit = digits[pos.x/numberheight];
		ivec2 myPos = pos - ivec2(pos.x/numberheight*numberheight, 0);
		
	
		int s1 = s/10;
		int s2 = s-s1*10;

		return getNumberColor( myDigit, vec2(myPos)/float(numberheight) );
	}
	return getColor(color, pos);
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
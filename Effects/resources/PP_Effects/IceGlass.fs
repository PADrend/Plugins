#version 130

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
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
uniform int PixelX;
uniform int PixelY;
uniform float Freq;
uniform float sg_time;

vec4 getColor(in sampler2D tex, in ivec2 pos){
	return texelFetch(tex, max(ivec2(0,0),min(pos,ivec2(sg_viewport[2], sg_viewport[3])-1)), 0);
}

vec4 spline(float x, vec4 c1, vec4 c2, vec4 c3, vec4 c4, vec4 c5, vec4 c6, vec4 c7, vec4 c8, vec4 c9)
{
  float w1, w2, w3, w4, w5, w6, w7, w8, w9;
  w1 = 0.0;
  w2 = 0.0;
  w3 = 0.0;
  w4 = 0.0;
  w5 = 0.0;
  w6 = 0.0;
  w7 = 0.0;
  w8 = 0.0;
  w9 = 0.0;
  float tmp = x * 8.0;
  if (tmp<=1.0) {
    w1 = 1.0 - tmp;
    w2 = tmp;
  }
  else if (tmp<=2.0) {
    tmp = tmp - 1.0;
    w2 = 1.0 - tmp;
    w3 = tmp;
  }
  else if (tmp<=3.0) {
    tmp = tmp - 2.0;
    w3 = 1.0-tmp;
    w4 = tmp;
  }
  else if (tmp<=4.0) {
    tmp = tmp - 3.0;
    w4 = 1.0-tmp;
    w5 = tmp;
  }
  else if (tmp<=5.0) {
    tmp = tmp - 4.0;
    w5 = 1.0-tmp;
    w6 = tmp;
  }
  else if (tmp<=6.0) {
    tmp = tmp - 5.0;
    w6 = 1.0-tmp;
    w7 = tmp;
  }
  else if (tmp<=7.0) {
    tmp = tmp - 6.0;
    w7 = 1.0 - tmp;
    w8 = tmp;
  }
  else
  {
    //tmp = saturate(tmp - 7.0);
    // http://www.ozone3d.net/blogs/lab/20080709/saturate-function-in-glsl/
    tmp = clamp(tmp - 7.0, 0.0, 1.0);
    w8 = 1.0-tmp;
    w9 = tmp;
  }
  return w1*c1 + w2*c2 + w3*c3 + w4*c4 + w5*c5 + w6*c6 + w7*c7 + w8*c8 + w9*c9;
}

float getNoise(in ivec2 p){ 
	vec2 nv = texture2D(noise, Freq * p/vec2(sg_viewport[2],sg_viewport[3])).xy;
	float n = nv.x + sg_time * nv.y * 0.01;
	return mod(n, 0.111111) / 0.111111;
}

vec4 addEffect(in ivec2 pos){

	ivec2 ox = ivec2(PixelX, 0);
	ivec2 oy = ivec2(0, PixelY);

	vec4 C00 = getColor( color, pos - ox - oy);
	vec4 C01 = getColor( color, pos      - oy);
	vec4 C02 = getColor( color, pos + ox - oy);

	vec4 C10 = getColor( color, pos - ox     );
	vec4 C11 = getColor( color, pos          );
	vec4 C12 = getColor( color, pos + ox     );

	vec4 C20 = getColor( color, pos - ox + oy);
	vec4 C21 = getColor( color, pos      + oy);
	vec4 C22 = getColor( color, pos + ox + oy);

	float n = getNoise(pos);

	vec4 sp = spline(n,C00,C01,C02,C10,C11,C12,C20,C21,C22);

	return vec4(sp.rgb, 1.0);
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
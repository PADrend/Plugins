#version 130

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

// ------------------
// vs
#ifdef SG_VERTEX_SHADER

void main(void)
{
  gl_Position = ftransform();
  gl_TexCoord[0] = gl_MultiTexCoord0;
}
#endif
// ------------------
// fs
#ifdef SG_FRAGMENT_SHADER
uniform sampler2D TUnit_1; // 0

void main(){ 
  vec2 uv = gl_TexCoord[0].st;
  vec3 color = textureLodOffset(TUnit_1, uv, 0.0, ivec2(0,0)).rgb;
  float luma = sqrt(dot(color, vec3(0.299, 0.587, 0.114)));
//  float luma = dot(color, vec3(0.299, 0.587, 0.114));
  gl_FragColor = vec4(color,luma);
//  gl_FragColor = vec4(luma);
}
// ------------------
#endif
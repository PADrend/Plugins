#version 130

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

uniform float pixelSizeY,pixelSizeX; 
varying vec4 posPos;

// ------------------
// vs
#ifdef SG_VERTEX_SHADER

uniform float FXAA_SUBPIX_SHIFT = 1.0/4.0;


void main(void)
{
  gl_Position = ftransform();
  gl_TexCoord[0] = gl_MultiTexCoord0;
  vec2 rcpFrame = vec2(pixelSizeX, pixelSizeY);
  posPos.xy = gl_MultiTexCoord0.xy;
  posPos.zw = gl_MultiTexCoord0.xy - 
                  (rcpFrame * (0.5 + FXAA_SUBPIX_SHIFT));
}
#endif
// ------------------
// fs
#ifdef SG_FRAGMENT_SHADER

//! \see Fxaa3_8.sfn
vec4 FxaaPixelShader(
    // {xy} = center of pixel
    vec2 pos,
    // {xyzw} = not used on FXAA3 Quality
    vec4 posPos,       
    // {rgb_} = color in linear or perceptual color space
    // {___a} = luma in perceptual color space (not linear) 
    sampler2D tex,
    // This must be from a constant/uniform.
    // {x_} = 1.0/screenWidthInPixels
    // {_y} = 1.0/screenHeightInPixels
    vec2 rcpFrame,
    // {xyzw} = not used on FXAA3 Quality
    vec4 rcpFrameOpt 
);



uniform sampler2D TUnit_1; // 0
//	vec3 c = textureLodOffset(t, p, 0.0, o);
//	return  sqrt(dot(color.rgb, vec3(0.299, 0.587, 0.114))); // compute luma
void main() 
{ 
  vec2 uv = posPos.xy;
  vec4 color = textureLodOffset(TUnit_1, uv, 0.0, ivec2(0,0));
  color = FxaaPixelShader(uv,vec4(0),TUnit_1,vec2(pixelSizeX, pixelSizeY),vec4(0));
  gl_FragColor = color;
}


#endif
// ------------------
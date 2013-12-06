/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*
 * DynamicSky.fs
 * 2009-11 CJ
 * Inspired by skyFP.glsl (based on the work of Michael Horsch)
 * \see http://www.bonzaisoftware.com/volsmoke.html
 */

uniform float cloudTime;


varying vec3 vpos;
varying vec2 texCoord_1, texCoord_2, texCoord_3, skyPos_ws;

const float scale = 0.005;

void  main(void){

    vec3 normal = - normalize(gl_Vertex.xyz);
    vec2 texCoords = (normal*(10.0 / normal.y)).xz*scale;

    skyPos_ws = texCoords;
    texCoord_1 = texCoords * 2.0 + cloudTime * vec2( 0.5, 1.0 );
    texCoord_2 = texCoords * 2.5 + cloudTime * vec2( -0.9, 1.2 );
    texCoord_3 = texCoords * 8.1 + cloudTime * vec2( 1.6, 1.7 );

    vpos = gl_Vertex.xyz;

    gl_Position = ftransform();
}

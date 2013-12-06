/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*! PP_DoF - Postprocessing depth of field & blooming Shader
    2009-11-23 Claudius
 */

uniform sampler2D TUnit_1;      //!< Original Image
uniform sampler2D TUnit_Blur;   //!< Blurred Image
uniform sampler2D TUnit_Depth;  //!< Depth values

const float zNear=0.1;          //!< Camera near plane
const float zFar=5000.0;        //!< Camera far plane

/*! The upper envelope of the blur-function is defined by two functions:
    f1(z) :=  c1 + z*m1;
    f2(z) :=  c2 + z*m2;
    blur(z) := clamp( max( f1(z), f2(z) ) , 0.0 ,1.0)   */
uniform float c1;//=0.0
uniform float m1;//=-0.3;
uniform float c2;//=-20.0;
uniform float m2;//=0.1;

uniform float bloomingLimit;

void main(){
    float x = gl_TexCoord[0].s;
    float y = gl_TexCoord[0].t;

//    float d=clamp(pow(float(texture2D(TUnit_Depth,vec2(x,y))),256.0),0.0,1.0); // far blur
//    float d=clamp(0.1*(1.0/float(texture2D(TUnit_Depth,vec2(x,y)))),0.0,1.0); // linear??

    // calculate z value from depth
    vec4 depthSample = texture2D(TUnit_Depth, vec2(x,y));
    float depth = depthSample.x * 255.0 / 256.0 +
                  depthSample.y * 255.0 / 65536.0 +
                  depthSample.z * 255.0 / 16777216.0;
    float z = (zNear * zFar) / (zFar - depth * (zFar - zNear));

    // calculate DoF
    float blur =clamp(max( c1+z*m1 , c2+z*m2),0.0,1.0);

    // prevent sky bleeding
    if(z>=zFar*0.99) blur=0.0;

//    blur=0.0;

    // ---
    vec3 colorOriginal =  vec3(texture2D(TUnit_1,vec2(x,y)));
    vec3 colorBlurred =  vec3(texture2D(TUnit_Blur,vec2(x,y)));

    // add blooming
    float energyBlurred = colorBlurred.x+colorBlurred.y+colorBlurred.z;
    float energyOriginal = colorOriginal.x+colorOriginal.y+colorOriginal.z;
    if(energyBlurred > bloomingLimit && energyBlurred > energyOriginal )
            blur=clamp(blur+(5.0*(energyBlurred-bloomingLimit)),0.0,1.0);


    vec3 c = colorOriginal * (1.0-blur) + colorBlurred*blur;
    gl_FragColor = vec4( c,1);
}

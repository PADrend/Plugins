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
/*! PP_Cartoon - postprocessing cartoon shader
    2009-11-27 Claudius
 */

uniform sampler2D TUnit_1;  //!< source image
uniform sampler2D TDepth;  //!< source depth
uniform float pixelSizeX;    //!< 1.0/horizonal or vertical resolution
uniform float pixelSizeY;    //!< 1.0/horizonal or vertical resolution
const float zNear=0.1;
const float zFar=5000.0;

vec3 getColor(float x,float y,float d){
    return vec3(texture2D(TUnit_1,vec2(x,y))) * d;
}
float getDepth(float x,float y){
        vec4 depthSample = texture2D(TDepth, vec2(x,y));
    float depth = depthSample.x * 255.0 / 256.0 +
                  depthSample.y * 255.0 / 65536.0 +
                  depthSample.z * 255.0 / 16777216.0;
    float z = (zNear * zFar) / (zFar - depth * (zFar - zNear));
    return z;
}

void main(){
    float x = gl_TexCoord[0].s;
    float y = gl_TexCoord[0].t;
    vec3 c=texture2D(TUnit_1,vec2(x,y)).xyz;
    float cL=length(c);

    float f=1.0;

    if(cL<0.2){
        f=0.7;
    } else if(cL<0.4){
        f=0.9;
    } else if(cL<0.5){
        f=0.95;
    }
    float r=1.0,g=1.0,b=1.0;
// // Add some color
//    if(c.x>c.y*1.3 )
//        g*=0.8;
//    if(c.x>c.z*1.3 )
//        b*=0.8;
//    if(c.y>c.x*1.3 )
//        r*=0.8;
//    if(c.y>c.z*1.3 )
//        b*=0.8;
//    if(c.z>c.x*1.3 )
//        r*=0.8;
//    if(c.z>c.y*1.3 )
//        g*=0.8;

    float z=getDepth(x,y)*1.05;

    if(z<getDepth(x+pixelSizeX,y)){
        f*=0.3;
    }else if(z<getDepth(x+pixelSizeX*2.0,y)){
        f*=0.8;
    }
    if(z<getDepth(x-pixelSizeX,y)){
        f*=0.3;
    }else if(z<getDepth(x-pixelSizeX*2.0,y)){
        f*=0.8;
    }
    if(z<getDepth(x,y-pixelSizeY)){
        f*=0.3;
    }else if(z<getDepth(x,y-pixelSizeY*2.0)){
        f*=0.8;
    }
    if(z<getDepth(x,y+pixelSizeY)){
        f*=0.3;
    }else if(z<getDepth(x,y+pixelSizeY*2.0)){
        f*=0.8;
    }

    c=vec3(r,g,b)*f;

//    gl_FragColor = vec4( c.y/16.0,0.0,0.0,1);
//    gl_FragColor = vec4( texture2D(TUnit_1,vec2(x,y))*0.5 ,1);
//    gl_FragColor = vec4(c,0.0);
	gl_FragColor = vec4( texture2D(TUnit_1,vec2(x,y)).rgb*c ,1.0);
}

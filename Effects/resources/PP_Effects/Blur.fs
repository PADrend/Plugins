#version 330
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
/*! PP_Blur - 2-pass postprocessing blur shader
    2009-11-23 Claudius
 */

uniform sampler2D TUnit_1;  //!< source image

uniform int range;          //!< size of the filter cernel
uniform float pixelSize;    //!< 1.0/horizonal or vertical resolution
uniform int orientation;    //!< 0 for horizontal, 1 for vertical pass

in vec2 texCoord;
out vec4 fragColor;

vec3 getColor(float x,float y,float d){
    return vec3(texture2D(TUnit_1,vec2(x,y))) * d;
}

void main(){
    float x = texCoord.s;
    float y = texCoord.t;

    float weight = 16.0;
    vec3 c=getColor(x,y,weight);
    float offset = 0.0;
    if(orientation == 0){
        for(int i=1;i<range;i++,offset+=pixelSize){
            float w=float(range-i/2);
            if(x+offset<1.0){
                weight+=w;
                c+=getColor(x+offset,y,w);
            }
            if(x-offset>0.0){
                weight+=w;
                c+=getColor(x-offset,y,w);
            }
        }
    } else {
        for(int i=1;i<range;i++,offset+=pixelSize){
            float w=float(range-i/2);
            if(y+offset<1.0){
                weight+=w;
                c+=getColor(x,y+offset,w);
            }
            if(y-offset>0.0){
                weight+=w;
                c+=getColor(x,y-offset,w);
            }
        }
    }
//    gl_FragColor = vec4( c.y/16.0,0.0,0.0,1);
    fragColor = vec4( c/weight ,1);
}

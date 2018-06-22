#version 330

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2018 Sascha Brandt <sascha@brandt.graphics>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*! PP_SSAO 2 - postprocessing screen space abient occlusion shader
	\note inspired by an article on ssao by iñigo quilez from 2007
			(http://www.iquilezles.org/www/articles/ssao/ssao.htm)
    2011-08 Claudius
    2013-03 Claudius (Version 2.0 - complete re-design)
 */

uniform sampler2D TUnit_1;  //!< source image
uniform sampler2D TDepth;  //!< source depth
uniform float pixelSizeX = 1.0/1024.0;    //!< 1.0/horizonal or vertical resolution
uniform float pixelSizeY = 1.0/1024.0;    //!< 1.0/horizonal or vertical resolution

uniform mat4 inverseProjectionMatrix;
uniform mat4 projectionMatrix;

uniform float debugBlend = 0.0;
uniform float intensityFactor = 2.0;
uniform float intensityExponent = 1.0;

uniform float debugBorder = 0.0;
uniform float maxBrightness = 1.0;
uniform float radiusIncrease = 1.7;
uniform float initialRadius = 4;
uniform int numDirections = 5;
uniform int numSteps = 5;

uniform float hazeFar_cs = -1.0;
uniform float hazeNear_cs = -1.0;
uniform vec3 hazeColor;

/*! if useNoise is defined, the sampled points are perturbed by reflecting them by an pseudo randomized
	plane. */
uniform bool useNoise = false;

in vec2 texCoord;

out vec4 fragColor; 

vec3 getEyePos(in vec2 camPos) {
	vec4 eyePos = inverseProjectionMatrix * vec4(camPos, texture2D(TDepth, camPos).r, 1.0);
	eyePos /= eyePos.w; 
	return eyePos.xyz;
}

vec3 camToEye(in vec2 camPos,float depth) {
	vec4 eyePos = inverseProjectionMatrix * vec4(camPos, depth, 1.0);
	eyePos /= eyePos.w; 
	return eyePos.xyz;
}

float calcLuma(in vec3 color) {
	return sqrt(dot(color, vec3(0.299, 0.587, 0.114))); // needed for fxaa
}

void main() {
  vec2 pos_cs = texCoord;
  vec4 originalColor = texture2D(TUnit_1,pos_cs);
  
  vec3 eyeSpacePos;
    	
	{ // background? --> skip calculations for speedup
		float depth = texture2D(TDepth, pos_cs).r;
		if(depth>0.9999999){
			fragColor = vec4(originalColor.rgb,calcLuma(originalColor.rgb)); // luma needed for fxaa
			return; 
		}
		eyeSpacePos = camToEye(pos_cs,depth); // don't use getEyePos as we already have the depth value.

		if(eyeSpacePos.z<-100000.0 || pos_cs.x<debugBorder){
			if(hazeFar_cs!=hazeNear_cs){
				originalColor.rgb = mix(originalColor.rgb,hazeColor,(clamp(-eyeSpacePos.z, hazeNear_cs,hazeFar_cs)-hazeNear_cs) / (hazeFar_cs-hazeNear_cs) );
			}

			fragColor = vec4(originalColor.rgb,calcLuma(originalColor.rgb)); // luma needed for fxaa
			return;
		}
	}
	float freeVolume = 0.0;

	{ // calcualte free volume (= 1 - occlusion)
		float sum =0.0;
		float cummulatedOcc = 0.0;
		float PI = 3.14159265358979323846264;
		float stepSize = 2.0*PI / numDirections;
		float distanceMod = 1.0 / (1.0-eyeSpacePos.z);
		for(float i=0;i<2*PI;i+=stepSize){
			vec2 ray_cs = vec2(cos(i)*pixelSizeX , sin(i)*pixelSizeY);
			float lastAng = -1.0;

			vec2 rayOffset_cs = pos_cs + initialRadius*ray_cs;

			for(float j=0;j<numSteps;++j){
				vec2 samplePos_cs = rayOffset_cs + ray_cs;
				// clip
				if( samplePos_cs.x<0.0 || samplePos_cs.x>=1.0 || samplePos_cs.y<0.0 || samplePos_cs.y>=1.0 ){
					break;
				}

				vec3 intersection_es = getEyePos(rayOffset_cs + ray_cs);
				vec3 dir = intersection_es-eyeSpacePos;
				
				float ang = (1.0-dot(normalize(dir),vec3(0,0,-1.0)))*0.5;

				if(ang<lastAng){ // once a closer point is found, let it influence the current point
					ang = (ang+lastAng) * 0.5;
				}else{
					lastAng = ang;
				}

				cummulatedOcc += ang/(1.0+length(dir)*distanceMod) * 1.0;
				sum+=1.0;
				ray_cs *=radiusIncrease;
			}
		}
		freeVolume = 1.0 - cummulatedOcc/sum;
	}

	{ // calculate final color
		float f =  pow(freeVolume* intensityFactor,intensityExponent); 
		vec3 color = originalColor.xyz;
		
		color = mix( color, vec3(1.0,1.0,1.0),debugBlend);
		
		// reduce brightness in YUV-space
		float cY = 0.299 * color.r + 0.587*color.g + 0.114*color.b;
		float cU = (color.b-cY) * 0.493;
		float cV = (color.r-cY) * 0.877;
		cY *= min(f,maxBrightness);	
		color = vec3(cY+cV/0.877, cY-0.39466*cU-0.5806*cV, cY+cU/0.493);
		
		// reduce color in RGB-space (not so good...)
	//		baseColor *= min(blocking/counter + intensityOffset,1.0);	
		
		if(hazeFar_cs!=hazeNear_cs){
			color.rgb = mix(color.rgb,hazeColor,(clamp(-eyeSpacePos.z, hazeNear_cs,hazeFar_cs)-hazeNear_cs) / (hazeFar_cs-hazeNear_cs) );
		}		 
		
		fragColor = vec4(color.rgb,calcLuma(color.rgb)); // luma needed for fxaa
	}
	return;
}

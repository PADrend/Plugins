#version 120
#extension GL_EXT_gpu_shader4 : enable

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
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
 */

uniform sampler2D TUnit_1;  //!< source image
uniform sampler2D TDepth;  //!< source depth
uniform float pixelSizeX = 1.0/1024.0;    //!< 1.0/horizonal or vertical resolution
uniform float pixelSizeY = 1.0/1024.0;    //!< 1.0/horizonal or vertical resolution

uniform mat4 inverseProjectionMatrix;
uniform mat4 projectionMatrix;

uniform float samplingRadius = 0.008;
uniform float intensityOffset = 0.1;
uniform float debugBlend = 0.0;
uniform float intensityFactor = 1.0;
uniform float minPlaneDistance = 0.2;

uniform float debugBorder = 0.0;
uniform float maxBrightness = 1.0;
uniform float radiusIncrease = 1.05;
uniform float distancePow = 1.0;
uniform int numSamples = 16;

/*! if useNoise is defined, the sampled points are perturbed by reflecting them by an pseudo randomized
	plane. */
uniform bool useNoise = false;

//out vec4 fragColor; // version 130

// \note when using a const array instead of an uniform, the rendering process becomes verry!!! slow. This
// is most likely a NVIDIA driver issue.
uniform vec3 points[16] = vec3[16](
	vec3(-0.25444,-0.0589858,0.697345),
	vec3(0.487843,0.661275,0.427246),
	vec3(-0.298106,0.127501,0.59822),
	vec3(-0.0676845,0.801723,-0.021715),
	vec3(-0.311076,0.039659,0.377949),
	vec3(-0.401293,-0.822986,-0.360809),
	vec3(-0.382384,-0.0614385,0.301561),
	vec3(0.0197475,-0.770772,0.0465037),
	vec3(0.12617,0.357898,0.0743235),
	vec3(0.472344,0.503945,-0.0725119),
	vec3(-0.354711,-0.269181,0.35097),
	vec3(0.272704,-0.29374,0.858466),
	vec3(-0.142453,-0.363622,-0.382014),
	vec3(0.192463,0.380795,-0.633324),
	vec3(-0.45662,0.477546,-0.391975),
	vec3(-0.2087,-0.172308,0.532069)
);

vec3 getEyePos(float x,float y){
	float depth = texture2D(TDepth, vec2(x,y)).r;
	vec4 eyePos = inverseProjectionMatrix * vec4(x,y, depth, 1.0);
	eyePos /= eyePos.w; 
	return eyePos.xyz;
}

vec3 camToEye(float x,float y,float depth){
	vec4 eyePos = inverseProjectionMatrix * vec4(x,y, depth, 1.0);
	eyePos /= eyePos.w; 
	return eyePos.xyz;
}

void main(){
    float x = gl_TexCoord[0].s;
    float y = gl_TexCoord[0].t;
    
    vec3 eyeSpacePos;
    	
	{ // background? --> skip calculations for speedup
		float depth = texture2D(TDepth, vec2(x,y)).r;
		if(depth>0.99999){
			gl_FragColor = texture2D(TUnit_1,vec2(x,y));
			return; 
		}
		eyeSpacePos = camToEye(x,y,depth); // don't use getEyePos as we already have the depth value.
	}
	
	float r = samplingRadius * pow(-eyeSpacePos.z, distancePow); // increase radius in the distance
		
	vec3 noise;
	if(useNoise){
		int h = int(x/pixelSizeX + y*5000/pixelSizeY + mod(eyeSpacePos.z*10000.0,0.7) );
		h ^= (((h) * 1234393) % 0xffffff);
		h ^= (((h) * 1234393) % 0xffffff);
		float f1 = float(h%1024-512);
		
		h ^= (((h) * 1234393) % 0xffffff);
		float f2 = float(h%1024-512);

		h ^= (((h) * 1234393) % 0xffffff);
		float f3 = float(h%1024-512);
		
		noise = normalize(vec3( f1,f2,f3 ));
	}
	
	
	// approximate normal
	vec3 approxEsNormal;
	{
		vec3 p1 = getEyePos(x+pixelSizeX , y);
		vec3 p2 = getEyePos(x , y-pixelSizeY);
		vec3 p3 = getEyePos(x-pixelSizeX , y);
		
		vec3 esNormal1 = normalize(cross(p2-eyeSpacePos,p1-eyeSpacePos));
		vec3 esNormal2 = normalize(cross(p3-eyeSpacePos,p2-eyeSpacePos));
		approxEsNormal = normalize((esNormal1+esNormal2));
	}
	
	float blocking = 0.0;
	float counter = 0.0;
	for( int i=0; i<64; i++ )   {
		if(i>=numSamples)
			break;
	
		vec3 point = points[i%16];
		
		if(i>16){
			point = reflect(point,normalize(vec3( float((i*100)%17-8) ,float((i*1170)%17-8),float((i*769)%17-8))));
			r*=radiusIncrease; // gradually increase the sampling radius 
		}
		
		if(useNoise)
			point = reflect(point,noise);
		
		
		float distanceToNormalPlane = dot(point,approxEsNormal);
		// if the sampled point is too close to the normal plane, skip it as it likely to produce artefacts due to rounding errors in the depth buffer.
		if(abs(distanceToNormalPlane)<minPlaneDistance){
			continue;
		// if the sampled point is below the normal plane reflect it at the normal plane.
		} else if(distanceToNormalPlane<0.0)
			point = reflect(point,approxEsNormal);
			
        vec3 eyeSpaceSamplePoint = eyeSpacePos + r * point;
		
		// project back to screenSpace
        vec4 screenSpaceSamplePoint = projectionMatrix * vec4(eyeSpaceSamplePoint,1.0);
		screenSpaceSamplePoint/=screenSpaceSamplePoint.w;

		// clip
		if( screenSpaceSamplePoint.x<0.0 || screenSpaceSamplePoint.x>=1.0 || 
				screenSpaceSamplePoint.y<0.0 || screenSpaceSamplePoint.y>=1.0 ){
			continue;
		}
	
		counter += 1.0;
		float zd = 0.0;
		
		float diff = getEyePos(screenSpaceSamplePoint.x,screenSpaceSamplePoint.y).z - eyeSpaceSamplePoint.z ;
	
		if(diff>0.00){
			zd = 5.0 / (diff*diff);
		}
		blocking += 1.0/(1.0+ zd*zd );

	}
	blocking *= intensityFactor; //pow(blocking,intensityFactor);

    vec3 baseColor = texture2D(TUnit_1,vec2(x,y)).xyz;
    if(x>=debugBorder){
		baseColor = mix( baseColor, vec3(1.0,1.0,1.0),debugBlend);
		
		// reduce brightness in YUV-space
		float cY = 0.299 * baseColor.r + 0.587*baseColor.g + 0.114*baseColor.b;
		float cU = (baseColor.b-cY) * 0.493;
		float cV = (baseColor.r-cY) * 0.877;
		cY *= min(blocking/counter + intensityOffset,maxBrightness);	
		baseColor = vec3(cY+cV/0.877, cY-0.39466*cU-0.5806*cV, cY+cU/0.493);
		
		// reduce color in RGB-space (not so good...)
//		baseColor *= min(blocking/counter + intensityOffset,1.0);	
    }

    gl_FragColor = vec4(baseColor,1.0);
}

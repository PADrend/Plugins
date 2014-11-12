#version 120
/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Lukas Kopecki
 * Copyright (C) 2010 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2010 Robert Gmyr
 * Copyright (C) 2011-2012 Sascha Brandt
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/**
 * Fragment Shader of the InfiniteGround plugin.
 */

/*
		 viewerPos
         |
	|    X     |
	\   /     / --- dome
     \ /     /
      /-----/
     /dir       ^ normal
    /           |             virtual ground
  -X----------------------------
   |                        | groundLevel
  groundIntersection        --(0)

*/


#define TYPE_MEADOW 0
#define TYPE_SIMPLE_TEXTURE 1
#define TYPE_CHESSBOARD 2
#define TYPE_WATER 3
#define TYPE_WHITE 4
#define TYPE_GRID 5

const float noiseScale = 50.0;  // scalefactor of noise texture for alpha blending

uniform sampler2D noise;

uniform sampler2D texture_1;
uniform sampler2D texture_2;

uniform int type;
uniform float scale;
uniform vec3 viewerPos;
uniform mat3 worldRot;
uniform mat4 sg_matrix_worldToCamera;
uniform float groundLevel;  // y-coordinate of the ground

uniform bool useHaze;
uniform float hazeNear;
uniform float hazeFar;
uniform vec3 hazeColor;

uniform vec3 sunPosition;
uniform vec3 sunAmbient;
uniform vec3 sunDiffuse;

// used for type == TYPE_WATER
uniform float reflection;
uniform float refraction;
uniform float screenRatio;

varying vec3 worldDir;  // interpolated negative normal of vertex of the dome

// used for type == TYPE_WATER
varying vec4 wave0;
varying vec4 wave1;

// ---------------------------------------------------
// default uniforms

uniform int sg_viewport[4];

// ----------------------------------------------------------------
// general helper

vec3 worldPosToCamPos(const in vec3 worldPos) {
	vec4 v = sg_matrix_worldToCamera * vec4(worldRot*worldPos, 1.0);
	return v.xyz / v.w;
}
float sunGlow(const in vec3 worldLightDir) {
	float sunDistance = max(0.0, dot(vec3(worldLightDir.x, -worldLightDir.y, -worldLightDir.z), worldDir));
//	if(sunDistance < 0.9)
//		return 0;
	float hazeFactor =  clamp( pow(1.0 + worldDir.y, 6.0), 0.0, 1.0) ; //
	float sunGlowExponent =  1024.0 * (1.0 - hazeFactor * 0.95) ;

	return  pow( sunDistance, sunGlowExponent ) * pow(1.0 - worldDir.y, 80.0);
}

// ----------------------------------------------------------------
// Meadow
void calculateMeadow(const in vec2 groundPos, out vec3 color) {
	float f0 = texture2D(noise, (groundPos * 4.537) / noiseScale).x;
	float f1 = texture2D(noise, groundPos / noiseScale).x;
	float f2 = texture2D(noise, (groundPos.yx * 0.537) / noiseScale).x;
	float f = clamp( pow( (f1 + f2 + f0) * 0.5 , 10.0) , 0.0, 1.0);
	float disortion = 1.0; // f

	vec3 c1 = vec3(( texture2D(texture_1,
							   vec2( groundPos) + vec2( (f2 * 1.42) + f, f2 * 1.4431 - f ) * disortion) +
					 texture2D(texture_1,
							   vec2( groundPos.y * 0.723, groundPos.x * 0.623) + vec2( f1 * 4.271, f1 * 4.3331) * disortion ))) * 0.5 ;

	float brightness = (c1.x + c1.y + c1.z) * 0.3333;
	vec3 c2 = vec3( (brightness + c1.x) * 0.5 , (brightness + c1.y) * 0.45 , (brightness + c1.z) * 0.43 );

	color = mix(c1, c2, f);

	// add some dark borders around the darker areas
	if( (0.7 - f) < 0.2)
		color *= 0.8 + abs(f - 0.7);
}

// ----------------------------------------------------------------
// Chessboard
void calculateChessboard(const in vec2 groundPos, out vec3 color) {
	bvec2 offsetVec = lessThan(fract(groundPos), vec2(0.5));
	color = (offsetVec.x ^^ offsetVec.y)  ? vec3(0.0, 0.0, 0.0) : vec3(1.0, 1.0, 1.0);
}

// ----------------------------------------------------------------
// Water
float fresnel(float NdotL, float fresnelBias, float fresnelPow) {
	float facing = (1.0 - NdotL);
	return max(fresnelBias + (1.0 - fresnelBias) * pow(facing, fresnelPow), 0.0);
}
void calculateWater(const in vec2 groundPos, const in vec3 worldLightDir,  out vec3 groundPos_cam,
					out vec3 color, out vec3 worldNormal , const in vec3 worldGroundIntersection) {

	vec3 f0 = texture2D(texture_1, (groundPos * 2.0) / noiseScale + wave0.xy).rgb;
	vec3 f1 = texture2D(texture_1, (groundPos * 4.0) / noiseScale + wave0.zw).rgb;
	vec3 f2 = texture2D(texture_1, (groundPos * 6.0) / noiseScale + wave1.xy).rgb;
	vec3 f3 = texture2D(texture_1, (groundPos * 8.0) / noiseScale + wave1.zw).rgb;

	worldNormal = normalize(2.0 * (f0 + f1 + f2 + f3) - 4.0);
	
	vec2 mirrorCoord = vec2( gl_FragCoord.x / float(sg_viewport[2]) , 1.0-gl_FragCoord.y / float(sg_viewport[3]) );

	vec3 refl = texture2D(texture_2, mirrorCoord + (worldNormal.xy * refraction)).rgb;
	float NdotL = max(dot(worldLightDir, worldNormal), 0.0);
	float fres = fresnel(NdotL, 0.5, 5.0);
	vec3 waterColor = vec3(0, 0.115, 0.15);
	vec3 waterColor2 = hazeColor / max(length(hazeColor),1.0) ; // use haze, but reduce too bright colors
	color = ((refl * reflection) + ( waterColor2 *(1.0-reflection))  )* fres + waterColor;
	
	// add some height (modified depth values) to the waves
	groundPos_cam = worldPosToCamPos(worldGroundIntersection + vec3(0.0,1.0,0.0)*( f0.r*0.2 +f1.g*0.15 +f2.b*0.1+f3.r*0.05 ));
}
// ----------------------------------------------------------------
float calcFragmentDepth(const in vec3 groundPos_cam){
	vec4 windowCoord = gl_ProjectionMatrix * vec4(groundPos_cam, 1.0);
	// Clamp here to prevent clipping.
	return  clamp(0.5 + 0.5 * windowCoord.z / windowCoord.w, 0.0, 0.99999);
}


// -------------------------------------------------------------------
void main(void) {

	// viewer under ground -> no ground visible
	if(viewerPos.y < groundLevel) {
		discard;
	}

	vec3 nWorldDir = normalize(worldDir);

	// distance from the viewer to the groundIntersection
	// \note The heigth above ground is (viewerPos.y - groundLevel).
	// \note The max(...) is used to prevent artifacts near the horizon where nWorldDir.y becomes very small.
	float worldDistance = (viewerPos.y - groundLevel) / max(nWorldDir.y, 0.00001);

	// ground intersection
	vec3 worldGroundIntersection = viewerPos - worldDistance * nWorldDir;
	vec3 groundPos_cam = worldPosToCamPos(worldGroundIntersection);
	gl_FragData[1] = vec4( groundPos_cam,0.0); 											// pos_cs
	gl_FragData[2] = vec4( (sg_matrix_worldToCamera * vec4(0.0,1.0,0.0,0.0)).xyz,0.0); 	// normal_cs
	gl_FragData[4] = vec4( 0.0); 														// diffuse
	gl_FragData[5] = vec4( 0.0); 														// specular

	vec3 worldLightDir = normalize(sunPosition.xyz);

	// fragment completely in haze?
	if(useHaze && worldDistance >= hazeFar) {
		gl_FragData[0] = gl_FragData[3] = vec4( hazeColor + vec3(sunGlow(worldLightDir)) , 1.0);
		gl_FragDepth = calcFragmentDepth(groundPos_cam);
		return;
	}
	vec3 worldNormal = vec3(0.0, 1.0, 0.0);
	vec3 color = vec3(0.0, 0.0, 0.0);

	// scaled position on the ground (in ground space coordinates)
	vec2 groundPos = worldGroundIntersection.xz / scale;

	if(type == TYPE_MEADOW) {
		calculateMeadow(groundPos, color);
	} else if(type == TYPE_SIMPLE_TEXTURE) {
		color = vec3(texture2D(texture_1, groundPos) + texture2D(texture_1, groundPos * 1.743) + texture2D(texture_1, groundPos * 4.13)) * 0.3333;
	} else if(type == TYPE_CHESSBOARD) {
		calculateChessboard(groundPos, color);
	} else if(type == TYPE_WATER) {
		calculateWater(groundPos, worldLightDir, groundPos_cam, color, worldNormal,worldGroundIntersection);
	} else if(type == TYPE_GRID) {
		if(mod(groundPos.x+0.01,1.0)>0.02 && mod(groundPos.y+0.01,1.0)>0.02 )
			discard;
		color = vec3(1.0,1.0,1.0);
	} 
	// set the depth value
	gl_FragDepth = calcFragmentDepth(groundPos_cam);

	{
		// add lighting (sunlight)
		// \note The effect of the ambient part is massively reduced.
		vec3 ambientAndDiffuse = sunAmbient +
//								 sunDiffuse * clamp( 0.6 + 0.5 * dot(vec3(worldLightDir.x, -worldLightDir.y, -worldLightDir.z), worldNormal), 0.0, 1.0);
								 sunDiffuse * clamp( 0.6 + 0.5 * dot(worldLightDir, worldNormal), 0.0, 1.0);
		color *= ambientAndDiffuse;
//		color *= dot(worldLightDir, worldNormal);
	}
	if( type == TYPE_WHITE) {
		color = vec3(1.0,1.0,1.0);
	}

	// add haze
	if(useHaze) {
		color = mix(color, hazeColor, smoothstep(hazeNear, hazeFar, worldDistance));
		color += sunGlow(worldLightDir);
	}

//	gl_FragColor = vec4(color, 1.0);
	
	// multiple render targets \see universal3/main_mrt.sfn
	{
		gl_FragData[0] = vec4( color,1.0);											// "normal" color
		gl_FragData[3] = vec4( color,1.0); 											// ambient (emission)
	}

}

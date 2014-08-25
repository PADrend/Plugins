/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Lukas Kopecki
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
uniform sampler2D ColorMap;
uniform sampler2D BumpMap;
uniform vec4 skyColor_1, skyColor_2, skyColor_3; // azimuth, middle, horizon
uniform vec4 cloudColor;
uniform float cloudDensity;// = 0.6;
uniform vec3 sunPosition;
uniform bool starsEnabled;// = false;

varying vec3 vpos; //, lpos;
varying vec2 texCoord_1, texCoord_2, texCoord_3, skyPos_ws;

uniform float maxSunBrightness = 10000.0; // to get values beyond 1.0 for hdr
const float bloomingExponent = 4.0;
const float bloomingScale = 1.0;
const float wobble = 0.4;
const float cloudCutLine = 0.08; // 0.05-0.015

void main(void){

	// Always output nearly maximum depth. Maximum depth (= 1.0) gets clipped.
	gl_FragDepth = 0.99999;

	vec3 norm = -normalize(vpos).xyz;
	vec3 lightDir = normalize(sunPosition.xyz);
	float distanceToSun = 1.0 - max(0.0, dot(-lightDir,norm));

	// ---------
	// -- mix skyColor_2 & skyColor_3
	vec3 skyColor = mix( skyColor_3.rgb, skyColor_2.rgb,
						0.1*pow(11.0,length(norm.xz))-0.1 );

	
	// stars (experimental)
	if(starsEnabled){
		vec3 t = texture2D(BumpMap, skyPos_ws*10.0).xyz;
		if( t.x < 0.02  )
			skyColor += vec3( max(  t.y * (t.y - (skyColor.x+skyColor.y+skyColor.z)*0.33 ) *3.0 ,0.0 ) );
		
	}
	float cloudStrength = 0.0;
	
	// used to smoothly blend  out clouds near the horizon
	float noCloudsNearHorizon =  1.0 - clamp( pow(1.0+norm.y+cloudCutLine,48.0),0.0,1.0);

	// this can reduce the number of calculations and texture lookups
	if(noCloudsNearHorizon>0.20){
		// ---------------------------
		// -- calculate cloud depth
		vec2 t1 = texture2D(ColorMap, texCoord_1).xy;
		float cloudDepth_1 = t1.x;
		float cloudDepth_2 = 0.5*texture2D(ColorMap, texCoord_2).x;
		vec2 texCoord_3b= texCoord_3 - wobble*(1.0+norm.y)*vec2(cloudDepth_1,cloudDepth_2); // add wobbel
		float cloudDepth_3 = 0.25*texture2D(ColorMap, texCoord_3b ).x;

		float cloudDepth = (cloudDepth_1 + cloudDepth_2 + cloudDepth_3)/1.75;
		cloudDepth = pow( cloudDepth+0.5, 0.5+t1.y*3.0 ) - 0.5; // add some sharper cloud edges


		// ---------------------------
		// -- calculate cloud normal
		vec3 cNorm = normalize(texture2D(BumpMap, texCoord_1).xyz +
							   0.5*texture2D(BumpMap, texCoord_2).xyz +
							   0.25*texture2D(BumpMap, texCoord_3b).xyz);

		// ---------------------------
		// -- add clouds to skyColor
		// \note if cloudDensity is high, the blooming is reduced
		float sunBlooming = pow( 1.0-distanceToSun, bloomingExponent )*bloomingScale*(1.0-cloudDensity);

//        float cloudBrightness = clamp( pow( clamp(dot(cNorm, lightDir),0.0,1.0), 2.0) * 1.0 + 0.6 + sunBlooming, 0.0, 2.0);
		float cloudBrightness = clamp( pow( clamp(dot(cNorm, lightDir),0.0,1.0), 2.0) + sunBlooming + 0.5 + (2.0-cloudDepth-cloudDensity)*0.2 , 0.0, 2.0);
		cloudStrength = pow(clamp((cloudDepth-(1.0-cloudDensity))*4.0,0.0,noCloudsNearHorizon),3.0 );
		
		skyColor = mix( skyColor, cloudColor.rgb  * cloudBrightness, cloudStrength );
	}

	// ---------------------------
	// -- calculate haze
	float hazeFactor =  clamp( pow(1.0+norm.y,6.0),0.0,1.0) ; // optimization:(norm.y>-0.4) ?

	// ---------------------------
	// -- mix skyColor & skyColor_1 (horizon)
	skyColor = mix( skyColor,skyColor_1.rgb,hazeFactor);

	// ---------------------------
	// -- add sun
	skyColor += vec3(pow( 1.0-distanceToSun, 1024.0 * (1.0-hazeFactor*0.95) ));  // halo
	
	// add massive sun power for hdr images
	if(distanceToSun<0.0005){
		float coreSunPower = max( 2.0, maxSunBrightness * (1.0 - clamp( pow(1.0+norm.y,2.0) + cloudStrength,0.0,1.0) ));
		skyColor += vec3(coreSunPower);
	}

	gl_FragColor = vec4( skyColor,1.0);
//    gl_FragColor = vec4(cNorm*abs(dot(cNorm, lightDir)) ,0.0);
}

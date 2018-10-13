#version 110
/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*! DisplayAlpha - Post-processing fragment shader to display the alpha channel of the image.
    2011-07-15 Benjamin Eikel
 */

uniform sampler2D colorTexture;

void main() {
	vec4 color = texture2D(colorTexture, gl_TexCoord[0].xy);
	
	float squareSize = 10.0;
	vec2 squareCoord = (gl_FragCoord.xy - (0.5, 0.5)) / squareSize;
	
	bool evenRow = (mod(squareCoord.y, 2.0) < 1.0);
	bool evenColumn = (mod(squareCoord.x, 2.0) < 1.0);
	
	vec4 alphaColor;
	if(evenRow ^^ evenColumn) {
		// Dark alpha color
		alphaColor = vec4(0.5, 0.5, 0.5, 1);
	} else {
		// Light alpha color
		alphaColor = vec4(0.75, 0.75, 0.75, 1);
	}
	
	gl_FragColor.rgb = (1.0 - color.a) * alphaColor.rgb + color.a * color.rgb;
	gl_FragColor.a = 1.0;
}

#version 120

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010-2013 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

attribute vec3 sg_Position;

varying vec4 pixelColor;

vec4 addLighting();
void addTexture(inout vec4 color);
void addShadow(inout vec4 color);

uniform mat4 sg_modelViewProjectionMatrix;

void main (void) {
	gl_Position = sg_modelViewProjectionMatrix * vec4(sg_Position,1);
	pixelColor = addLighting();
	
	addTexture(pixelColor);
	addShadow(pixelColor);
}

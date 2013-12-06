#version 130

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*!	PackGeometry - Shader that packs the geometry information for each pixel
	               into the color buffers
	2009-12-08 - Benjamin Eikel
 */

in vec3 sg_Position;
in vec3 sg_Normal;
in vec4 sg_Color;

out vec4 position;
out vec3 normal;
out vec4 color;

uniform mat4 sg_modelViewMatrix;
uniform mat4 sg_modelViewProjectionMatrix;

void main() {
	position = sg_modelViewMatrix * vec4(sg_Position, 1.0);
	normal = normalize((sg_modelViewMatrix * vec4(sg_Normal, 0.0)).xyz);
	color = sg_Color;
	gl_Position = sg_modelViewProjectionMatrix * vec4(sg_Position, 1.0);
}

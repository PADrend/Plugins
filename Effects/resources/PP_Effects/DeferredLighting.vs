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
/*!	PP_DeferredLighting - Shader for calculating lighting based on geometry data
	                      packed into textures.
	2009-12-09 - Benjamin Eikel
 */

in vec3 sg_Position;
in vec2 sg_TexCoord0;

out vec2 texCoord;

uniform mat4 sg_modelViewProjectionMatrix;

void main(void) {
	texCoord = sg_TexCoord0;
	gl_Position = sg_modelViewProjectionMatrix * vec4(sg_Position, 1.0);
}

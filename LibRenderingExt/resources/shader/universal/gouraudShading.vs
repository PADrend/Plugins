#version 120

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010-2013 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

vec4 addLighting(vec3 esPos, vec3 esNormal, vec4 color);

uniform mat4 sg_matrix_modelToCamera;

attribute vec4 sg_Color;
attribute vec3 sg_Normal;
attribute vec3 sg_Position;

vec4 addLighting() {
	vec4 esPos4 = sg_matrix_modelToCamera * vec4(sg_Position,1);
	vec3 esPos = esPos4.xyz / esPos4.w;
	vec3 esNormal = normalize((sg_matrix_modelToCamera * vec4(sg_Normal,0)).xyz);
	return addLighting(esPos, esNormal, sg_Color);
}

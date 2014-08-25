#version 120

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

uniform mat4 sg_matrix_modelToCamera;
uniform mat4 sg_matrix_modelToClipping;

attribute vec3 sg_Normal;
attribute vec3 sg_Position;
attribute vec4 sg_Color;

varying vec3 eyeSpaceNormal;
varying vec4 eyeSpacePosition;

vec4 addLighting() {
	eyeSpaceNormal = normalize((sg_matrix_modelToCamera * vec4(sg_Normal,0)).xyz);
	eyeSpacePosition = sg_matrix_modelToCamera * vec4(sg_Position, 1);
	return sg_Color;
}

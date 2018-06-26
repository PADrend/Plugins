#version 330

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2018 Sascha Brandt <sascha@brandt.graphics>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

layout(location = 0) in vec3 sg_Position;
layout(location = 4) in vec2 sg_TexCoord0;

out vec2 texCoord;

uniform mat4 sg_matrix_modelToClipping;

void main(void){
	texCoord = sg_TexCoord0;
	gl_Position = sg_matrix_modelToClipping * vec4(sg_Position,1);
}

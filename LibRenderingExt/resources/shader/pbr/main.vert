#version 450
/*
	This file is part of the open source part of the
	Platform for Algorithm Development and Rendering (PADrend).
	Web page: http://www.padrend.de/
	Copyright (C) 2020-2021 Sascha Brandt <sascha@brandt.graphics>

	PADrend consists of an open source part and a proprietary part.
	The open source part of PADrend is subject to the terms of the Mozilla
	Public License, v. 2.0. You should have received a copy of the MPL along
	with this library; see the file LICENSE. If not, you can obtain one at
	http://mozilla.org/MPL/2.0/.
*/

uniform mat4 sg_matrix_modelToCamera;
uniform mat4 sg_matrix_modelToClipping;

in vec3 sg_Position;
in vec3 sg_Normal;
in vec4 sg_Color;
in vec2 sg_TexCoord0;
in vec2 sg_TexCoord1;

out VertexInterface {
	vec3 position;
	vec3 normal;
	vec4 color;
	vec2 texCoord0;
	vec2 texCoord1;
} vsOut;

void main() {
	vsOut.position = (sg_matrix_modelToCamera * vec4(sg_Position, 1.0)).xyz;
	vsOut.normal = (sg_matrix_modelToCamera * vec4(sg_Normal, 0.0)).xyz;
	vsOut.color = sg_Color;
	vsOut.texCoord0 = sg_TexCoord0;
	vsOut.texCoord1 = sg_TexCoord1;
	gl_Position = sg_matrix_modelToClipping * vec4(sg_Position, 1.0);
}
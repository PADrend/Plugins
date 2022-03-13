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
#include "skin.glsl"

uniform mat4 sg_matrix_modelToCamera;
uniform mat4 sg_matrix_modelToClipping;
uniform mat4 sg_matrix_cameraToWorld;
uniform mat4 sg_shadowMatrix;

in vec3 sg_Position;
in vec3 sg_Normal;
in vec4 sg_Color;
in vec2 sg_TexCoord0;
in vec2 sg_TexCoord1;

out VertexInterface {
	vec4 position;
	vec3 normal;
	vec4 color;
	vec2 texCoord0;
	vec2 texCoord1;
	vec4 shadowCoord;
	vec4 camera;
} vsOut;

void main() {
	vec4 skinnedPos = applySkinning(vec4(sg_Position, 1.0));
	vec4 skinnedNrm = applySkinning(vec4(sg_Normal, 0.0));
	vsOut.position = ( sg_matrix_modelToCamera * skinnedPos);
	vsOut.normal = ( sg_matrix_modelToCamera * skinnedNrm).xyz;
	vsOut.camera = ( vec4(0.0, 0.0, 0.0, 1.0));
	vsOut.color = sg_Color;
	vsOut.texCoord0 = sg_TexCoord0;
	vsOut.texCoord1 = sg_TexCoord1;
	vsOut.shadowCoord = sg_shadowMatrix * sg_matrix_cameraToWorld * sg_matrix_modelToCamera * skinnedPos;
	gl_Position = sg_matrix_modelToClipping * skinnedPos;
}
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
#ifndef RENDERING_SHADER_SKIN_GLSL_
#define RENDERING_SHADER_SKIN_GLSL_

#ifdef USE_SKINNING

	in vec4 sg_Weights0;
	in ivec4 sg_Joints0;

	layout(std430, binding = 0) readonly buffer JointMatrices {
		mat4 jointMatrices[];
	};

	uniform bool sg_SkinningEnabled;

	vec4 applySkinning(vec4 pos) {
		if(sg_SkinningEnabled) {
			mat4 skinMat = 
				sg_Weights0.x * jointMatrices[int(sg_Joints0.x)] +
				sg_Weights0.y * jointMatrices[int(sg_Joints0.y)] +
				sg_Weights0.z * jointMatrices[int(sg_Joints0.z)] +
				sg_Weights0.w * jointMatrices[int(sg_Joints0.w)];
			return skinMat * pos;
		} else {
			return pos;
		}
	}

#else

	vec4 applySkinning(vec4 pos) {
		return pos;
	}

#endif

#endif /* end of include guard: RENDERING_SHADER_SKIN_GLSL_ */
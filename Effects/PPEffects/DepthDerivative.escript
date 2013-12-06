/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var Effect = new Type(PPEffect_Simple);

Effect._constructor ::= fn() @(super(Rendering.Shader.loadShader(getShaderFolder() + "Simple_130.vs", getShaderFolder() + "DepthDerivative.fs", Rendering.Shader.USE_UNIFORMS))) {
	this.derivativeOrder := DataWrapper.createFromValue(3);
	this.edgeHighlightMode := DataWrapper.createFromValue(true);
	this.epsilon := DataWrapper.createFromValue(0.00001);
};

Effect.applyUniforms ::= fn() {
	shader.setUniform(renderingContext,"derivativeOrder", Rendering.Uniform.INT, [derivativeOrder()]);
	shader.setUniform(renderingContext,"edgeHighlightMode", Rendering.Uniform.BOOL, [edgeHighlightMode()]);
	shader.setUniform(renderingContext,"epsilon", Rendering.Uniform.FLOAT, [epsilon()]);
};

Effect.addOptions ::= fn(panel) {
	panel += "*DepthDerivative*";
	panel++;
	panel += {
		GUI.LABEL			:	"derivativeOrder",
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.RANGE			:	[1, 3],
		GUI.RANGE_STEPS		:	2,
		GUI.DATA_WRAPPER	:	this.derivativeOrder
	};
	panel++;
	panel += {
		GUI.LABEL			:	"edgeHighlightMode",
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.DATA_WRAPPER	:	this.edgeHighlightMode
	};
	panel++;
	panel += {
		GUI.LABEL			:	"epsilon",
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.RANGE			:	[-2, -8],
		GUI.RANGE_STEPS		:	6,
		GUI.RANGE_FN_BASE	:	10,
		GUI.DATA_WRAPPER	:	this.epsilon
	};
	panel++;
};

return new Effect();

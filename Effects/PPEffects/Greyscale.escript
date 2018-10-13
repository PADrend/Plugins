/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var Effect = new Type( Std.module('Effects/SimplePPEffect') );

Effect._constructor::=fn()@(super(Rendering.Shader.loadShader(getShaderFolder()+"Default.vs", getShaderFolder()+"Greyscale.fs", Rendering.Shader.USE_UNIFORMS))){
	this.weight_r := 0.3;
	this.weight_g := 0.59;
	this.weight_b := 0.11;
	this.gamma := 1.0;
};

Effect.applyUniforms @(override) ::= fn(){
	shader.setUniform(renderingContext,"weight_r", Rendering.Uniform.FLOAT, [weight_r]);
	shader.setUniform(renderingContext,"weight_g", Rendering.Uniform.FLOAT, [weight_g]);
	shader.setUniform(renderingContext,"weight_b", Rendering.Uniform.FLOAT, [weight_b]);
	shader.setUniform(renderingContext,"gamma", Rendering.Uniform.FLOAT, [gamma]);
};

Effect.addOptions @(override) ::= fn(p){
	
	p += "*Greyscale*";
	p++;
	p += {GUI.LABEL:"weight_r", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,1], GUI.RANGE_STEPS:100, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$weight_r};
	p++;
	p += {GUI.LABEL:"weight_g", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,1], GUI.RANGE_STEPS:100, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$weight_g};
	p++;
	p += {GUI.LABEL:"weight_b", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,1], GUI.RANGE_STEPS:100, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$weight_b};
	p++;
	p += {GUI.LABEL:"gamma", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[-2,2], GUI.RANGE_FN: fn(x){return (2).pow(x);}, GUI.RANGE_INV_FN: fn(x){return (2).pow(1/x);}, GUI.RANGE_STEPS:100, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$gamma};
	p++;
};

return new Effect;

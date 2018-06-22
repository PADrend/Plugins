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

Effect._constructor::=fn()@(super(Rendering.Shader.loadShader(getShaderFolder()+"Default.vs", getShaderFolder()+"Posterize.fs", Rendering.Shader.USE_UNIFORMS))){
	
	this.gamma := 0.6;
	this.numColors := 8;
	
};

Effect.applyUniforms @(override) ::= fn(){
	shader.setUniform(renderingContext,"gamma", Rendering.Uniform.FLOAT, [this.gamma]);
	shader.setUniform(renderingContext,"numColors", Rendering.Uniform.FLOAT, [this.numColors]);
};

Effect.addOptions @(override) ::= fn(p){
	
	p += "*Posterize*";
	p++;
	p += {GUI.LABEL:"# colors", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[2,32], GUI.RANGE_STEPS:30, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$numColors};
	p++;
	p += {GUI.LABEL:"gamma", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,2], GUI.RANGE_STEPS:20, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$gamma};
	p++;
};

return new Effect;

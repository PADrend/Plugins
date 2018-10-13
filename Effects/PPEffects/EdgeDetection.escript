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

Effect._constructor::=fn()@(super(Rendering.Shader.loadShader(getShaderFolder()+"Default.vs", getShaderFolder()+"EdgeDetection.fs", Rendering.Shader.USE_GL))){
	this.colorize := false;
	this.useDepth := false;
	this.method := false;
};

Effect.applyUniforms @(override) ::= fn(){
	shader.setUniform(renderingContext,"colorize", Rendering.Uniform.BOOL, [colorize]);
	shader.setUniform(renderingContext,"useDepth", Rendering.Uniform.BOOL, [useDepth]);
	shader.setUniform(renderingContext,"method", Rendering.Uniform.BOOL, [method]);
};

Effect.addOptions @(override) ::= fn(p){
	
	p += "*EdgeDetection*";
	p++;
	p += {GUI.LABEL:"colorize", GUI.TYPE:GUI.TYPE_BOOL, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$colorize};
	p++;
	p += {GUI.LABEL:"useDepth", GUI.TYPE:GUI.TYPE_BOOL, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$useDepth};
	p++;
	p += {GUI.LABEL:"switch method", GUI.TYPE:GUI.TYPE_BOOL, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$method};
	p++;
};

return new Effect;

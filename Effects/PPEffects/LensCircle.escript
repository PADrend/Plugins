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

Effect._constructor::=fn()@(super(Rendering.Shader.loadShader(getShaderFolder()+"Default.vs", getShaderFolder()+"LensCircle.fs", Rendering.Shader.USE_GL))){
	this.innerRadius := 0.1;
	this.outerRadius := 0.55;
	this.move := false;
};

Effect.applyUniforms @(override) ::= fn(){
	shader.setUniform(renderingContext,"innerRadius", Rendering.Uniform.FLOAT, [innerRadius]);
	shader.setUniform(renderingContext,"outerRadius", Rendering.Uniform.FLOAT, [outerRadius]);
	shader.setUniform(renderingContext,"move", Rendering.Uniform.BOOL, [move]);
};

Effect.addOptions @(override) ::= fn(p){
	
	p += "*LensCircle*";
	p++;
	p += {GUI.LABEL:"inner radius", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,1], GUI.RANGE_STEPS:100, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$innerRadius};
	p++;
	p += {GUI.LABEL:"outer radius", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,1], GUI.RANGE_STEPS:100, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$outerRadius};
	p++;
	p += {GUI.LABEL:"move", GUI.TYPE:GUI.TYPE_BOOL, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$move};
	p++;
};

return new Effect;

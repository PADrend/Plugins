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

Effect._constructor::=fn()@(super(Rendering.Shader.loadShader(getShaderFolder()+"Default.vs", getShaderFolder()+"CrossStitch.fs", Rendering.Shader.USE_GL))){
	
	this.stitchSize := 6;
	this.invert := true;
};

Effect.applyUniforms @(override) ::= fn(){
	shader.setUniform(renderingContext,"stitchSize", Rendering.Uniform.INT, [this.stitchSize]);
	shader.setUniform(renderingContext,"invert", Rendering.Uniform.BOOL, [invert]);
};

Effect.addOptions @(override) ::= fn(p){
	
	p += "*CrossStitch*";
	p++;
	p += {GUI.LABEL:"stitch size", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[3,20], GUI.RANGE_STEPS:17, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$stitchSize};
	p++;
	p += {GUI.LABEL:"invert", GUI.TYPE:GUI.TYPE_BOOL, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$invert};
	p++;
};

return new Effect;

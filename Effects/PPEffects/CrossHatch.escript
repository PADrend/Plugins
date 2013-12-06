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
var Effect = new Type(PPEffect_Simple);

Effect._constructor::=fn()@(super(Rendering.Shader.loadShader(getShaderFolder()+"Simple_GL.vs", getShaderFolder()+"CrossHatch.fs", Rendering.Shader.USE_GL))){
	
	this.hatch_y := 5; // other values don't make sense --> no gui entry
	this.lum_1 := 1.0;
	this.lum_2 := 0.7;
	this.lum_3 := 0.5;
	this.lum_4 := 0.3;
	
};

Effect.applyUniforms ::= fn(){
	shader.setUniform(renderingContext,"hatch_y_offset", Rendering.Uniform.FLOAT, [this.hatch_y]);
	shader.setUniform(renderingContext,"lum_threshold_1", Rendering.Uniform.FLOAT, [this.lum_1]);
	shader.setUniform(renderingContext,"lum_threshold_2", Rendering.Uniform.FLOAT, [this.lum_2]);
	shader.setUniform(renderingContext,"lum_threshold_3", Rendering.Uniform.FLOAT, [this.lum_3]);
	shader.setUniform(renderingContext,"lum_threshold_4", Rendering.Uniform.FLOAT, [this.lum_4]);
};

Effect.addOptions ::= fn(p){
	
	p += "*CrossHatch*";
	p++;
	p += {GUI.LABEL:"lum 1", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,1], GUI.RANGE_STEPS:20, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$lum_1};
	p++;
	p += {GUI.LABEL:"lum 2", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,1], GUI.RANGE_STEPS:20, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$lum_2};
	p++;
	p += {GUI.LABEL:"lum 3", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,1], GUI.RANGE_STEPS:20, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$lum_3};
	p++;
	p += {GUI.LABEL:"lum 4", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,1], GUI.RANGE_STEPS:20, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$lum_4};
	p++;
};

return new Effect();
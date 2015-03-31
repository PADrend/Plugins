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

Effect._constructor::=fn()@(super(Rendering.Shader.loadShader(getShaderFolder()+"Simple_GL.vs", getShaderFolder()+"NightVision.fs", Rendering.Shader.USE_GL))){
	this.lumThres := 0.2;
	this.colorAmp := 8.0;
	this.maskSize := [renderingContext.getWindowWidth()/2, renderingContext.getWindowHeight()/2].min()/8;
	this.noise = true;
};

Effect.applyUniforms @(override) ::= fn(){
	shader.setUniform(renderingContext,"lumThres", Rendering.Uniform.FLOAT, [lumThres]);
	shader.setUniform(renderingContext,"colorAmp", Rendering.Uniform.FLOAT, [colorAmp]);
	shader.setUniform(renderingContext,"maskSize", Rendering.Uniform.FLOAT, [maskSize]);
};

Effect.addOptions @(override) ::= fn(p){
	
	p += "*NightVision*";
	p++;
	p += {GUI.LABEL:"lum thres", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,1], GUI.RANGE_STEPS:40, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$lumThres};
	p++;
	p += {GUI.LABEL:"color amp", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,8], GUI.RANGE_STEPS:40, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$colorAmp};
	p++;
	p += {GUI.LABEL:"maskSize", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,[renderingContext.getWindowWidth()/2, renderingContext.getWindowHeight()/2].min()], GUI.RANGE_STEPS:[renderingContext.getWindowWidth()/2, renderingContext.getWindowHeight()/2].min(), GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$maskSize};
	p++;
};

return new Effect;

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

Effect._constructor::=fn()@(super(Rendering.Shader.loadShader(getShaderFolder()+"Default.vs", getShaderFolder()+"IceGlass.fs", Rendering.Shader.USE_GL))){
	
	this.noise = true;
	this.pixelX := 2;
	this.pixelY := 2;
	this.freq := 0.115;
};

Effect.applyUniforms @(override) ::= fn(){
	
	shader.setUniform(renderingContext,"PixelX", Rendering.Uniform.INT, [pixelX]);
	shader.setUniform(renderingContext,"PixelY", Rendering.Uniform.INT, [pixelY]);
	shader.setUniform(renderingContext,"Freq", Rendering.Uniform.FLOAT, [freq]);
};

Effect.addOptions @(override) ::= fn(p){
	
	p += "*IceGlass*";
	p++;
	p += {GUI.LABEL:"pixel x", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,8], GUI.RANGE_STEPS:8, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$pixelX};
	p++;
	p += {GUI.LABEL:"pixel y", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,8], GUI.RANGE_STEPS:8, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$pixelY};
	p++;
	p += {GUI.LABEL:"frequency", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,1], GUI.RANGE_STEPS:100, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$freq};
	p++;
};

return new Effect;

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
var Effect = new Type( Std.require('Effects/SimplePPEffect') );

Effect._constructor::=fn()@(super(Rendering.Shader.loadShader(getShaderFolder()+"Simple_130.vs", getShaderFolder()+"Pixelize.fs", Rendering.Shader.USE_UNIFORMS))){
	this.pixelSize := 16;
};

Effect.applyUniforms @(override) ::= fn(){
	shader.setUniform(renderingContext,"pixelSize", Rendering.Uniform.INT, [pixelSize]);
};

Effect.addOptions @(override) ::= fn(p){
	
	p += "*Pixelize*";
	p++;
	p += {GUI.LABEL:"pixel size", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[1,50], GUI.RANGE_STEPS:49, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$pixelSize};
	p++;
};

return new Effect;

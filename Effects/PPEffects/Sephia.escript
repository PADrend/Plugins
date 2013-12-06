/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var Effect = new Type(PPEffect_Simple);

Effect._constructor::=fn()@(super(Rendering.Shader.loadShader(getShaderFolder()+"Simple_130.vs", getShaderFolder()+"Sepia.fs", Rendering.Shader.USE_UNIFORMS))){
	this.border := renderingContext.getWindowWidth();
};

return new Effect();
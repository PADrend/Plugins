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
var Effect = new Type( Std.module('Effects/SimplePPEffect2') );

Effect._constructor ::= fn() {
	this.shader := Rendering.Shader.loadShader(getShaderFolder() + "NormalToColor.vs", getShaderFolder() + "NormalToColor.fs", Rendering.Shader.USE_GL);
};

Effect.begin @(override) ::= fn() {
	renderingContext.pushAndSetFBO(fbo);
	renderingContext.pushAndSetShader(shader);
};

Effect.end @(override) ::= fn() {
	renderingContext.popFBO();
	renderingContext.popShader();
	
	drawTexture(colorTexture);
};

return new Effect;

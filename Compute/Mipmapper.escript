/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2018-2019 Sascha Brandt <sascha@brandt.graphics>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
 
var T = new Type();
T._printableName @(override) := $Mipmap;

T.shader @(private) := void;
T.initialized @(private) := false; 

T.layers := 1;
T.textureCount := 1;

// ----------------------------------------

T.build ::= fn() {
	if(initialized)
		return;
	var defines = {
		'TEXTURES' : textureCount,
	};
	if(layers > 1)
		defines['LAYER_COUNT'] = layers;
	var file = __DIR__ + "/shader/mipmap.sfn";
	this.shader = Rendering.Shader.createShader();
	this.shader.attachVSFile(file, defines);
	this.shader.attachFSFile(file, defines);
	if(layers > 1)
		this.shader.attachGSFile(file, defines);
		
	// force shader compilation
	renderingContext.pushAndSetShader(shader);
	renderingContext.popShader();
	
	initialized = true;
};

// ----------------------------------------

T.generate ::= fn(minLevel, maxLevel, textures...) {
	build();
	var vp = new Geometry.Rect(0,0,textures[0].getWidth()/2.pow(minLevel), textures[0].getHeight()/2.pow(minLevel));
	
	var fbo = new Rendering.FBO;
	fbo.setDrawBuffers(renderingContext, textureCount);
	renderingContext.pushViewport();
	renderingContext.pushAndSetFBO(fbo);
	renderingContext.pushAndSetShader(shader);
	for(var i=0; i<textureCount; ++i)
		renderingContext.pushAndSetTexture(i, textures[i]);

	for(var level=minLevel+1; level<=maxLevel; ++level) {
		shader.setUniform(renderingContext, 'level', Rendering.Uniform.INT, [level]);    
		for(var i=0; i<textureCount; ++i)
			fbo.attachColorTexture(renderingContext, textures[i], i, level);
		vp.setSize(vp.getWidth()/2, vp.getHeight()/2);
		renderingContext.setViewport(vp);
		Rendering.drawFullScreenRect(renderingContext);
		renderingContext.barrier();
	}
	
	for(var i=0; i<textureCount; ++i)
		renderingContext.popTexture(i);
	renderingContext.popShader();
	renderingContext.popFBO();
	renderingContext.popViewport();
};

// ----------------------------------------

return T;
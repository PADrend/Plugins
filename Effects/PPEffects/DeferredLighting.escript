/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Effects] Effects/PPEffects/SSAO.escript
 **/


var Effect = new Type( Std.module('Effects/PPEffect') );

Effect.debug := void;

Effect._constructor ::= fn() {
	debug = new Std.DataWrapper(false);
	
	this.fbo := new Rendering.FBO();
	renderingContext.pushAndSetFBO(fbo);

	this.texturePosition := Rendering.createHDRTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight(), true);
	fbo.attachColorTexture(renderingContext,texturePosition, 0);

	this.textureNormal := Rendering.createHDRTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight(), true);
	fbo.attachColorTexture(renderingContext,textureNormal, 1);

	this.textureAmbient := Rendering.createStdTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight(), true);
	fbo.attachColorTexture(renderingContext,textureAmbient, 2);

	this.textureDiffuse := Rendering.createStdTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight(), true);
	fbo.attachColorTexture(renderingContext,textureDiffuse, 3);

	this.textureSpecular := Rendering.createStdTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight(), true);
	fbo.attachColorTexture(renderingContext,textureSpecular, 4);

	this.depthTexture := Rendering.createDepthTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight());
	fbo.attachDepthTexture(renderingContext,depthTexture);

	renderingContext.popFBO();

	this.packShader := Rendering.Shader.loadShader(getShaderFolder()+"PackGeometry.vs", getShaderFolder()+"PackGeometry.fs", Rendering.Shader.USE_UNIFORMS);
	this.lightShader := Rendering.Shader.loadShader(getShaderFolder()+"DeferredLighting.vs", getShaderFolder()+"DeferredLighting.fs", Rendering.Shader.USE_UNIFORMS);
};

//! ---|> PPEffect
Effect.begin @(override) ::= fn() {
	renderingContext.pushAndSetFBO(fbo);
	fbo.setDrawBuffers(5);
	renderingContext.pushAndSetShader(packShader);
};

//! ---|> PPEffect
Effect.end @(override) ::= fn() {
	fbo.setDrawBuffers(1);
	renderingContext.popFBO();
	renderingContext.popShader();

	renderingContext.clearScreen(PADrend.getBGColor());

	var texCoords = new Geometry.Rect(0, 0, 1, 1);
	var textures = [
		texturePosition,
		textureNormal,
		textureAmbient,
		textureDiffuse,
		textureSpecular
	];

	if(debug()){ // debug mode
		Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0, 0, renderingContext.getWindowWidth(), renderingContext.getWindowHeight()),
										[textures[debug()]],
										[texCoords] );
		
	}else{
		var lightStates = MinSG.collectStates(PADrend.getRootNode(), MinSG.LightingState);
		foreach(lightStates as var lightState) {
			lightState.enableState(GLOBALS.frameContext);
		}

		renderingContext.pushAndSetShader(lightShader);

		Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0, 0, renderingContext.getWindowWidth(), renderingContext.getWindowHeight()),
										textures,
										[
											texCoords,
											texCoords,
											texCoords,
											texCoords,
											texCoords
										]);

		renderingContext.popShader();

		foreach(lightStates as var lightState) {
			lightState.disableState(GLOBALS.frameContext);
		}
	}

	
};

//! ---|> PPEffect
Effect.getOptionPanel:=fn(){
    var p = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.SIZE : GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT : GUI.LAYOUT_FLOW
	});
	p+={
		GUI.TYPE : GUI.TYPE_SELECT,
		GUI.DATA_WRAPPER : debug,
		GUI.LABEL : "Mode:",
		GUI.OPTIONS : [
			[false,"Deffered lighting"],
			[0,"Debug: Position"],
			[1,"Debug: Normal"],
			[2,"Debug: Ambient"],
			[3,"Debug: Diffuse"],
			[4,"Debug: Specular"]
		]
		
	};
    
    return p;
};

return new Effect;

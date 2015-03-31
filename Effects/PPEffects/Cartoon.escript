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
var Effect = new Type( Std.module('Effects/PPEffect') );

Effect._constructor ::= fn(){
	
	this.fbo:=new Rendering.FBO;
	renderingContext.pushAndSetFBO(fbo);
	this.colorTexture_1:=Rendering.createHDRTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight(),true);
	fbo.attachColorTexture(renderingContext,colorTexture_1);
	this.depthTexture:=Rendering.createDepthTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight());
	fbo.attachDepthTexture(renderingContext,depthTexture);
	out(fbo.getStatusMessage(renderingContext),"\n");
	renderingContext.popFBO();
	
	this.shader:=Rendering.Shader.loadShader(getShaderFolder()+"Simple_GL.vs",getShaderFolder()+"Cartoon.fs");
	renderingContext.pushAndSetShader(shader);
	shader.setUniform(renderingContext,'TUnit_1',Rendering.Uniform.INT,[0]) ;
	shader.setUniform(renderingContext,'TDepth',Rendering.Uniform.INT,[1]) ;
	
	shader.setUniform(renderingContext,'pixelSizeY',Rendering.Uniform.FLOAT,[1.0/renderingContext.getWindowHeight()]) ;
	shader.setUniform(renderingContext,'pixelSizeX',Rendering.Uniform.FLOAT,[1.0/renderingContext.getWindowWidth()]) ;
	renderingContext.popShader();
};
/*! ---|> PPEffect  */
Effect.begin @(override) ::= fn(){
	
	renderingContext.pushAndSetFBO(fbo);
};
/*! ---|> PPEffect  */
Effect.end @(override) ::= fn(){
	renderingContext.popFBO();
	
	renderingContext.pushAndSetShader(shader);
	
	Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()) ,
								  [this.colorTexture_1,depthTexture],[new Geometry.Rect(0,0,1,1),new Geometry.Rect(0,0,1,1)]);
	
	renderingContext.popShader();
	
};

return new Effect;

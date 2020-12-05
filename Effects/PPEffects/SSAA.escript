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

Effect._constructor:=fn(){
	var width=renderingContext.getWindowWidth()*1.0;
	var height=renderingContext.getWindowHeight()*1.0;
	
	this.fbo:=new Rendering.FBO;
	renderingContext.pushAndSetFBO(fbo);
	this.colorTexture_1:=Rendering.createHDRTexture(width,height,true);
	fbo.attachColorTexture(renderingContext,colorTexture_1);

	this.colorTexture_2:=Rendering.createHDRTexture(width,height,true);

	
	this.depthTexture:=Rendering.createDepthTexture(width,height);
	fbo.attachDepthTexture(renderingContext,depthTexture);
	out(fbo.getStatusMessage(renderingContext),"\n");
	renderingContext.popFBO();
	
	this.shader1:=Rendering.Shader.loadShader(getShaderFolder()+"Default.vs",getShaderFolder()+"LumaToAlpha.fs");
	shader1.setUniform(renderingContext,'TUnit_1',Rendering.Uniform.INT,[0]) ;
//	shader1.setUniform(renderingContext,'TDepth',Rendering.Uniform.INT,[1]) ;

	this.shader2:= Rendering.Shader.createShader();
	shader2.attachVSFile(getShaderFolder()+"AA.sfn");
	shader2.attachFSFile(getShaderFolder()+"Fxaa3_8_mod.sfn");
	shader2.attachFSFile(getShaderFolder()+"AA.sfn");
	
	
	shader2.setUniform(renderingContext,'TUnit_1',Rendering.Uniform.INT,[0]) ;
	shader2.setUniform(renderingContext,'pixelSizeY',Rendering.Uniform.FLOAT,[1.0/height]) ;
	shader2.setUniform(renderingContext,'pixelSizeX',Rendering.Uniform.FLOAT,[1.0/width]) ;
//	shader2.setUniform(renderingContext,'FXAA_REDUCE_MUL',Rendering.Uniform.FLOAT,[0]) ;
//	shader2.setUniform(renderingContext,'FXAA_SUBPIX_SHIFT',Rendering.Uniform.FLOAT,[0.0]) ;
//	shader2.setUniform(renderingContext,'FXAA_SPAN_MAX',Rendering.Uniform.FLOAT,[4.0]) ;
//	renderingContext.popShader();
	//	camera.setViewport(new Geometry.Rect(0,0,width,height));
};
/*! ---|> PPEffect  */
Effect.begin:=fn(){
	
	renderingContext.pushAndSetFBO(fbo);
};
/*! ---|> PPEffect  */
Effect.end:=fn(){
	
	renderingContext.pushAndSetShader(shader1);
	
	Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()) ,
								  [this.colorTexture_1,depthTexture],[new Geometry.Rect(0,0,1,1),new Geometry.Rect(0,0,1,1)]);

	renderingContext.popShader();
	
	renderingContext.pushAndSetShader(shader2);
	
	var f = colorTexture_1;
	colorTexture_1 = colorTexture_2;
	colorTexture_2 = f;
	fbo.attachColorTexture(renderingContext,colorTexture_1);

	renderingContext.popFBO();
	
	Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()) ,
								  [this.colorTexture_1,depthTexture],[new Geometry.Rect(0,0,1,1),new Geometry.Rect(0,0,1,1)]);
	
	renderingContext.popShader();
	
};

return new Effect;

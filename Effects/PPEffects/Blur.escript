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
	this.range:=10;
	this.fbo:=new Rendering.FBO;
	renderingContext.pushAndSetFBO(fbo);
	this.colorTexture_1:=Rendering.createHDRTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight(),true);
	this.colorTexture_2:=Rendering.createHDRTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight(),true);
	fbo.attachColorTexture(renderingContext,colorTexture_1);
	this.depthTexture:=Rendering.createDepthTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight());
	fbo.attachDepthTexture(renderingContext,depthTexture);
	out(fbo.getStatusMessage(renderingContext),"\n");
	renderingContext.popFBO();
	
	this.shader:=Rendering.Shader.loadShader(getShaderFolder()+"Default.vs",getShaderFolder()+"Blur.fs");
	renderingContext.pushAndSetShader(this.shader);
	shader.setUniform(renderingContext,'TUnit_1',Rendering.Uniform.INT,[0]) ;
	
	//    shader.setUniform(renderingContext,'pixelSizeY',Rendering.Uniform.FLOAT,[1.0/renderingContext.getWindowHeight()]) ;
	renderingContext.popShader();
};
/*! ---|> PPEffect  */
Effect.begin @(override) ::= fn(){
	renderingContext.pushAndSetFBO(fbo);
	fbo.attachColorTexture(renderingContext,colorTexture_1);
	fbo.attachDepthTexture(renderingContext,depthTexture);
};
/*! ---|> PPEffect  */
Effect.end @(override) ::=fn(){
	fbo.detachDepthTexture(renderingContext);
	
	renderingContext.pushAndSetShader(shader);
	shader.setUniform(renderingContext,'range',Rendering.Uniform.INT,[range]) ;
	shader.setUniform(renderingContext,'pixelSize',Rendering.Uniform.FLOAT,[1.0/renderingContext.getWindowWidth()]) ;
	shader.setUniform(renderingContext,'orientation',Rendering.Uniform.INT,[0]) ;
	
	fbo.attachColorTexture(renderingContext,colorTexture_2);
	Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()) ,
								  this.colorTexture_1,new Geometry.Rect(0,0,1,1));
	
	fbo.attachColorTexture(renderingContext,colorTexture_1);
	shader.setUniform(renderingContext,'pixelSize',Rendering.Uniform.FLOAT,[1.0/renderingContext.getWindowHeight()]) ;
	shader.setUniform(renderingContext,'orientation',Rendering.Uniform.INT,[1]) ;
	
	Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()) ,
								  this.colorTexture_2,new Geometry.Rect(0,0,1,1));
	
	renderingContext.popFBO();
	renderingContext.popShader();
	renderingContext.pushAndSetShader(void);
	Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()) ,
								  this.colorTexture_1,new Geometry.Rect(0,0,1,1));
	renderingContext.popShader();
};
/*! ---|> PPEffect  */
Effect.getOptionPanel @(override) ::=fn(){
	var p=gui.createPanel(200,200,GUI.AUTO_MAXIMIZE|GUI.AUTO_LAYOUT);
	p.add(gui.createLabel("Blur"));
	p.nextRow();
	p.add(gui.createLabel("range"));
	p.nextColumn();
	var s=gui.createSlider(100,15,1,100,99,GUI.SHOW_VALUE);
	s.setValue(range);
	s.effect:=this;
	s.onDataChanged = fn(data){
		effect.range=getValue();
	};
	
	p.add( s );
	return p;
};

return new Effect;

/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017 Sascha Brandt <myeti@mail.upb.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
var Effect = new Type( Std.module('Effects/PPEffect') );

Effect.getShaderFolder ::= fn(){	return __DIR__+"/../resources/";	};

PADrend.getSceneManager().addSearchPath(__DIR__ + "/../resources/");

Effect._constructor ::= fn() {
	this.fbo := new Rendering.FBO();
	this.oldColor := void;
	
	this.colorTexture := Rendering.createHDRTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight(), false);
	fbo.attachColorTexture(renderingContext,colorTexture);
	
	//this.depthTexture := Rendering.createDepthTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight());
	//fbo.attachDepthTexture(renderingContext,depthTexture);
	
	this.blendingParams := new Rendering.BlendingParameters;
	blendingParams.enable();
	blendingParams.setBlendEquation(Rendering.BlendEquation.FUNC_ADD);
	blendingParams.setBlendFunc(Rendering.BlendFunc.ONE, Rendering.BlendFunc.ONE);
	//blendingParams.setBlendFuncSrcRGB(Rendering.BlendFunc.SRC_ALPHA);	

	this.scale := Std.DataWrapper.createFromEntry(PADrend.configCache,'Effects.DepthComplexity.scale',1.0);
	
	var renderingShaderState = new MinSG.ShaderState;
	(renderingShaderState.getStateAttributeWrapper(MinSG.ShaderState.STATE_ATTR_SHADER_NAME))( "surfels_depth_complexity.shader" );
	renderingShaderState.recreateShader( PADrend.getSceneManager() );
	this.shader := renderingShaderState.getShader();  
};

/*! ---|> PPEffect  */
Effect.begin @(override) ::= fn() {	
	this.oldColor = PADrend.EventLoop.getBGColor();
	PADrend.EventLoop.setBGColor(0,0,0,0);
	renderingContext.pushAndSetFBO(fbo);
	renderingContext.pushAndSetDepthBuffer(false, false, Rendering.Comparison.ALWAYS);
  renderingContext.pushAndSetBlending(blendingParams);
	renderingContext.pushAndSetShader( this.shader );
  shader.setUniform(renderingContext, 'scale', Rendering.Uniform.FLOAT, [this.scale()]);
};

/*! ---|> PPEffect  */
Effect.end @(override) ::= fn() {
	renderingContext.popShader();
	renderingContext.popBlending();
	renderingContext.popDepthBuffer();
	renderingContext.popFBO();
	Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0, 0, renderingContext.getWindowWidth(), renderingContext.getWindowHeight()),
								  [colorTexture], [new Geometry.Rect(0, 0, 1, 1)]);
	PADrend.EventLoop.setting_bgColor(oldColor);
};

//! ---|> PPEffect
Effect.getOptionPanel @(override) ::= fn(){
  var p=gui.createPanel(200,200,GUI.AUTO_MAXIMIZE|GUI.AUTO_LAYOUT);  
	p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "scale",
		GUI.RANGE : [ 0.0,1.0 ],
		GUI.RANGE_STEP_SIZE : 0.01,
		GUI.DATA_WRAPPER : this.scale
  }; 
  p++;
  return p;
};

return new Effect;

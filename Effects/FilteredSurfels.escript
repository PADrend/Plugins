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

Effect._constructor ::= fn(){

  this.fbo := new Rendering.FBO;
  
  this.depthTexture := Rendering.createDepthTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight());
  this.colorTexture := Rendering.createStdTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight(), true);
  this.colorTextureSurfels := Rendering.createHDRTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight(), true);
  this.filterTexture := Rendering.createColorTexture(Rendering.Texture.TEXTURE_1D, 256, 1, 1, Util.TypeConstant.FLOAT, 1, false);
    
  { // initialize gauss filter
    var ta = Rendering.createColorPixelAccessor(renderingContext, filterTexture);
    var sigma2 = 0.1.sqrt();
    var e = 2.71828182845904523536;
    for(var i=0; i<256; ++i) {
      var x = i/255;
      var w = x*x / (2*sigma2);
      ta.writeSingleValueFloat(i,0,e.pow(-w));
    }
  }
  

	// settings
	this.settings := {
		'depthOffset' : new Std.DataWrapper( 1 ),
	};
	this.presetManager := new (Std.module('LibGUIExt/PresetManager'))( PADrend.configCache, 'Effects.FilteredSurfels', settings );
  
  
	this.depthShader := Rendering.Shader.loadShader( getShaderFolder()+"SurfelDepth.sfn", getShaderFolder()+"SurfelDepth.sfn", Rendering.Shader.USE_UNIFORMS|Rendering.Shader.USE_GL);  
  
  this.composeShader := Rendering.Shader.loadShader(getShaderFolder()+"SurfelCompose.sfn", getShaderFolder()+"SurfelCompose.sfn", Rendering.Shader.USE_UNIFORMS|Rendering.Shader.USE_GL);
  composeShader.setUniform(renderingContext, 't_color', Rendering.Uniform.INT, [0]);
  composeShader.setUniform(renderingContext, 't_colorSurfel', Rendering.Uniform.INT, [1]);
  composeShader.setUniform(renderingContext, 't_depth', Rendering.Uniform.INT, [2]);

	var renderingShaderState = new MinSG.ShaderState;
	(renderingShaderState.getStateAttributeWrapper(MinSG.ShaderState.STATE_ATTR_SHADER_NAME))( "universal3_surfelsElliptic.shader" );
	renderingShaderState.recreateShader( PADrend.getSceneManager() );
	this.surfelShader := renderingShaderState.getShader();  
  surfelShader.setUniform(renderingContext, 't_filter', Rendering.Uniform.INT, [7]);
  surfelShader.setUniform(renderingContext, 'filtering', Rendering.Uniform.BOOL, [true]);
    
  this.blendingParams := new Rendering.BlendingParameters;
  blendingParams.enable();
  blendingParams.setBlendEquation(Rendering.BlendEquation.FUNC_ADD);
  blendingParams.setBlendFunc(Rendering.BlendFunc.ONE, Rendering.BlendFunc.ONE);
  blendingParams.setBlendFuncSrcRGB(Rendering.BlendFunc.SRC_ALPHA);
  
  this.surfelRenderer := void;


};

//! ---|> PPEffect
Effect.begin @(override) ::= fn(){  
  var scene = PADrend.getCurrentScene();
  var states = MinSG.collectStates(scene, MinSG.SurfelRendererFixedSize);
  if(states.count() == 0) {
    states = MinSG.collectStates(scene, MinSG.SurfelRendererBudget);
  }
  if(states.count() == 0) {
    surfelRenderer = void;
    return;
  }
  surfelRenderer = states.front();

  surfelRenderer.setDebugHideSurfels(true);
  surfelRenderer.setDeferredSurfels(true);

	renderingContext.pushAndSetFBO( this.fbo );  
  fbo.attachDepthTexture(renderingContext, depthTexture);
  fbo.attachColorTexture(renderingContext, colorTexture);
};

//! ---|> PPEffect
Effect.end @(override) ::= fn(){
  if(!surfelRenderer)
    return;
    
  surfelRenderer.setDebugHideSurfels(false);  
  surfelRenderer.setDeferredSurfels(false);
    
  // Render surfels depth only    
  depthShader.setUniform(renderingContext, 'depthOffset', Rendering.Uniform.FLOAT, [settings['depthOffset']()]);
	renderingContext.pushAndSetShader( this.depthShader );
  renderingContext.pushAndSetColorBuffer(false, false, false, false);  
	surfelRenderer.drawSurfels(frameContext);  
  renderingContext.popColorBuffer();
	renderingContext.popShader();    
  
  // Render surfel colors  
	var lightStates = MinSG.collectStates(PADrend.getRootNode(), MinSG.LightingState);
	foreach(lightStates as var lightState) {
		lightState.enableState(GLOBALS.frameContext);
	}
  
  fbo.attachColorTexture(renderingContext, colorTextureSurfels);  
	renderingContext.pushAndSetShader( this.surfelShader );
  renderingContext.pushAndSetBlending(blendingParams);
  renderingContext.pushAndSetDepthBuffer(true, false, Rendering.Comparison.LESS);
  renderingContext.clearColor(new Util.Color4f(0,0,0,0));
  renderingContext.pushAndSetTexture(7, filterTexture);
	surfelRenderer.drawSurfels(frameContext); 
  renderingContext.popDepthBuffer();
  renderingContext.popBlending();
  renderingContext.popTexture(7);
	renderingContext.popShader();    
  
	foreach(lightStates as var lightState) {
		lightState.disableState(GLOBALS.frameContext);
	}
  
  fbo.detachColorTexture(renderingContext);
  fbo.detachDepthTexture(renderingContext);
	renderingContext.popFBO();
  
  // combine rendered images
	renderingContext.pushAndSetShader( this.composeShader );	
  renderingContext.pushAndSetTexture(0, colorTexture);
  renderingContext.pushAndSetTexture(1, colorTextureSurfels);
  renderingContext.pushAndSetTexture(2, depthTexture);
  renderingContext.pushAndSetDepthBuffer(false, true, Rendering.Comparison.ALWAYS);
  Rendering.drawFullScreenRect(renderingContext);
  renderingContext.popDepthBuffer();
  renderingContext.popTexture(2);
  renderingContext.popTexture(1);
  renderingContext.popTexture(0);
	renderingContext.popShader();
  
};


//! ---|> PPEffect
Effect.getOptionPanel @(override) ::= fn(){
  var p=gui.createPanel(200,200,GUI.AUTO_MAXIMIZE|GUI.AUTO_LAYOUT);
  presetManager.createGUI( p );
  p++;
  p+='----';
  p++;
  p+={
    GUI.TYPE : GUI.TYPE_RANGE,
    GUI.LABEL : "Depth Offset (clip space)",
    GUI.RANGE : [ 0.0,1.0 ],
    GUI.RANGE_STEP_SIZE : 0.05,
    GUI.DATA_WRAPPER : settings['depthOffset']
  }; 
  p++;
  return p;
};

return new Effect;
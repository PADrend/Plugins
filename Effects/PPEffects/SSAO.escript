/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
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

Effect._constructor:=fn() {

  this.fbo:=new Rendering.FBO;
  //renderingContext.pushAndSetFBO(fbo);
  this.colorTexture_1:=Rendering.createHDRTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight(),true);
  fbo.attachColorTexture(renderingContext,colorTexture_1);
  
  this.depthTexture:=Rendering.createDepthTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight());
  fbo.attachDepthTexture(renderingContext,depthTexture);
  //renderingContext.popFBO();
  
  this.shader:=Rendering.Shader.loadShader(getShaderFolder()+"Default.vs",getShaderFolder()+"SSAO.fs");
  //renderingContext.pushAndSetShader(shader);
  shader.setUniform(renderingContext,'TUnit_1',Rendering.Uniform.INT,[0]) ;
  shader.setUniform(renderingContext,'TDepth',Rendering.Uniform.INT,[1]) ;
  shader.setUniform(renderingContext,'pixelSizeX',Rendering.Uniform.FLOAT,[1.0/renderingContext.getWindowWidth()]) ;
  shader.setUniform(renderingContext,'pixelSizeY',Rendering.Uniform.FLOAT,[1.0/renderingContext.getWindowHeight()]) ;
	//renderingContext.popShader();

	// settings
	this.settings := {
		'debugBlend' : new Std.DataWrapper( 0 ),
		'debugBorder' : new Std.DataWrapper( 0 ),
		'intensityExponent' : new Std.DataWrapper( 1.0 ),
		'intensityFactor' : new Std.DataWrapper( 2.0 ),
		'initialRadius' : new Std.DataWrapper( 4 ),
		'maxBrightness' : new Std.DataWrapper( 1 ),
		'numDirections' : new Std.DataWrapper( 5 ),
		'numSteps' : new Std.DataWrapper( 5 ),
		'radiusIncrease' : new Std.DataWrapper( 1.7 ),
		'fxaa' : new Std.DataWrapper(true ),
	};
	this.presetManager := new (Std.module('LibGUIExt/PresetManager'))( PADrend.configCache, 'Effects.SSAO', settings );

	// -------
	// last frame
  this.depthTexture_2:=Rendering.createDepthTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight());
  this.colorTexture_2:=Rendering.createHDRTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight(),true);

	this.renderPassInfo := new Map;

	// -------
	// ssaa
	this.shader2:= Rendering.Shader.createShader();
	shader2.attachVSFile(getShaderFolder()+"AA.sfn");
	shader2.attachFSFile(getShaderFolder()+"Fxaa3_8_mod.sfn");
	shader2.attachFSFile(getShaderFolder()+"AA.sfn");
	shader2.setUniform(renderingContext,'TUnit_1',Rendering.Uniform.INT,[0]);
	shader2.setUniform(renderingContext,'pixelSizeY',Rendering.Uniform.FLOAT,[1.0/renderingContext.getWindowHeight()]);
	shader2.setUniform(renderingContext,'pixelSizeX',Rendering.Uniform.FLOAT,[1.0/renderingContext.getWindowWidth()]);

	this.colorTexture_3 := Rendering.createHDRTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight(),true);
};

/*! ---|> PPEffect  */
Effect.begin @(override) := fn(){
	// swap texture1 and texture 2
	var t = depthTexture_2;
	depthTexture_2 = depthTexture;
	depthTexture = t;
	t = colorTexture_2;
	colorTexture_2 = colorTexture_1;
	colorTexture_1 = t;

	// ------
  renderingContext.pushAndSetFBO(fbo);
  fbo.attachColorTexture(renderingContext,colorTexture_1);
  fbo.attachDepthTexture(renderingContext,depthTexture);

  renderingContext.pushAndSetTexture(6, colorTexture_2, Rendering.TexUnitUsageParameter.GENERAL_PURPOSE);
  renderingContext.pushAndSetTexture(7, depthTexture_2, Rendering.TexUnitUsageParameter.GENERAL_PURPOSE);
  renderingContext.setGlobalUniform('lastColorBuffer',Rendering.Uniform.INT,[6]);
  renderingContext.setGlobalUniform('lastDepthBuffer',Rendering.Uniform.INT,[7]);

};
/*! ---|> PPEffect  */
Effect.end @(override) ::= fn(){

//	this.lastCamMatrix = renderingContext.getCameraMatrix().clone();
	renderingContext.popTexture(7);
	renderingContext.popTexture(6);

	// ----------

	// pass 1: Add SSAO
	renderingContext.pushAndSetShader(shader);
	var m = renderingContext.getMatrix_cameraToClipping().inverse();
	
	shader.setUniform(renderingContext,'inverseProjectionMatrix' , Rendering.Uniform.MATRIX_4X4F,[m]);
//	shader.setUniform(renderingContext,'projectionMatrix' , Rendering.Uniform.MATRIX_4X4F,[renderingContext.getMatrix_cameraToClipping()]);
	
	shader.setUniform(renderingContext,'debugBlend' , Rendering.Uniform.FLOAT,[settings['debugBlend']() ]);
	shader.setUniform(renderingContext,'debugBorder' , Rendering.Uniform.FLOAT,[settings['debugBorder']() ]);
	shader.setUniform(renderingContext,'initialRadius' , Rendering.Uniform.FLOAT,[settings['initialRadius']() ]);
	shader.setUniform(renderingContext,'intensityExponent' , Rendering.Uniform.FLOAT,[settings['intensityExponent']() ]);
	shader.setUniform(renderingContext,'intensityFactor' , Rendering.Uniform.FLOAT,[settings['intensityFactor']() ]);
	shader.setUniform(renderingContext,'maxBrightness' , Rendering.Uniform.FLOAT,[settings['maxBrightness']() ]);
	shader.setUniform(renderingContext,'numDirections' , Rendering.Uniform.INT,[settings['numDirections']() ]);
	shader.setUniform(renderingContext,'numSteps' , Rendering.Uniform.INT,[settings['numSteps']() ]);
	shader.setUniform(renderingContext,'radiusIncrease' , Rendering.Uniform.FLOAT,[settings['radiusIncrease']() ]);

	
	{	// haze \see Effects/InfiniteGround
		var p = Util.queryPlugin('Effects_InfiniteGround');
		if(p && p.enabled() && p.hazeEnabled()){
			shader.setUniform( renderingContext, 'hazeNear_cs', Rendering.Uniform.FLOAT, [p.hazeNear()] );
			shader.setUniform( renderingContext, 'hazeFar_cs', Rendering.Uniform.FLOAT, [p.hazeFar()]);
			var color = p.getHazeColor();
			shader.setUniform( renderingContext, 'hazeColor',  Rendering.Uniform.VEC3F,[ [color.r(),color.g(),color.b()] ]);
		}else{
			shader.setUniform( renderingContext, 'hazeNear_cs', Rendering.Uniform.FLOAT, [0] );
			shader.setUniform( renderingContext, 'hazeFar_cs', Rendering.Uniform.FLOAT, [0]);
		}
		
	}
		

		
	if( settings['fxaa']() ) {
		fbo.attachColorTexture(renderingContext,colorTexture_3);

		Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()) ,
								[this.colorTexture_1,depthTexture],[new Geometry.Rect(0,0,1,1),new Geometry.Rect(0,0,1,1)]);

		renderingContext.popShader();


		renderingContext.popFBO();
		
		// -----------------
		// pass 2: Add SSAA
		
		renderingContext.pushAndSetShader(shader2);
		Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()) ,
								[this.colorTexture_3,depthTexture],[new Geometry.Rect(0,0,1,1),new Geometry.Rect(0,0,1,1)]);
		renderingContext.popShader();
	} else {
		renderingContext.popFBO();
		Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()) ,
								[this.colorTexture_1,depthTexture],[new Geometry.Rect(0,0,1,1),new Geometry.Rect(0,0,1,1)]);

		renderingContext.popShader();
	
	}
//	out(".\n");
};

//! ---|> PPEffect
Effect.beginPass @(override) ::= fn(PADrend.RenderingPass pass){

//	out("<",pass.getId());


  var lastFrameData = this.renderPassInfo[pass.getId()];
  if(!lastFrameData){
    lastFrameData = new ExtObject;
    lastFrameData.lastProjectionMatrix := renderingContext.getMatrix_cameraToClipping();
    lastFrameData.sg_lastProjectionMatrixInverse := renderingContext.getMatrix_cameraToClipping().inverse();
    lastFrameData.lastCamMatrix := renderingContext.getMatrix_worldToCamera();
    	
    this.renderPassInfo[pass.getId()] = lastFrameData;
  }

//	var camera = PADrend.getActiveCamera();
	var camera = pass.getCamera();

//	out(lastFrameData);

    // ----
  renderingContext.setGlobalUniform('sg_lastProjectionMatrix',Rendering.Uniform.MATRIX_4X4F,[lastFrameData.lastProjectionMatrix]);
  renderingContext.setGlobalUniform('sg_lastProjectionMatrixInverse',Rendering.Uniform.MATRIX_4X4F,[lastFrameData.sg_lastProjectionMatrixInverse]);
  
  renderingContext.setGlobalUniform('lastCamMatrix',Rendering.Uniform.MATRIX_4X4F,[lastFrameData.lastCamMatrix.clone()]);
  renderingContext.setGlobalUniform('invLastCamMatrix',Rendering.Uniform.MATRIX_4X4F,[lastFrameData.lastCamMatrix.inverse()]);
    

	var viewport = camera.getViewport();
	
  renderingContext.setGlobalUniform('last_viewportScale',Rendering.Uniform.VEC2F,[
			new Geometry.Vec2(	viewport.getWidth()/renderingContext.getWindowWidth(),
							viewport.getHeight()/renderingContext.getWindowHeight())
	]);
  renderingContext.setGlobalUniform('last_viewportOffset',Rendering.Uniform.VEC2F,[
  		new Geometry.Vec2(	viewport.getX()/renderingContext.getWindowWidth(),
							viewport.getY()/renderingContext.getWindowHeight())
  ]);
    
//    uniform vec2 last_viewportScale = vec2(1,1);
//uniform vec2 last_viewportOffset = vec2(0,0);

	// ----------
	
  var sg_eyeToLastEye = camera.getWorldToLocalMatrix() * lastFrameData.lastCamMatrix;  // eye to world,  world to last eye
  lastFrameData.lastCamMatrix = camera.getWorldTransformationMatrix();

  renderingContext.setGlobalUniform('sg_eyeToLastEye',Rendering.Uniform.MATRIX_4X4F,[sg_eyeToLastEye]);
  
//  	lastFrameData.lastProjectionMatrix = renderingContext.getMatrix_cameraToClipping().clone();
	lastFrameData.lastProjectionMatrix = camera.getFrustum().getProjectionMatrix();
	lastFrameData.sg_lastProjectionMatrixInverse = lastFrameData.lastProjectionMatrix.inverse();

};
//! ---|> PPEffect
Effect.endPass @(override) ::= fn(PADrend.RenderingPass pass){
//	out(">");

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
		GUI.LABEL : "numDirections",
		GUI.RANGE : [ 1.0,12.0 ],
		GUI.RANGE_STEP_SIZE : 1,
		GUI.DATA_WRAPPER : settings['numDirections']
    }; 
    p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "numSteps",
		GUI.RANGE : [ 1.0,15.0 ],
		GUI.RANGE_STEP_SIZE : 1,
		GUI.DATA_WRAPPER : settings['numSteps']
    }; 
    p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "radiusIncrease",
		GUI.RANGE : [ 1.0,4.0 ],
		GUI.RANGE_STEP_SIZE : 0.1,
		GUI.DATA_WRAPPER : settings['radiusIncrease']
    };
    p++;   
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "initialRadius",
		GUI.RANGE : [ 0.0,4.0 ],
		GUI.RANGE_STEP_SIZE : 0.1,
		GUI.DATA_WRAPPER : settings['initialRadius']
    };
    p++;
	p+='----';
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "maxBrightness",
		GUI.RANGE : [ 1.0,2.0 ],
		GUI.RANGE_STEP_SIZE : 0.1,
		GUI.DATA_WRAPPER : settings['maxBrightness']
    };
    p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "intensityExponent",
		GUI.RANGE : [ 0.0,3.0 ],
		GUI.RANGE_STEP_SIZE : 0.1,
		GUI.DATA_WRAPPER : settings['intensityExponent']
    };
    p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "intensityFactor",
		GUI.RANGE : [ 0.0,3.0 ],
		GUI.RANGE_STEP_SIZE : 0.1,
		GUI.DATA_WRAPPER : settings['intensityFactor']
    };
	p++;
	p+='----';
	p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "debugBlend",
		GUI.RANGE : [ 0.0,1.0 ],
		GUI.RANGE_STEP_SIZE : 0.1,
		GUI.DATA_WRAPPER : settings['debugBlend']
    };
    p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "debugBorder",
		GUI.RANGE : [ 0.0,1.0 ],
		GUI.RANGE_STEP_SIZE : 0.1,
		GUI.DATA_WRAPPER : settings['debugBorder']
    };
    p++;    
    p+='----';
    p++;    
    p+={
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "fxaa",
		GUI.DATA_WRAPPER : settings['fxaa']
    };
    p++;
    return p;
};

return new Effect;

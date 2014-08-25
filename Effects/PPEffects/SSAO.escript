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


var Effect = new Type( Std.require('Effects/PPEffect') );

Effect._constructor:=fn(){

    this.fbo:=new Rendering.FBO;
    renderingContext.pushAndSetFBO(fbo);
    this.colorTexture_1:=Rendering.createHDRTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight(),true);
    fbo.attachColorTexture(renderingContext,colorTexture_1);
    
    this.depthTexture:=Rendering.createDepthTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight());
    fbo.attachDepthTexture(renderingContext,depthTexture);
    out(fbo.getStatusMessage(renderingContext),"\n");
    renderingContext.popFBO();
    
    this.shader:=Rendering.Shader.loadShader(getShaderFolder()+"Simple_GL.vs",getShaderFolder()+"SSAO.fs");
	renderingContext.pushAndSetShader(shader);
    shader.setUniform(renderingContext,'TUnit_1',Rendering.Uniform.INT,[0]) ;
    shader.setUniform(renderingContext,'TDepth',Rendering.Uniform.INT,[1]) ;
    shader.setUniform(renderingContext,'pixelSizeX',Rendering.Uniform.FLOAT,[1.0/renderingContext.getWindowWidth()]) ;
    shader.setUniform(renderingContext,'pixelSizeY',Rendering.Uniform.FLOAT,[1.0/renderingContext.getWindowHeight()]) ;

	// settings
	this.settings := {
		'debugBorder' : DataWrapper.createFromValue( shader.getUniform('debugBorder').getData()[0] ),
		'debugBlend' : DataWrapper.createFromValue( shader.getUniform('debugBlend').getData()[0] ),
		'distancePow' : DataWrapper.createFromValue( shader.getUniform('distancePow').getData()[0] ).setOptions([1.0]),
		'intensityFactor' : DataWrapper.createFromValue( shader.getUniform('intensityFactor').getData()[0] ),
		'intensityOffset' : DataWrapper.createFromValue( shader.getUniform('intensityOffset').getData()[0] ),
		'maxBrightness' : DataWrapper.createFromValue( shader.getUniform('maxBrightness').getData()[0] ),
		'minPlaneDistance' : DataWrapper.createFromValue( shader.getUniform('minPlaneDistance').getData()[0] ),
		'numSamples' : DataWrapper.createFromValue( shader.getUniform('numSamples').getData()[0] ),
		'radiusIncrease' : DataWrapper.createFromValue( shader.getUniform('radiusIncrease').getData()[0] ),
		'samplingRadius' : DataWrapper.createFromValue( shader.getUniform('samplingRadius').getData()[0] ),
		'useNoise' : DataWrapper.createFromValue( shader.getUniform('useNoise').getData()[0] ),
	};

	this.presetManager := new PresetManager( PADrend.configCache, 'Effects.SSAO', settings );

	renderingContext.popShader();
};
/*! ---|> PPEffect  */
Effect.begin @(override) := fn(){
    renderingContext.pushAndSetFBO(fbo);
};
/*! ---|> PPEffect  */
Effect.end @(override) :=fn(){

	// pass 1: Calculate AO
	renderingContext.pushAndSetShader(shader);
	var m = renderingContext.getMatrix_cameraToClip().inverse();
	
	shader.setUniform(renderingContext,'inverseProjectionMatrix' , Rendering.Uniform.MATRIX_4X4F,[m]);
	shader.setUniform(renderingContext,'projectionMatrix' , Rendering.Uniform.MATRIX_4X4F,[renderingContext.getMatrix_cameraToClip()]);
	
	shader.setUniform(renderingContext,'distancePow' , Rendering.Uniform.FLOAT,[settings['distancePow']() ]);
	shader.setUniform(renderingContext,'samplingRadius' , Rendering.Uniform.FLOAT,[settings['samplingRadius']() ]);
	shader.setUniform(renderingContext,'intensityOffset' , Rendering.Uniform.FLOAT,[settings['intensityOffset']() ]);
	shader.setUniform(renderingContext,'intensityFactor' , Rendering.Uniform.FLOAT,[settings['intensityFactor']() ]);
	shader.setUniform(renderingContext,'debugBlend' , Rendering.Uniform.FLOAT,[settings['debugBlend']() ]);
	shader.setUniform(renderingContext,'debugBorder' , Rendering.Uniform.FLOAT,[settings['debugBorder']() ]);
	shader.setUniform(renderingContext,'useNoise' , Rendering.Uniform.BOOL,[settings['useNoise']() ]);
	shader.setUniform(renderingContext,'minPlaneDistance' , Rendering.Uniform.FLOAT,[settings['minPlaneDistance']() ]);
	shader.setUniform(renderingContext,'maxBrightness' , Rendering.Uniform.FLOAT,[settings['maxBrightness']() ]);
	shader.setUniform(renderingContext,'radiusIncrease' , Rendering.Uniform.FLOAT,[settings['radiusIncrease']() ]);
	shader.setUniform(renderingContext,'numSamples' , Rendering.Uniform.INT,[settings['numSamples']() ]);

    renderingContext.popFBO();
    

    Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()) ,
                            [this.colorTexture_1,depthTexture],[new Geometry.Rect(0,0,1,1),new Geometry.Rect(0,0,1,1)]);

	renderingContext.popShader();


	
};
/*! ---|> PPEffect  */
Effect.getOptionPanel:=fn(){
    var p=gui.createPanel(200,200,GUI.AUTO_MAXIMIZE|GUI.AUTO_LAYOUT);
    presetManager.createGUI( p );

    p++;
    p+='----';
    p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "samplingRadius",
		GUI.RANGE : [ 0.001,0.01 ],
		GUI.DATA_WRAPPER : settings['samplingRadius'],
    };
    p++;    
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "radiusIncrease",
		GUI.RANGE : [ 1.0,1.2 ],
		GUI.DATA_WRAPPER : settings['radiusIncrease']
    };
    p++;   
     p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "distancePow",
		GUI.RANGE : [ 0.0,2.0 ],
		GUI.DATA_WRAPPER : settings['distancePow']
    };
    p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "intensityOffset",
		GUI.RANGE : [ 0.0,1.0 ],
		GUI.DATA_WRAPPER : settings['intensityOffset']
    };
	p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "intensityFactor",
		GUI.RANGE : [ 0.5,3.0 ],
		GUI.DATA_WRAPPER : settings['intensityFactor']
    };
    p++;      
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "minPlaneDistance",
		GUI.RANGE : [ 0.0,1.0 ],
		GUI.DATA_WRAPPER : settings['minPlaneDistance']
    };    
    p++;    
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "numSamples",
		GUI.RANGE : [ 1.0,64.0 ],
		GUI.RANGE_STEPS : 63,
		GUI.DATA_WRAPPER : settings['numSamples']
    };    
    p++;   
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "maxBrightness",
		GUI.RANGE : [ 1.0,10.0 ],
		GUI.DATA_WRAPPER : settings['maxBrightness']
    };    
    p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "debugBlend",
		GUI.RANGE : [ 0.0,1.0 ],
		GUI.DATA_WRAPPER : settings['debugBlend']
    };
    p++;      
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "debugBorder",
		GUI.RANGE : [ 0.0,1.0 ],
		GUI.DATA_WRAPPER : settings['debugBorder']
    };    
    p++;      
    p+={
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "useNoise",
		GUI.DATA_WRAPPER : settings['useNoise']
    };
    p++;    
    return p;
};

return new Effect;

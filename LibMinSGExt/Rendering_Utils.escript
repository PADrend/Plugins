/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	 [LibMinSGExt] Rendering_Utils.escript
 **
 **  Rendering helper functions.
 **/

//----------------------
// TextureProcessor
/*! A TextureProcessor converts some input textures into some output textures
	using a shader. It is just a wrapper for some simple fbo handling, but
	can simplify your code.
	\code
	(new TextureProcessor)
		.setInputTextures([colorInput1,colorInput2])
		.setOutputTexture(resultingTexture)
		.setOutputDepthTexture( myDepthTexture )
		.setShader(myPPEffect)
		.execute();
	
	// or
	var tp = (new TextureProcessor)
		.setInputTextures([colorInput1,colorInput2])
		.setOutputTexture(resultingTexture)
		.setOutputDepthTexture( myDepthTexture );
	tp.begin();
	// render something
	tp.end(); 
	// resultingTexture & myDepthTexture contain the resulting image.
*/
Rendering.TextureProcessor := new Type();
var TextureProcessor = Rendering.TextureProcessor;
TextureProcessor._printableName @(override) := $TextureProcessor;
TextureProcessor.outputDepthTexture @(private) := void;
TextureProcessor.fbo @(private) := void;
TextureProcessor.inputTextures @(private,init) := Array;
TextureProcessor.outputTextures @(private,init) := Array;
TextureProcessor.shader @(private) := void;
TextureProcessor.width @(private) := 0;
TextureProcessor.height @(private) := 0;

TextureProcessor.getDepthTexture	::= fn(){	return outputDepthTexture;	};
TextureProcessor.getInputTextures	::= fn(){	return inputTextures.clone();	};
TextureProcessor.getOutputTextures	::= fn(){	return outputTextures.clone();	};
TextureProcessor.getResolution		::= fn(){	return new Geometry.Vec2(width,height);	};
TextureProcessor.getShader 			::= fn(){	return shader;	};

TextureProcessor.setShader ::= fn([Rendering.Shader,void] _shader){
	shader = _shader;
	return this;
};

TextureProcessor.setInputTexture ::= fn(Rendering.Texture _inputTexture){
	inputTextures = [_inputTexture];
	return this;
};
TextureProcessor.setInputTextures ::= fn(Array _inputTextures){
	inputTextures = _inputTextures.clone();
	return this;
};
TextureProcessor.setOutputTexture ::= fn(Rendering.Texture _outputTexture){
	outputTextures = [_outputTexture];
	return this;
};
TextureProcessor.setOutputTextures ::= fn(Array _outputTextures){
	outputTextures = _outputTextures.clone();
	return this;
};
TextureProcessor.setOutputDepthTexture ::= fn([Rendering.Texture,void] _outputDepthTexture){
	outputDepthTexture = _outputDepthTexture;
	return this;
};
/*! Bind the textures, enable the fbo and the shader, set the viewport and scissor.
	\note Normally, don't use begin() and end() but just call execute()
	\note end() has to be called after begin() -- if no exception occured. */
TextureProcessor.begin ::= fn(){
	if(outputTextures.empty()){
		throw "No output texture defined!";
	}
	if(!fbo)
		fbo = new Rendering.FBO;
	
	renderingContext.pushAndSetFBO(fbo);
	foreach(outputTextures as var index,var t)
		fbo.attachColorTexture(renderingContext,t,index);
	if(outputDepthTexture)
		fbo.attachDepthTexture(renderingContext,outputDepthTexture);
//	out(fbo.getStatusMessage(renderingContext),"\n");
	if(shader){
		try{
			renderingContext.pushAndSetShader(shader);
		}catch(e){
			renderingContext.popFBO();
			fbo = void; // clear all attachments
			throw e;
		}
	}


	width = outputTextures.front().getWidth();
	height = outputTextures.front().getHeight();
	renderingContext.pushAndSetScissor(new Rendering.ScissorParameters(new Geometry.Rect(0,0,width,height)));
	renderingContext.pushViewport();
	renderingContext.setViewport(0,0,width,height);
	return this;
};

//! Render the input textures into the output textures using a shader.
TextureProcessor.execute ::= fn(){
	begin();
	var inputRects = [];
	foreach(inputTextures as var t)
		inputRects += new Geometry.Rect(0,0,1,1);
	Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,width,height),
					inputTextures,inputRects);
	end();
	return this;
};

//! \note Call after begin()!
TextureProcessor.end ::= fn(){
	renderingContext.popScissor();
	renderingContext.popViewport();
	if(outputDepthTexture)
		fbo.detachDepthTexture(renderingContext);
	foreach(outputTextures as var index,var t)
		fbo.detachColorTexture(renderingContext,index);

	if(shader){
		renderingContext.popShader();
	}
	renderingContext.popFBO();
	return this;
};
//------------------------------------

//! Show the given texture on the sceen for the given time and swap the frame buffer.
Rendering.showDebugTexture := fn(Rendering.Texture t, time = 0.5){
	renderingContext.pushAndSetScissor(new Rendering.ScissorParameters(new Geometry.Rect(0,0,t.getWidth(),t.getHeight())));
	renderingContext.pushViewport();
	renderingContext.setViewport(0,0,t.getWidth(),t.getHeight());

	Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,t.getWidth(),t.getHeight()) ,
							[t],[new Geometry.Rect(0,0,1,1)]);
	renderingContext.popScissor();
	renderingContext.popViewport();
	
	PADrend.SystemUI.swapBuffers();
	for(var i=clock()+time;clock()<i;);
};

//------------------------------------

Rendering.Shader._setUniform ::= Rendering.Shader.setUniform;

/*! Passes all additional parameters to the uniform's constructor. 
	Allows:
		shader.setUniform(renderingContext,'m1',Rendering.Uniform.FLOAT,[m1]);
	instead of:
		shader.setUniform(renderingContext, new Rendering.Uniform('m1',Rendering.Uniform.FLOAT,[m1]) );	*/
Rendering.Shader.setUniform ::= fn(rc,uniformOrName,params...){
	if(uniformOrName---|>Rendering.Uniform){
		return this._setUniform(rc,uniformOrName,params...);
	}else{
		var type = params.popFront();
		var values = params.popFront();
		return this._setUniform(rc,new Rendering.Uniform(uniformOrName,type,values),params...);
	}
};

// --------------------------------------

Rendering.RenderingContext._setGlobalUniform ::= Rendering.RenderingContext.setGlobalUniform;

/*! Passes all parameters to the uniform's constructor. 
	Allows:
		renderingContext.setGlobalUniform('m1',Rendering.Uniform.FLOAT,[m1]);
	instead of:
		renderingContext.setGlobalUniform(new Rendering.Uniform('m1',Rendering.Uniform.FLOAT,[m1]) );	*/
Rendering.RenderingContext.setGlobalUniform ::= fn(params...){
	return this._setGlobalUniform(new Rendering.Uniform(params...));
};

//-------------------------------------


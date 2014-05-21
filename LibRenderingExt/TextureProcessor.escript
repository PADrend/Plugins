/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

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
var T = new Type();
T._printableName @(override) := $TextureProcessor;
T.outputDepthTexture @(private) := void;
T.fbo @(private) := void;
T.inputTextures @(private,init) := Array;
T.outputTextures @(private,init) := Array;
T.shader @(private) := void;
T.width @(private) := 0;
T.height @(private) := 0;

T.getDepthTexture	::= fn(){	return outputDepthTexture;	};
T.getInputTextures	::= fn(){	return inputTextures.clone();	};
T.getOutputTextures	::= fn(){	return outputTextures.clone();	};
T.getResolution		::= fn(){	return new Geometry.Vec2(width,height);	};
T.getShader 			::= fn(){	return shader;	};

T.setShader ::= fn([Rendering.Shader,void] _shader){
	shader = _shader;
	return this;
};

T.setInputTexture ::= fn(Rendering.Texture _inputTexture){
	inputTextures = [_inputTexture];
	return this;
};
T.setInputTextures ::= fn(Array _inputTextures){
	inputTextures = _inputTextures.clone();
	return this;
};
T.setOutputTexture ::= fn(Rendering.Texture _outputTexture){
	outputTextures = [_outputTexture];
	return this;
};
T.setOutputTextures ::= fn(Array _outputTextures){
	outputTextures = _outputTextures.clone();
	return this;
};
T.setOutputDepthTexture ::= fn([Rendering.Texture,void] _outputDepthTexture){
	outputDepthTexture = _outputDepthTexture;
	return this;
};
/*! Bind the textures, enable the fbo and the shader, set the viewport and scissor.
	\note Normally, don't use begin() and end() but just call execute()
	\note end() has to be called after begin() -- if no exception occured. */
T.begin ::= fn(){
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

	fbo.setDrawBuffers(outputTextures.count());

	//out(fbo.getStatusMessage(renderingContext),"\n");
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
T.execute ::= fn(){
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
T.end ::= fn(){
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

return T;

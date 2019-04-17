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
	\note To bind a specific layer or level of a texture as output texture,
			use [Texture,level, layer] as texture parameter.
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
T.outputTextures @(private,init) := Array; // [  [array,level,layer]* ]
T.shader @(private) := void;
T.width @(private) := 0;
T.height @(private) := 0;

T.getDepthTexture	::= fn(){	return this.outputDepthTexture;	};
T.getInputTextures	::= fn(){	return this.inputTextures.clone();	};
T.getOutputTextures	::= fn(){	return this.outputTextures.clone();	};
T.getResolution		::= fn(){	return new Geometry.Vec2(this.width,this.height);	};
T.getShader 		::= fn(){	return this.shader;	};

T.setShader ::= fn([Rendering.Shader,void] _shader){
	this.shader = _shader;
	return this;
};
T.setInputTexture ::= fn(Rendering.Texture _inputTexture){
	this.inputTextures = [_inputTexture];
	return this;
};
T.setInputTextures ::= fn(Array _inputTextures){
	this.inputTextures = _inputTextures.clone();
	return this;
};
T.addOutputTexture ::= fn(Rendering.Texture texture, Number level=0, Number layer=0){
	this.outputTextures += [texture,level,layer];
	return this;
};

T.setOutputTexture ::= fn( p... ){
	this.outputTextures.clear();
	this.addOutputTexture( p... );
	return this;
};
T.setOutputTextures ::= fn(Array _outputTextures){
	this.outputTextures.clear();
	foreach( _outputTextures as var entry)
		this.addOutputTexture(  (entry.isA(Array) ? entry :  [entry])... );
	return this;
};
T.setOutputDepthTexture ::= fn([Rendering.Texture,void] _outputDepthTexture){
	this.outputDepthTexture = _outputDepthTexture;
	return this;
};
/*! Bind the textures, enable the fbo and the shader, set the viewport and scissor.
	\note Normally, don't use begin() and end() but just call execute()
	\note end() has to be called after begin() -- if no exception occured. */
T.begin ::= fn(){
	if(this.outputTextures.empty())
		Runtime.exception( "No output texture defined!");

	if(!this.fbo)
		this.fbo = new Rendering.FBO;

	GLOBALS.renderingContext.pushAndSetFBO(this.fbo);
	foreach(this.outputTextures as var index,var textureEntry){
		this.fbo.attachColorTexture(GLOBALS.renderingContext,textureEntry[0],index,textureEntry.get(1,0),textureEntry.get(2,0));

	}
	if(this.outputDepthTexture)
		this.fbo.attachDepthTexture(GLOBALS.renderingContext,this.outputDepthTexture);

	this.fbo.setDrawBuffers(renderingContext,outputTextures.count());
// 	out(fbo.getStatusMessage(GLOBALS.renderingContext),"\n");
	if(this.shader){
		try{
			GLOBALS.renderingContext.pushAndSetShader(shader);
//			 outln( __FILE__,":",__LINE__); Rendering.checkGLError();
		}catch(e){
			GLOBALS.renderingContext.popFBO();
			this.fbo = void; // clear all attachments
			throw e;
		}
	}

	this.width = outputTextures.front()[0].getWidth();
	this.height = outputTextures.front()[0].getHeight();
	GLOBALS.renderingContext.pushAndSetScissor(new Rendering.ScissorParameters(new Geometry.Rect(0,0,this.width,this.height)));
	GLOBALS.renderingContext.pushViewport();
	GLOBALS.renderingContext.setViewport(0,0,this.width,this.height);
	return this;
};

//! Render the input textures into the output textures using a shader.
T.execute ::= fn(){
	this.begin();
	
	if(this.inputTextures.empty()){
		renderingContext.pushAndSetScissor(new Rendering.ScissorParameters(new Geometry.Rect(0,0,this.width,this.height)));
		renderingContext.pushViewport();
		renderingContext.setViewport(0,0,this.width,this.height);

		Rendering.drawFullScreenRect( renderingContext );
								
		renderingContext.popViewport();
		renderingContext.popScissor();
	}else{
		var inputRects = [];
		foreach(this.inputTextures as var t)
			inputRects += new Geometry.Rect(0,0,1,1);
		Rendering.drawTextureToScreen(GLOBALS.renderingContext,new Geometry.Rect(0,0,this.width,this.height),
						this.inputTextures,inputRects);
	}
	
	this.end();
	return this;
};

//! \note Call after begin()!
T.end ::= fn(){
	GLOBALS.renderingContext.popScissor();
	GLOBALS.renderingContext.popViewport();
	if(this.outputDepthTexture)
		this.fbo.detachDepthTexture(GLOBALS.renderingContext);
	foreach(this.outputTextures as var index,var t)
		this.fbo.detachColorTexture(GLOBALS.renderingContext,index);

	if(this.shader)
		GLOBALS.renderingContext.popShader();
	GLOBALS.renderingContext.popFBO();
	return this;
};

return T;

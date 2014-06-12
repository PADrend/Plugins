/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Jan Krems
 * Copyright (C) 2010-2013 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

 /*! Helper type for simple post-processing effects.
	\deprecated Do not use for new effects! Directly inherit from PPEffect instead.
*/
var SimplePPEffect = new Type( Std.require('Effects/PPEffect') );
SimplePPEffect._constructor::=fn(Rendering.Shader shader){

	this.fbo := new Rendering.FBO;
	this.color := void;
	this.depth := void;
	this.noise := void;
	this.numbers := void; // really?? this is ugly!

	this.viewport := void;
	this.shader := shader;

	this.border := 1.0;
};

//! ---o
SimplePPEffect.applyUniforms ::= fn(){
};

SimplePPEffect.beginPass @(override) ::= fn(PADrend.RenderingPass pass){
	
	this.viewport = pass.getCamera().getViewport();
	pass.getCamera().setViewport(new Geometry.Rect(0,0,viewport.width(),viewport.height()));
	
	if(noise === true){
		noise = Rendering.createNoiseTexture(viewport.width(), viewport.height(),true);
	}

	if( !color || viewport.width() != color.getWidth() || viewport.height() != color.getHeight() ){
		color = Rendering.createStdTexture(viewport.width(), viewport.height(),true);
		depth = Rendering.createDepthTexture(viewport.width(), viewport.height());
	}
	
	renderingContext.pushAndSetFBO(fbo);
	fbo.attachColorTexture(renderingContext,color);
	fbo.attachDepthTexture(renderingContext,depth);
	
};

SimplePPEffect.endPass @(override) ::= fn(PADrend.RenderingPass pass){

	fbo.detachColorTexture(renderingContext);
	fbo.detachDepthTexture(renderingContext);
	renderingContext.popFBO();
	
	pass.getCamera().setViewport(viewport);
	frameContext.setCamera(pass.getCamera());
	
	renderingContext.pushAndSetShader(shader);
	
	shader.setUniform(renderingContext,"color", Rendering.Uniform.INT, [0], false);
	shader.setUniform(renderingContext,"depth", Rendering.Uniform.INT, [1], false);
	shader.setUniform(renderingContext,"noise", Rendering.Uniform.INT, [2], false);
	shader.setUniform(renderingContext,"numbers", Rendering.Uniform.INT, [3], false);
	shader.setUniform(renderingContext,"imageSize", Rendering.Uniform.VEC2I, [ [viewport.width(), viewport.height()] ], false);
	
	shader.setUniform(renderingContext,"border", Rendering.Uniform.FLOAT, [border], false);
	this.applyUniforms();
	
	renderingContext.pushAndSetTexture(0, color);
	renderingContext.pushAndSetTexture(1, depth);
	if(noise)
		renderingContext.pushAndSetTexture(2, noise);
	if(numbers)
		renderingContext.pushAndSetTexture(3, numbers);
	
	renderingContext.pushAndSetDepthBuffer(true, true, Rendering.Comparison.ALWAYS);
	Rendering.drawFullScreenRect(renderingContext);
	renderingContext.popDepthBuffer();
	
	renderingContext.popTexture(0);
	renderingContext.popTexture(1);
	if(noise)
		renderingContext.popTexture(2);
	if(numbers)
		renderingContext.popTexture(3);
	
	renderingContext.popShader();
};

SimplePPEffect.getOptionPanel  @(override) ::= fn(){
	var p = gui.createPanel(400,200,GUI.AUTO_MAXIMIZE|GUI.AUTO_LAYOUT);
	p += "*Global*";
    p++;
    p += {GUI.LABEL:"border", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,1], GUI.RANGE_STEPS:100, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$border};
	p++;
	addOptions(p);
	return p;
};


//! ---o
SimplePPEffect.addOptions ::= fn(panel){
};

return SimplePPEffect;

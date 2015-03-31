/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var Effect = new Type( Std.module('Effects/PPEffect') );

Effect._constructor ::= fn(){

    this.fbo := new Rendering.FBO;

    this.colorTexture_1 := Rendering.createHDRTexture( renderingContext.getWindowWidth(),renderingContext.getWindowHeight(),true);
    fbo.attachColorTexture(renderingContext, this.colorTexture_1);
    
    this.depthTexture := Rendering.createDepthTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight());
    fbo.attachDepthTexture(renderingContext,depthTexture);
    
    outln( fbo.getStatusMessage(renderingContext) );

	this.shader := Rendering.Shader.loadShader( getShaderFolder()+"Simple_130.vs", getShaderFolder()+"Example_Green.fs", Rendering.Shader.USE_UNIFORMS);

};

//! ---|> PPEffect
Effect.begin @(override) ::= fn(){
	renderingContext.pushAndSetFBO( this.fbo );
  
};
//! ---|> PPEffect
Effect.end @(override) ::= fn(){
	renderingContext.popFBO();
	renderingContext.pushAndSetShader( this.shader );
	
	shader.setUniform(renderingContext,"colorTexture", Rendering.Uniform.INT, [0]);

	
	Rendering.drawTextureToScreen(renderingContext, new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()),
							  [this.colorTexture_1,this.depthTexture],[new Geometry.Rect(0,0,1,1),new Geometry.Rect(0,0,1,1)]);
	
	renderingContext.popShader();
};


//! ---|> PPEffect
Effect.getOptionPanel @(override) ::= fn(){
    return [
			" This is a simple Example to show how to create PP effects!",
			GUI.NEXT_ROW,
			GUI.H_DELIMITER,
			GUI.NEXT_ROW
	];
};

return new Effect;

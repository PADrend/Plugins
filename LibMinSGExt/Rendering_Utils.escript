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

//------------------------------------

//! Show the given texture on the sceen for the given time and swap the frame buffer.
Rendering.showDebugTexture := fn(Rendering.Texture t, time = 0.5){
	
	if( t.getTextureType()!=Rendering.Texture.TEXTURE_2D ){
		var b = Rendering.createBitmapFromTexture( renderingContext, t );
		t = Rendering.createTextureFromBitmap( b );
	}
	
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


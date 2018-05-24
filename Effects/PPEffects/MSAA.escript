/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var Effect = new Type( Std.module('Effects/PPEffect') );

Effect._constructor:=fn(){
	this.width:=renderingContext.getWindowWidth()*1.0;
	this.height:=renderingContext.getWindowHeight()*1.0;
	
	this.fbo:=new Rendering.FBO;
	renderingContext.pushAndSetFBO(fbo);
	
	this.colorTexture_1:=Rendering.createMultisampleTexture(width,height,true);	
	fbo.attachColorTexture(renderingContext,colorTexture_1);
	
	this.depthTexture:=Rendering.createMultisampleDepthTexture(width,height);	
	fbo.attachDepthTexture(renderingContext,depthTexture);
	
	out(fbo.getStatusMessage(renderingContext),"\n");
	renderingContext.popFBO();
	Rendering.checkGLError();
};
/*! ---|> PPEffect  */
Effect.begin:=fn(){
	renderingContext.pushAndSetFBO(fbo);
};
/*! ---|> PPEffect  */
Effect.end:=fn(){
	renderingContext.popFBO();
	var screenRect = new Geometry.Rect(0,0,width,height);
	this.fbo.blitToScreen(renderingContext, screenRect, screenRect);
};

return new Effect;

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
var Effect = new Type( Std.require('Effects/PPEffect') );

Effect._constructor ::= fn() {
	this.fbo := new Rendering.FBO();
	renderingContext.pushAndSetFBO(fbo);
	
	this.colorTexture := Rendering.createStdTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight(), false);
	fbo.attachColorTexture(renderingContext,colorTexture);
	
	this.depthTexture := Rendering.createDepthTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight());
	fbo.attachDepthTexture(renderingContext,depthTexture);
	
	out(fbo.getStatusMessage(renderingContext), "\n");
	renderingContext.popFBO();
	this.srt:=false;
};

/*! ---|> PPEffect  */
Effect.begin @(override) ::= fn() {
	
	renderingContext.pushAndSetFBO(fbo);
	var newSRT=PADrend.getDolly().getRelTransformationSRT();
	if( this.srt == newSRT)
		PADrend.EventLoop.doClearScreen = false;
	else
		srt=newSRT;
};

/*! ---|> PPEffect  */
Effect.end @(override) ::= fn() {
	PADrend.EventLoop.doClearScreen = true;
	
	renderingContext.popFBO();
	Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0, 0, renderingContext.getWindowWidth(), renderingContext.getWindowHeight()),
								  [colorTexture], [new Geometry.Rect(0, 0, 1, 1)]);
};

return new Effect;

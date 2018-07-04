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
var SimplePPEffect2 = new Type( Std.module('Effects/PPEffect') );
SimplePPEffect2._constructor ::= fn() {
	this.fbo := new Rendering.FBO;
	
	this.colorTexture := Rendering.createStdTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight(), true);
	this.depthTexture := Rendering.createDepthTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight());
	
	fbo.attachColorTexture(renderingContext, colorTexture);
	fbo.attachDepthTexture(renderingContext, depthTexture);
	//outln(fbo.getStatusMessage(renderingContext));
	Rendering.checkGLError();
};

SimplePPEffect2.drawTexture ::= fn(Rendering.Texture texture) {	
	Rendering.drawTextureToScreen(renderingContext, renderingContext.getWindowClientArea(), [texture], [new Geometry.Rect(0, 0, 1, 1)]);
};


return SimplePPEffect2;

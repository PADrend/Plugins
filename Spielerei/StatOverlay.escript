/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Spielerei/StatOverlayPlugin.escript
 ** 2009-11 Urlaubsprojekt...
 **/
GLOBALS.StatOverlayPlugin:= new Plugin({
			Plugin.NAME	: "Spielerei_StatOverlay",
			Plugin.VERSION : 0.1,
			Plugin.DESCRIPTION : "Show statistics overlay",
			Plugin.AUTHORS : "Claudius",
			Plugin.OWNER : "All"
});

StatOverlayPlugin.init @(override) := fn(){
     { // Register ExtensionPointHandler:
		registerExtension('PADrend_Init',this->fn(){
			gui.register('Spielerei.statOverlay',[
				"*StatOverlay mode*",
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "enable",
					GUI.ON_CLICK : this->fn() {
						enabled=true;
						lastTime=clock();
						out(" EXPERIMENTAL!!!! \n");
					}
				},
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "disable",
					GUI.ON_CLICK : this->fn() {
						enabled=false;
					}
				},
				'----'
			]);
		});
        registerExtension('PADrend_AfterRendering',this->this.ex_AfterRendering);
    }
	this.texture:=void;
	this.enabled:=false;
	this.pos:=0;
	this.xRes:=0;
	this.yRes:=0;
	this.lastTime:=false;

	this.bars:={
		PADrend.frameStatistics.getFrameDurationCounter() : {
			'range' : 500,
			'color' : new Util.Color4f(2.0,0.0,0.0,1.5)
		},
		PADrend.frameStatistics.getTrianglesCounter() : {
			'range' : 10000000,
			'color' : new Util.Color4f(0.0,2.0,0.0,1.5)
		}
	};

	return true;
};


/**
 * [ext:PADrend_AfterFrame]
 */
StatOverlayPlugin.ex_AfterRendering:=fn(...){
	if(!enabled)
		return;

	if(!texture){
		xRes=renderingContext.getWindowWidth();
		yRes=renderingContext.getWindowHeight();
		texture = Rendering.createStdTexture(xRes,yRes,true);
		texture.allocateLocalData();
	}

	var duration=lastTime ? clock()-lastTime : 0;
	lastTime=clock();

	var pixels = Rendering.createDepthPixelAccessor(renderingContext, texture);
	if(!pixels){
		out("No pixel access!\n");
		return;
	}

	foreach( bars as var index,var params){
		var value=PADrend.frameStatistics.getValue( index );

		value=[ (yRes/params['range'])* value ,yRes-2 ].min(); // normalize
		var oldColor=pixels.readColor4f(pos,value-1) ;
//		pixels.writeColor(pos,value-1,oldColor*0.5);

		oldColor=pixels.readColor4f(pos,value) ;
		pixels.writeColor(pos,value,new Util.Color4f( oldColor ,params['color'] , 0.7));
		oldColor=pixels.readColor4f(pos,value+1) ;
		pixels.writeColor(pos,value+1,new Util.Color4f( oldColor ,params['color'] , 0.7));
//		oldColor=pixels.readColor4f(pos,value+2) ;
//		pixels.writeColor(pos,value+2,oldColor*0.5);
	}

	texture.dataChanged();
	pos+=duration*10;
	if(pos>=xRes)
		pos=0;

	var blending=new Rendering.BlendingParameters();
	blending.enable();
	blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE_MINUS_SRC_ALPHA);
//	blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.DST_ALPHA);
	renderingContext.pushAndSetBlending(blending);
	renderingContext.pushAndSetShader(void);
    Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()) ,
                            [this.texture],[new Geometry.Rect(0,0,1,1)]);
	renderingContext.popShader();
	renderingContext.popBlending();

};


// ---------------------------------------------------------
return StatOverlayPlugin;

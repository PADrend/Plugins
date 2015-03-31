/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010-2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Spielerei/JumpNRun.escript
 ** 2009-11 Claudius Urlaubsprojekt...
 **/
declareNamespace($Tools);
Tools.JumpNRunPlugin := new Plugin({
		Plugin.NAME : 'Tools_JumpNRun',
		Plugin.DESCRIPTION : "Gravity and simple collision detection for camera.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []

});

var plugin = Tools.JumpNRunPlugin;

/*!	---|> Plugin */
plugin.init @(override) := fn(){
     { // Register ExtensionPointHandler:
        registerExtension('PADrend_Init',this->this.ex_Init);
        registerExtension('PADrend_AfterFrame',this->this.ex_AfterFrame);
        registerExtension('PADrend_UIEvent',this->this.ex_UIEvent);
    }
    this.enabled:=false;
    this.fbo:=void;
    this.jump:=false;
    this.lastDirDist:=false;
    this.ghostMode:= DataWrapper.createFromValue(false);

    this.gravity:=-20.0;

	this.zNear:=0.01;
	this.zFar:=10;

    this.t_1 := false;
    this.t_2 := false;
	this.pos_2 := false;

	this.rayCaster :=void;
	this.size := DataWrapper.createFromConfig( systemConfig,'Tools.JumpNRun.size',1.5);

	return true;
};

//! [ext:PADrend_Init]
plugin.ex_Init:=fn(){
	gui.register('Tools_ToolsMenu.jumpNRun',[
		"*JumpNRun*",
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Enable",
			GUI.ON_CLICK : this->enable
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Disable",
			GUI.ON_CLICK : this->disable
		},
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [-1,3],
			GUI.RANGE_FN_BASE : 10,
			GUI.DATA_WRAPPER : size
			
		},
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "ghost mode",
			GUI.TOOLTIP : "Ghosts can walk through walls!",
			GUI.DATA_WRAPPER : ghostMode
			
		},
		'----'
	]);
};

/*!	(public interface) */
plugin.enable:=fn(){

    if(enabled)
        return;
    if(!this.fbo){
        this.fbo := new Rendering.FBO();
        renderingContext.pushAndSetFBO(fbo);
        this.colorTexture := Rendering.createStdTexture(32,32,true);
        this.depthTexture := Rendering.createDepthTexture(32,32);
        fbo.attachColorTexture(renderingContext,colorTexture);
        fbo.attachDepthTexture(renderingContext,depthTexture);

        out(fbo.getStatusMessage(renderingContext),"\n");
        renderingContext.popFBO();

        this.depthCam:=new MinSG.CameraNode();
        depthCam.setViewport( new Geometry.Rect(0,0,32,32));

        depthCam.setNearFar(zNear,zFar);
        depthCam.applyVerticalAngle(20);
    }
    enabled=true;
    PADrend.getCameraMover().setWalkMode(true);
};

/*!	(public interface) */
plugin.disable:=fn(){
    enabled=false;
    PADrend.getCameraMover().setWalkMode(false);
};

//!	[ext:PADrend_AfterFrame]
plugin.ex_AfterFrame:=fn(...){
    if(!enabled)
        return;

	var observer=PADrend.getCameraMover().getDolly();

    if(!rayCaster)
		rayCaster=new (Std.module('LibMinSGExt/RendRayCaster'));

	var t_0=clock();
	if(!t_1)
		t_1=t_0;
	if(!t_2)
		t_2=t_0;

	var times=[];
	for(var t=t_1+0.01;t<t_0;t+=0.05){ // take a sample at least for every 50 ms
		times+=t;
	}
	times+=t_0;

	//out("\r                        \r#",times.count(),": ");

	foreach(times as t_0){
		var d_0=t_0-t_1;
		var d_1=t_1-t_2;
		var pos_1=observer.getRelPosition();
		if(!pos_2)
			pos_2=pos_1;

		var pos_0 = step( d_1,d_0,pos_2,pos_1);
		observer.setRelPosition(pos_0);

		// ----
		t_2=t_1;
		t_1=t_0;

		pos_2=pos_1;
	}


//
//	var dir = pos - pos_1;
////	dir.setY(0);
//	if(!ghostMode() && (dir.getX()!=0 || dir.getZ()!=0))  {
//		var distance =  measureDepth(new Geometry.SRT( pos , -dir , new Geometry.Vec3(0,1,0)));
//
//		out("\r",distance);
//
//		if(!lastDirDist)
//			lastDirDist=distance;
//		if(distance < size*0.3 && distance<lastDirDist){
//	//        observer.moveRel(0,size*0.52-depth,0); // jump
//
////			observer.setRelPosition(pos_1);
//			v*=0.1;
////			lastDirDist=depth;
//			out("XX");
//		}
////		else if(depth < size*0.5 && depth<lastDirDist){
////	//        observer.moveRel(0,size*0.52-depth,0); // jump
////			var r=((size*0.5-depth + size*0.3) / (size*0.5)).pow(4);
////			observer.moveRel(-dir*r);
//////			observer.setRelPosition(pos_1* r +pos*(1.0-r) );
////			damping*=0.1;
//////			lastDirDist=depth;
//////			out("XX",r," ");
////		}else{
//			lastDirDist=distance;
////			out("        ");
//
////		}
//    }

    // -----------------------------------
};

/*!
		^ position (meters)
		|
		|
	p_2 - - x
		|   |
	p_1-|- - - - x
		|   |    |    x - p_0 ?
		|   |    |    |
		o---|----|----|------> time (seconds)
           t_2  t_1  t_0
            <d_1> <d_0>

*/
plugin.step:=fn( Number d_1, Number d_0, Geometry.Vec3 pos_2, Geometry.Vec3 pos_1 ){
	if( d_1==0 || d_0==0)
		return pos_1;

	// vertical speed
	var v = (pos_1.getY() - pos_2.getY()) / d_1; // ( m/s )
	v +=  gravity * d_0;  // (m/s^2 * s)

	var intersection= rayCaster.queryIntersection(frameContext,PADrend.getCurrentScene(),pos_1,pos_1 + new Geometry.Vec3(0,-size(),0) );
	var height;

	if(!intersection){
		height=size();
	}else{
		height=(pos_1 - intersection).length();
	}
	if(pos_1.getY() < size() && pos_1.getY() < height){
		height=pos_1.getY();
	}
	// elevate
    if(height < size()*0.5){
        v*=0.1; // add massive damping
    	v += (size()-height) * d_0 *200.0; // add upward force
    }else if(height< size() ){
    	if(jump){
			v += jump; // add an impulse ( (kg*) m/s )
			jump = 0.0;
        }else {
			v*=0.5;// add damping
        }
    	v +=  (size()-height) * d_0 *200.0; // add upward force

    }else {
        jump=false;
    }

	var m = new Geometry.Vec3(0,v,0)*d_0; // (m/s * s)

	return pos_1 + m;
};

/**
 * [ext:PADrend_KeyPressed]
 */
plugin.ex_UIEvent:=fn(evt) {
    if(!enabled)
        return false;
    if(evt.type==Util.UI.EVENT_KEYBOARD && evt.pressed){
        if(evt.key == Util.UI.KEY_SHIFTL){
            jump=5.0*size();
            return true;
        } // L-Shift
    }
    return false;
};

return plugin;
// ----------------------------------------------------------------------------

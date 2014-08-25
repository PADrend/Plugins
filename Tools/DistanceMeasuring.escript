/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2012 Benjamin Eikel <benjamin@eikel.org>
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
 **	[Plugin:Tools_DistanceMeasuring] Tools/DistanceMesauring.escript
 ** 2010-01
 **/
 
declareNamespace($Tools);

Tools.DistanceMeasuringPlugin := new Plugin({
		Plugin.NAME : 'Tools_DistanceMeasuring',
		Plugin.DESCRIPTION : "Measure distances.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});
var plugin = Tools.DistanceMeasuringPlugin;

/*!	---|> Plugin */
plugin.init @(override) := fn(){
     { // Register ExtensionPointHandler:
        registerExtension('PADrend_AfterRenderingPass',this->this.ex_AfterRenderingPass);
        registerExtension('PADrend_Init',this->this.ex_Init);
    }
	var m=0;
	this.IDLE := m++;
	this.PICK_FIRST := m++;
	this.PICK_SECOND := m++;
	this.PICK_JUMP := m++;

    this.mode:=IDLE;
    this.eventListenerRegistered:=false;

    this.measurement:=false;
    this.window:=false;
    this.infoLabel:=false;
    this.jumpDistance:=DataWrapper.createFromValue(1.0);
	this.flyToHandler:=void;
    this.rayCaster:=void;
    
    this.eventHandler := this->ex_UIEvent;
    
	return true;
};

//! [ext:PADrend_Init]
plugin.ex_Init:=fn() {

	this.window=gui.createWindow(320,250,"Measurement",GUI.HIDDEN_WINDOW);
	this.window.setPosition(200,renderingContext.getWindowHeight()-250);

	this.window.setEnabled(false);
	this.infoLabel=gui.createLabel(320,250,"...");

	infoLabel.setFont(gui.getFont(GUI.FONT_ID_XLARGE));

    infoLabel.setColor(new Util.Color4f(1.0,1.0,1.0,1.0));

	this.window.add(infoLabel);
	
	gui.registerComponentProvider('Tools_ToolsMenu.measuring',[
		"*Measure*",
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Measure",
			GUI.ON_CLICK : fn(){
				PADrend.uiToolsManager.setActiveTool('DistanceMeasure');
			},
			GUI.TOOLTIP : "Click to start measuring distances.\n"
				"Hint: After the first click, the distance from the camera to the picked \n"
				"point is measured until the mouse is moved."
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Clear",
			GUI.ON_CLICK : this->fn() {
				PADrend.executeCommand( fn(){ Tools.DistanceMeasuringPlugin.clearMeasurement(); });
			},
			GUI.TOOLTIP : "Remove current measurement."
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Jump to distance",
			GUI.ON_CLICK : this->fn() {
				setMode(PICK_JUMP);
			},
			GUI.TOOLTIP : "Click to jump in the given distance to the picked point."
		},
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.DATA_WRAPPER : jumpDistance,
			GUI.RANGE : [-1,3],
			GUI.RANGE_FN_BASE : 10,
			GUI.TOOLTIP : "Jump distance"
		},
		'----'
	]);
	
	gui.registerComponentProvider('PADrend_ToolsToolbar.measuring',{
		GUI.TYPE : GUI.TYPE_BUTTON,
//		GUI.LABEL : "M",
		GUI.ICON : '#MeasurementTool', 
		GUI.SIZE : [24,24],
		GUI.TOOLTIP : "Distance measuring",
		GUI.ON_CLICK : fn(){
			PADrend.setActiveUITool('DistanceMeasure');
		},
		GUI.ON_INIT : fn(...){
			var swithFun = fn(b){
				if(isDestroyed())
					return $REMOVE;
				setSwitch(b);
			};
			PADrend.accessUIToolConfigurator('DistanceMeasure')
				.registerActivationListener(this->([true] => swithFun))
				.registerDeactivationListener(this->([false] => swithFun));
		},
		GUI.TOOLTIP : "Distance measuring tool\n"
				"[LeftClick] on the scene to start measuring distances.\n"
				"[RightClick] one the button for options.\n"
				"[ESC] to stop measuring.\n"
				"Hint: After the first click, the distance from the camera to the picked \n"
				"point is measured until the mouse is moved.",
		GUI.CONTEXT_MENU_PROVIDER : fn(){
			return [{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Clear",
				GUI.ON_CLICK : this->fn(){	PADrend.executeCommand( fn(){ Tools.DistanceMeasuringPlugin.clearMeasurement(); });	}
			}];
		}
	});
	PADrend.registerUITool('DistanceMeasure')
			.registerActivationListener(this->activateTool)
			.registerDeactivationListener(this->deactivateTool);
};


plugin.activateTool := fn(){
	PADrend.message("Click to measure.");
	registerExtension('PADrend_UIEvent',eventHandler);
	setMode(PICK_FIRST);
};

plugin.clearMeasurement:=fn(){
	if(mode!=IDLE)
		PADrend.deactivateUITool();
	this.measurement=false;
	this.window.setEnabled(false);
};

plugin.deactivateTool := fn(){
	PADrend.message("Measuring stopped.");
	removeExtension('PADrend_UIEvent',eventHandler); 
	setMode(IDLE);
};

//!	[ext:PADrend_AfterRenderingPass]
plugin.ex_AfterRenderingPass:=fn(...){
	if(measurement)
		measurement.display();
};

plugin.setMode := fn(newMode){
	this.mode = newMode;
};

plugin.queryScenePos := fn(screenPos){
	screenPos = new Geometry.Vec2(screenPos);

	var pos = Util.requirePlugin('PADrend/Picking').queryIntersection( screenPos );
	if(!pos) return void;
	var minY = PADrend.getCurrentScene().getWorldBB().getMinY();
	if(pos.getY()<minY)
		pos.setY(minY);
	return pos;
};

//!	[ext:UIEvent]
plugin.ex_UIEvent:=fn(evt){

	if( evt.type==Util.UI.EVENT_MOUSE_BUTTON && evt.pressed){
		if( evt.button == Util.UI.MOUSE_BUTTON_LEFT && this.mode==PICK_FIRST ){
			var pos=queryScenePos( [evt.x, evt.y] );
			out(pos,"\n");
			if(!pos) return Extension.CONTINUE;
			
			PADrend.executeCommand( pos -> fn(){ Tools.DistanceMeasuringPlugin.selectFirstPoint(this); });
			
			// todo: broadcast
			this.setMode(PICK_SECOND);

		}else if(evt.button == Util.UI.MOUSE_BUTTON_LEFT && this.mode==PICK_SECOND ){
			var pos=queryScenePos( [evt.x, evt.y] );
			out(pos,"\n");
			if(!pos) return Extension.CONTINUE;
			
			PADrend.executeCommand( pos -> fn(){ Tools.DistanceMeasuringPlugin.selectSecondPoint(this); });

			this.setMode(PICK_FIRST);
		}else if(evt.button == Util.UI.MOUSE_BUTTON_LEFT && this.mode==PICK_JUMP){
			var pos=queryScenePos( [evt.x, evt.y] );
			out(pos,"\n");
			if(!pos) return Extension.CONTINUE;
			
			var camPos = GLOBALS.camera.getWorldPosition();
			var worldDir = (pos-camPos).normalize()*((pos-camPos).length()-jumpDistance());
			//PADrend.getDolly().moveLocal(PADrend.getDolly().worldDirToLocalDir(worldDir) );
			
			//PADrend.Navigation.flyTo(PADrend.getDolly().getSRT().translateLocal( PADrend.getDolly().worldDirToLocalDir(worldDir) ),0.5); //  this doesn't work with d3fact scenes!
			if(!this.flyToHandler){
				this.flyToHandler = new ExtObject({
					$targetPos : void,
					$sourcePos : void,
					$duration : 0,
					$start :0 ,
					$execute : fn(...){
						var p0 = new Geometry.Vec2(0,0);
						var p1 = new Geometry.Vec2(1.0,0.0);
						var p2 = new Geometry.Vec2(0.0,1.0);
						var p3 = new Geometry.Vec2(1,1);
						while( (Util.Timer.now()-start)<duration ){
							var f = Geometry.interpolateCubicBezier(p0,p1,p2,p3,(Util.Timer.now()-start)/duration ).getY();
							PADrend.getDolly().setWorldPosition( targetPos*f+sourcePos*(1-f));
							yield Extension.CONTINUE;
						}
						PADrend.getDolly().setWorldPosition( targetPos );
						Tools.DistanceMeasuringPlugin.flyToHandler = void;
						return Extension.REMOVE_EXTENSION;	
					}
				});
				registerExtension('PADrend_AfterFrame',flyToHandler->flyToHandler.execute);
			}
			flyToHandler.sourcePos = PADrend.getDolly().getWorldPosition();
			flyToHandler.targetPos = PADrend.getDolly().getWorldPosition()+worldDir;
			flyToHandler.duration = 0.5;
			flyToHandler.start = Util.Timer.now();;


		}
		return Extension.BREAK;
	}else if( evt.type==Util.UI.EVENT_MOUSE_MOTION && this.mode==PICK_SECOND){
		var pos=queryScenePos( [evt.x, evt.y] );
		if(!pos) return Extension.CONTINUE;
		this.selectSecondPoint(pos);
		PADrend.executeCommand( pos -> fn(){ Tools.DistanceMeasuringPlugin.selectSecondPoint(this); });

		return Extension.CONTINUE;
	}
	return Extension.CONTINUE;
};

plugin.selectFirstPoint:=fn(Geometry.Vec3 pos){
	if(!this.measurement)
		this.measurement = new Measurement(pos);
	else{
		this.measurement.pos1 = pos;
	}
	this.window.setEnabled(true);
	selectSecondPoint(PADrend.getDolly().getWorldPosition());
};

plugin.selectSecondPoint:=fn(Geometry.Vec3 pos){
	if(!this.measurement)
		this.measurement = new Measurement(pos,pos);
	else{
		this.measurement.pos2 = pos;
	}
	this.infoLabel.setText(measurement.getInfo());
	if(var OSD = Util.queryPlugin('GUITools/OSD'))
		OSD.message(measurement.getInfo());
	
};


// -----------------------------------------------------------------------------------------
/*! Measurement class */
var Measurement=new Type;
plugin.Measurement := Measurement;

Measurement._constructor:=fn(p1=void,p2=void){
	this.pos1:=p1;
	this.pos2:=p2;
};

Measurement.display:=fn(){
	if( !pos1)
		return;
	var p2=pos2 ? pos2 : pos1;
	var p3=new Geometry.Vec3(p2.getX(),pos1.getY(),p2.getZ());
	renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );

	renderingContext.pushAndSetDepthBuffer(false, false, Rendering.Comparison.LESS);
	renderingContext.pushLine();

	renderingContext.pushAndSetLighting(false);

	var blending=new Rendering.BlendingParameters();
	blending.enable();
	blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE);
	renderingContext.pushAndSetBlending(blending);

	renderingContext.setLineWidth(6.0);
	Rendering.drawVector(GLOBALS.renderingContext, pos1,p2, new Util.Color4f(1.0,0.0,0.0,0.07));

	renderingContext.setLineWidth(2.0);
	Rendering.drawVector(GLOBALS.renderingContext, pos1,p3, new Util.Color4f(0.0,1.0,0.0,0.07));

	Rendering.drawVector(GLOBALS.renderingContext, p3,p2, new Util.Color4f(0.0,0.0,1.0,0.07));
	// ---

	var b1=new Geometry.Box(pos1,0.1,0.1,0.1);
	var b2=new Geometry.Box(p2,0.1,0.1,0.1);
	renderingContext.pushAndSetColorMaterial(new Util.Color4f(1.0,0.0,0.0,0.1));
	Rendering.drawBox(GLOBALS.renderingContext, b1);
	Rendering.drawBox(GLOBALS.renderingContext, b2);
	renderingContext.popMaterial();
	renderingContext.popDepthBuffer();
	renderingContext.pushAndSetDepthBuffer(true, false, Rendering.Comparison.LESS);

	b1=new Geometry.Box(pos1,0.05,0.05,0.05);
	b2=new Geometry.Box(p2,0.05,0.05,0.05);
	renderingContext.pushAndSetColorMaterial(new Util.Color4f(1.0,0.0,0.0,0.6));
	Rendering.drawBox(GLOBALS.renderingContext, b1);
	Rendering.drawBox(GLOBALS.renderingContext, b2);
	renderingContext.popMaterial();

	renderingContext.popBlending();
	renderingContext.applyChanges();
	// ---

	renderingContext.setLineWidth(4.0);
	Rendering.drawVector(GLOBALS.renderingContext, pos1,p2, new Util.Color4f(1.0,0.0,0.0,1.0));

	renderingContext.setLineWidth(1.0);

	Rendering.drawVector(GLOBALS.renderingContext, pos1,p3, new Util.Color4f(0.0,1.0,0.0,1.0));

	Rendering.drawVector(GLOBALS.renderingContext, p3,p2, new Util.Color4f(0.0,0.0,1.0,1.0));

	renderingContext.popLine();
	renderingContext.popLighting();
	renderingContext.popDepthBuffer();
	renderingContext.pushAndSetMatrix_modelToCamera();
};
Measurement.getInfo:=fn(){
//	var s=" "+this.pos1+" to "+this.pos2+"\n";
	var d=(pos2-pos1);
	var s="Distance: "+(d.length()*100).round()*0.01+"\n";
	s+="Horizontal: "+((new Geometry.Vec3(d.getX(),0,d.getZ())).length()*100).round()*0.01+"\n";
	s+="Vertical: "+(d.getY()*100).round()*0.01;
//	s+=" Diff: "+d+" Length: "+d.length();"\n";
	return s;
};

// -----------------------------------------------------------------------------------------

return plugin;

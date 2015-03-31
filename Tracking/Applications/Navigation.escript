/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Mouns R. Husan Almarrani
 * Copyright (C) 2010 Robert Gmyr
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


static deviceRequirements = [	Std.module('LibUtilExt/HID_Traits').Controller_Room6D_Trait, 
								Std.module('LibUtilExt/HID_Traits').ControllerAnalogAxisTrait, 
								Std.module('LibUtilExt/HID_Traits').ControllerButtonTrait];
static enabled = Std.DataWrapper.createFromEntry( systemConfig,'Tracking.Nav.intitiallyEnabled',false );
static deviceNames = Std.DataWrapper.createFromEntry(systemConfig,'Tracking.Nav.deviceNames', ["Flystick"]);

// ------------

static axes = new Map;
static button0 = false;
static inverseRoomSRT;

static TrackingTools = module('../TrackingTools');

static buttonHandler = fn(buttonId,pressed){
	if(buttonId == 0)
		button0 = pressed;
	outln("ButtonHandler:",buttonId,pressed);
};
static axesHandler = fn(axisId,value){
	outln(axisId,":",value);
	axes[axisId] = value;
};

static removeRolling = fn( srt ){
	var dir = srt.getDirVector();
	var up = dir.cross( (new Geometry.Vec3(0,1,0)).cross(dir) );
	return new Geometry.SRT( srt.getTranslation(), dir, up, srt.getScale() );
};

//static lastPos = void;

static deviceRoomSRT;

static positionHandler = fn(roomSRTOrVoid){
	if(!roomSRTOrVoid){
		return;
	}
	deviceRoomSRT = roomSRTOrVoid.clone();
	
	static lastPos;
	
//	var rSRT = TrackingTools.roomSRTToWorldSRT(roomSRTOrVoid);
	var rSRT = roomSRTOrVoid;
	var roomPos = rSRT.getTranslation();
	if(button0&&lastPos){
		roomTranslationVector = -(roomPos-lastPos);
	}
//		var distance = 0;
//		{
//			@(once) static TrackingTools = module('../TrackingTools');
//
//			var worldSRT = TrackingTools.roomSRTToWorldSRT(roomSRTOrVoid);
//			var worldSource = worldSRT.getTranslation();
//			var worldTarget = TrackingTools.querySceneIntersection( new Geometry.Segment3( worldSource, worldSource+worldSRT.getDirVector()*10000 ));
//			distance = worldSource.distance(worldTarget);
//		}
//		var strength = [100, (0.3+  (distance).sqrt()*3.0 )].min();
//		if(lastStrength) strength = strength*0.6 + lastStrength*0.4;
//		lastStrength = strength;
////		outln(strength);
//		var dolly = PADrend.getDolly();
//		dolly.moveLocal( -(roomPos-lastPos) * strength );
//	}else{
//		lastStrength = false;
//	}
	lastPos = roomPos; 

//	if(button0 && inverseRoomSRT ){
//		var dolly = PADrend.getDolly();
//		var relRoomTransformation = rSRT * inverseRoomSRT;
////		var relRoomRotation = relRoomTransformation.getRotation();
//
//		outln( relRoomTransformation.getTranslation() );
//	
////		var clientWorldSRT = PADrend.getDolly().getWorldTransformationSRT();
////		clientWorldSRT.setRotation( relRoomRotation * clientWorldSRT.getRotation());
////		clientWorldSRT.setTranslation( relRoomTransformation * clientWorldSRT.getTranslation() );
////		PADrend.getDolly().setWorldTransformation(clientWorldSRT);
//		var clientSRT = dolly.getRelTransformationSRT();
//		dolly.moveLocal( relRoomTransformation.getTranslation() );
////		clientSRT.setRotation( relRoomRotation * clientSRT.getRotation());
////		clientSRT.setTranslation( relRoomTransformation * clientSRT.getTranslation() );
//		
//		
////		dolly.setRelTransformation(clientSRT);
//	}
//	inverseRoomSRT = rSRT.inverse();
//	inverseRoomSRT.setScale(1.0);
//	this.currentRoomTransformation = roomSRTOrVoid;
};

static queryTranslationStrength = fn(){
	@(once) static currentStrength = 0;
	@(once) static lastTime = -1;
	
	if(deviceRoomSRT && clock()-lastTime>0.1){
		lastTime = clock();
		
		var distance = 0;
		
		@(once) static TrackingTools = module('../TrackingTools');

		var worldSRT = TrackingTools.roomSRTToWorldSRT(deviceRoomSRT);
		var worldSource = worldSRT.getTranslation();
		var worldTarget = TrackingTools.querySceneIntersection( new Geometry.Segment3( worldSource, worldSource+worldSRT.getDirVector()*10000 ));
		distance = worldSource.distance(worldTarget);
		
		var s = ([100, (0.3+  (distance).sqrt()*3.0 )].min()) * 25.0;
		if(currentStrength>0) s = s*0.6 + currentStrength*0.4;
		currentStrength = s;
	}
	return currentStrength;
};

static roomTranslationVector;

static frameListener = fn(){
	@(once) static lastTime = clock();
	var now = clock();
	var t = now-lastTime;
	lastTime = now;
	if(!deviceRoomSRT)
		return;
	// translating using the trigger-button
	if( roomTranslationVector && !roomTranslationVector.isZero() ){
		var strength = queryTranslationStrength();
		var dolly = PADrend.getDolly();
//		outln(  );
		var amount =  	strength  *  // distance strength
						t *  // time 
						[3.0+roomTranslationVector.length().log(),0.5].min(); // movement speed
		dolly.moveLocal( roomTranslationVector * amount );
		if(!button0){ // smooth out
			roomTranslationVector *= [0,(0.9-t)].max();
			if(roomTranslationVector.length()<0.01)
				roomTranslationVector = void;
		}
			
	}
	@(once) static analogTranslationValue = 0;
	
	if(axes[1]){
		var v = axes[1];
		var i = [0,(0.9-t)].max();
		analogTranslationValue = analogTranslationValue*i + v*(1-i);
	}else{
		analogTranslationValue *= [0,(0.9-t)].max();
	}
		
	// translation using the analog axis 1
	if(analogTranslationValue.abs()>0.001){
//		var amount = queryTranslationStrength() * ( (1.0+axes[1].abs()).pow(0.5)*axes[1].sign()) * t * 0.01;
		var amount = queryTranslationStrength() * analogTranslationValue * t *0.1;
//		outln(( (1.0+axes[1].abs()).pow(0.5)*axes[1].sign()));
		outln(amount);
		var dolly = PADrend.getDolly();
		dolly.moveLocal( deviceRoomSRT.getDirVector() * amount );
	}
	// rotation using the analog axis 0
	if(axes[0] && axes[0].abs()>0.001){
		@(once) static TrackingTools = module('../TrackingTools');

		var amount = axes[0] * t * 30.0;

		if(button0){
			if(amount.abs()>0.01){

				var dolly = PADrend.getDolly();
				var worldSRT = TrackingTools.roomSRTToWorldSRT(deviceRoomSRT);
				var worldSource = worldSRT.getTranslation();
				dolly.rotateAroundWorldAxis_deg( amount,new Geometry.Line3(worldSource ,new Geometry.Vec3(0,1,0)) );
				
			}
			
		}else{


			var worldSRT = TrackingTools.roomSRTToWorldSRT(deviceRoomSRT);
			var worldSource = worldSRT.getTranslation();
			var worldTarget = TrackingTools.querySceneIntersection( new Geometry.Segment3( worldSource, worldSource+worldSRT.getDirVector()*10000 ));

	//		var amount = queryTranslationStrength() * ( (1.0+axes[0].abs()).pow(0.5)*axes[0].sign()) * t ;
			outln(worldTarget);
			if(worldTarget && amount.abs()>0.01){

				var dolly = PADrend.getDolly();
		//		rotateAroundWorldAxis_deg
				dolly.rotateAroundWorldAxis_deg( amount,new Geometry.Line3(worldTarget,new Geometry.Vec3(0,1,0)) );
				
			}
		}
	}
	
};

static myDeviceHandler = new (module('../DeviceHandler'))(enabled, deviceNames);
myDeviceHandler.onDeviceEnabled += fn(device){
	device.onAnalogAxisChanged += axesHandler;							//! \see HID_Traits.ControllerAnalogAxisTrait
	device.onButton += buttonHandler;									//! \see HID_Traits.ControllerButtonTrait
	device.onRoomTransformationChanged += positionHandler; 				//! \see HID_Traits.Controller_Room6D_Trait
	Util.registerExtension('PADrend_AfterFrame', frameListener);
};

myDeviceHandler.onDeviceDisabled += fn(device){	
//	positionHandler(void);
	device.onAnalogAxisChanged -= axesHandler; 							//! \see HID_Traits.ControllerAnalogAxisTrait
	device.onButton -= buttonHandler; 									//! \see HID_Traits.ControllerButtonTrait
	device.onRoomTransformationChanged -= positionHandler; 				//! \see HID_Traits.Controller_Room6D_Trait
	removeExtension('PADrend_AfterFrame', frameListener);
};
myDeviceHandler.refresh();

gui.register('Tracking_applications.flystickNavigation',fn(){
	return [{
		GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
		GUI.COLLAPSED : true,
		GUI.HEADER : [{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL :"FlystickNavigation",
			GUI.DATA_WRAPPER : enabled
		}],
		GUI.CONTENTS : fn(){ 
			var options = [];
			foreach( PADrend.HID.queryPossibleDeviceNames(deviceRequirements...) as var deviceName)
				options += [deviceName,deviceName];
			return [{
				GUI.TYPE : GUI.TYPE_LIST,
				GUI.LABEL : "Device",
				GUI.DATA_WRAPPER : deviceNames,
				GUI.OPTIONS : options,
				GUI.HEIGHT : options.count() * 15+3,
				GUI.TOOLTIP : "Used devices. Hold [ctrl] to select multiple devices."
			}];
		}
	}];
});
return true;

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2014 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static deviceRequirements = [Std.require('LibUtilExt/HID_Traits').Controller_Room6D_Trait];
static enabled = Std.DataWrapper.createFromEntry( systemConfig,'Tracking.Light.intitiallyEnabled',false );
static deviceNames = Std.DataWrapper.createFromEntry(systemConfig,'Tracking.Light.deviceNames', ["Flystick"]);

// ------------

static rpc = Util.requirePlugin('PADrend/RemoteControl');

static lightNode;
static lightingState;

rpc.registerFunction('Tracking.LightApp.set',fn(Array worldSRTArr){
	if(!lightNode){
		lightNode = new MinSG.LightNode(MinSG.LightNode.SPOT);
		lightNode.setTempNode( true );
		lightNode.name := "Tracking.LightApp.light";
	
		lightNode.setAmbientLightColor(new Util.Color4f(0,0,0,1));
		lightNode.setDiffuseLightColor(new Util.Color4f(1,1,1,1));
		lightNode.setSpecularLightColor(new Util.Color4f(1,1,1,1));
		lightNode.setConstantAttenuation(3);
		lightNode.setLinearAttenuation(0);
		lightNode.setQuadraticAttenuation(0);
		lightNode.setExponent(27);
		lightNode.setCutoff(15);
	
	
		lightingState = new MinSG.LightingState(lightNode);
		lightingState.name := "Tracking.LightApp.lighting";
		lightingState.setTempState( true );

		PADrend.getRootNode() += lightNode;
		PADrend.getRootNode() += lightingState;
	}
	lightNode.setRelTransformation( new Geometry.SRT(worldSRTArr) );
	lightNode.rotateLocal_deg( 180, [0,1,0]);
});

rpc.registerFunction('Tracking.LightApp.disable',fn(){
	if(lightNode){
		MinSG.destroy(lightNode);
		lightNode = void;
		PADrend.getRootNode().removeState(lightingState);
		lightingState = void;
	}
});

static positionHandler = fn(roomSRTOrVoid){
//	outln(roomSRTOrVoid);
	if(roomSRTOrVoid.isA(Geometry.SRT)){
		@(once) static TrackingTools = module('../TrackingTools');
		rpc.broadcast('Tracking.LightApp.set', TrackingTools.roomSRTToWorldSRT(roomSRTOrVoid).toArray() );
	}else{
		rpc.broadcast('Tracking.LightApp.disable' );
	}
};

static myDeviceHandler = new (module('../DeviceHandler'))(enabled, deviceNames);
myDeviceHandler.onDeviceEnabled += fn(device){	device.onRoomTransformationChanged += positionHandler; /*! \see HID_Traits.Controller_Room6D_Trait */	};
myDeviceHandler.onDeviceDisabled += fn(device){	
	positionHandler(void);
	device.onRoomTransformationChanged -= positionHandler; /*! \see HID_Traits.Controller_Room6D_Trait */	
};
myDeviceHandler.refresh();

gui.register('Tracking_applications.lightApp',fn(){
	return [{
		GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
		GUI.COLLAPSED : true,
		GUI.HEADER : [{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL :"Light",
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

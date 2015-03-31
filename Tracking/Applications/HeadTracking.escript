/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010 Robert Gmyr
 * Copyright (C) 2010-2014 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 ** Tracking of the position of the observer to optimize immersion for stereoscoping view.
 **/
 
static deviceRequirements = [Std.module('LibUtilExt/HID_Traits').Controller_Room6D_Trait];
static enabled = Std.DataWrapper.createFromEntry( systemConfig,'Tracking.ObserverPositionTracking.intitiallyEnabled',true );
static deviceNames = Std.DataWrapper.createFromEntry(systemConfig,'Tracking.ObserverPositionTracking.deviceNames', ["Brille"]);

static positionHandler = fn(roomSRTOrVoid){
	if(roomSRTOrVoid){
		PADrend.getDolly().getHeadNode().setRelTransformation(roomSRTOrVoid);
	}
};

static myDeviceHandler = new (module('../DeviceHandler'))(enabled, deviceNames);
myDeviceHandler.onDeviceEnabled += fn(device){	device.onRoomTransformationChanged += positionHandler; /*! \see HID_Traits.Controller_Room6D_Trait */	};
myDeviceHandler.onDeviceDisabled += fn(device){	device.onRoomTransformationChanged -= positionHandler; /*! \see HID_Traits.Controller_Room6D_Trait */	};
myDeviceHandler.refresh();

gui.register('Tracking_applications.observerPositionTracking',fn(){
	return [{
		GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
		GUI.COLLAPSED : true,
		GUI.HEADER : [{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL :"Observer position tracking",
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

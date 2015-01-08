/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014 Mouns R. Husan Almarrani<murrani@mail.uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static deviceRequirements = [ Std.require('LibUtilExt/HID_Traits').Controller_Room6D_Trait ];
static enabled = Std.DataWrapper.createFromEntry( systemConfig,'Tracking.SelecterTraking.intitiallyEnabled',false );
static deviceNames = Std.DataWrapper.createFromEntry(systemConfig,'Tracking.SelecterTraking.deviceNames', ["Flystick"]);

static materialState = new MinSG.MaterialState();
static selectedNode =void;

static positionHandler = fn(roomSRT){
	if(roomSRT){

        var r = new (Std.require('LibMinSGExt/RendRayCaster'));
        @(once) static TrackingTools = module('../TrackingTools');

		var worldSRT = TrackingTools.roomSRTToWorldSRT(roomSRT);
		var worldSource = worldSRT.getTranslation();
		var worldTarget = TrackingTools.querySceneIntersection( new Geometry.Segment3( worldSource, worldSource+worldSRT.getDirVector()*10000 ));
		var node = r.queryNode(frameContext, PADrend.getRootNode(), worldSource, worldTarget, true);

        if(selectedNode)
            selectedNode.removeState(materialState);
        if(node)
            node.addState(materialState);
        selectedNode = node;

		}

};

static rpc = Util.requirePlugin('PADrend/RemoteControl');
rpc.registerFunction('Tracking.SelecterTraking.setMode',fn(mode){
	enabled (mode =="true" ? true : false);

});


static myDeviceHandler = new (module('../DeviceHandler'))(enabled, deviceNames);
myDeviceHandler.onDeviceEnabled += fn(device){
	device.onRoomTransformationChanged += positionHandler; /*! \see HID_Traits.Controller_Room6D_Trait */
	materialState.setAmbient(new Util.Color4f(1.0, 0.0, 0.0, 1.0));
	materialState.setDiffuse(new Util.Color4f(1.0, 0.0, 0.0, 1.0));
	materialState.setSpecular(new Util.Color4f(1.0, 0.0, 0.0, 1.0));

};
myDeviceHandler.onDeviceDisabled += fn(device){
	positionHandler(void);
	device.onRoomTransformationChanged -= positionHandler; /*! \see HID_Traits.Controller_Room6D_Trait */
};

myDeviceHandler.refresh();
gui.registerComponentProvider('Tracking_applications.SelecterTraking',fn(){
	return [{
		GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
		GUI.COLLAPSED : true,
		GUI.HEADER : [{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL :"SelecterTraking",
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

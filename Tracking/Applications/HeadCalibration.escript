/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010 Robert Gmyr
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
 
static enabled = Std.DataWrapper.createFromEntry( systemConfig,'Tracking.HeadCalibration.intitiallyEnabled',false );
enabled.onDataChanged += fn(b){
	foreach(markers as var marker)
		marker.destroy();
	markers.clear();
	Util.removeExtension('PADrend_AfterFrame',handler);

	if(b)
		Util.registerExtension('PADrend_AfterFrame',handler);
};

static markers = [];
static handler = fn(){
	foreach(markers as var marker)
		marker.destroy();
	markers.clear();

	var dolly = PADrend.getDolly();

	var cameraFrameArr = dolly.getFrame();
	if(!cameraFrameArr){
		@(once) Runtime.warn("@(once) Using HeadCalibration without a camera frame!");
		return;
	}
	var roomScreenPlane = new Geometry.Plane( cameraFrameArr... );
	var roomDir = roomScreenPlane.getNormal();
	foreach(MinSG.collectNodes(dolly,MinSG.CameraNode) as var nr, var camera){

		var cameraRoomRay = new Geometry.Line3(  dolly.worldPosToLocalPos( camera.getWorldOrigin() ), roomDir );
		var roomIntersection = roomScreenPlane.getIntersection(cameraRoomRay);
		if(roomIntersection){
			var worldScreenIntersection = dolly.localPosToWorldPos( roomIntersection );
		
			var marker = gui.create({
				GUI.TYPE : GUI.TYPE_LABEL,
				GUI.LABEL : "("+nr+")",
				GUI.COLOR : new Util.Color4f(1,1,1,1),
				GUI.FLAGS : GUI.ALWAYS_ON_TOP
			});
			gui.registerWindow(marker);
			markers += marker;
			var screenPos = frameContext.convertWorldPosToScreenPos(worldScreenIntersection);
			marker.setPosition( [screenPos.x()-marker.getWidth()*0.5,screenPos.y()-marker.getHeight()*0.5] );
		}
	}
};

gui.registerComponentProvider('Tracking_applications.observerPositionCalibration',fn(){
	return [{
		GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
		GUI.COLLAPSED : true,
		GUI.HEADER : [{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL :"Head calibration",
			GUI.DATA_WRAPPER : enabled
		}],
		GUI.CONTENTS : ["Show the projection of the camera centers to adjust the eye offsets." ]
	}];
});


/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


/*! All camera nodes placed below a node with the CameraFrameAdjustmentTrait (=dolly)
	are automatically adjusted to a camera frame.
	The camera frame is described by three points [x,y,z] relative to the dolly: topLeft, bottomLeft, bottomRight.
	
	Adds the following public members:
	- setFrame( [ topLeft, bottomLeft, bottomRight] || void )
	- getFrame( )
	
	\note Adds the MinSG.TransformationObserverTrait to the subject.
	\note Adds the MinSG.NodeAddedObserverTrait to the subject.

*/
static t = new Traits.GenericTrait;


static updateCameras = fn(dolly, [Array,void] frame){
	static updateInProgress;
	if(updateInProgress||!frame)
		return;
	updateInProgress = true;
	try{
		var wFrameTopLeft = dolly.localPosToWorldPos( new Geometry.Vec3(frame[0]) );
		var wFrameBottomLeft = dolly.localPosToWorldPos( new Geometry.Vec3(frame[1]) );
		var wFrameBottomRight = dolly.localPosToWorldPos( new Geometry.Vec3(frame[2]) );
		var wFrameUp = wFrameTopLeft - wFrameBottomLeft;
		var wFrameNormal = (wFrameTopLeft-wFrameBottomLeft).cross(wFrameBottomRight-wFrameBottomLeft);

		foreach(MinSG.collectNodes(dolly,MinSG.CameraNode) as var camera){

			// - change orientation of the camera to orthogonally face the projection plane
			var relFrameNormal = camera.worldDirToRelDir(wFrameNormal);
			if(relFrameNormal.isZero()){ // camera on plane? move it a little bit...
				outln("Camera is in the projection plane! Moving the camera away...");
				camera.setWorldPosition( camera.getWorldPosition()+wFrameNormal.normalize()*0.01 );
				relFrameNormal = camera.worldDirToRelDir(wFrameNormal);
			}
			camera.setSRT( new Geometry.SRT(camera.getRelPosition(), 					// position
											-relFrameNormal,							// direction
											-camera.worldDirToRelDir(wFrameUp)));		// up-vector


			// - calculate corners relative to the camera
			var localFrameTopLeft = camera.worldPosToLocalPos(wFrameTopLeft);
			var localFrameBottomRight = camera.worldPosToLocalPos(wFrameBottomRight);
			
			// - calculate and set the frustum's angles
			var distanceToPlane = localFrameTopLeft.getZ();

			var leftAngle 	= -(localFrameTopLeft.getX()/distanceToPlane).atan();
			var rightAngle 	= -(localFrameBottomRight.getX()/distanceToPlane).atan();
			var bottomAngle	= -(localFrameBottomRight.getY()/distanceToPlane).atan();
			var topAngle= -(localFrameTopLeft.getY()/distanceToPlane).atan();
			
			camera.setAngles(leftAngle.radToDeg(),rightAngle.radToDeg(),bottomAngle.radToDeg(),topAngle.radToDeg());
		}
	
	}catch(e){
		updateInProgress = false;
		throw e;
	}
	updateInProgress = false;
};

t.onInit += fn( MinSG.GroupNode dolly ){
	var frameWrapper = new Std.DataWrapper;
	frameWrapper.onDataChanged += [dolly] => updateCameras;

	//! \see MinSG.TransformationObserverTrait
	if(!Traits.queryTrait(dolly,MinSG.TransformationObserverTrait))
		Traits.addTrait(dolly,MinSG.TransformationObserverTrait);
	dolly.onNodeTransformed += [dolly,frameWrapper] => fn(dolly,frameWrapper,node){	
		if(node!=dolly)
			updateCameras(dolly,frameWrapper());	
	};
	
	//! \see MinSG.NodeAddedObserverTrait
	if(!Traits.queryTrait(dolly,MinSG.NodeAddedObserverTrait))
		Traits.addTrait(dolly,MinSG.NodeAddedObserverTrait);
	dolly.onNodeAdded += [dolly,frameWrapper]=>fn(dolly,frameWrapper,...){	updateCameras(dolly,frameWrapper());	};

	dolly.setFrame := [frameWrapper] => fn(frameWrapper, [Array,void,false] frame){	frameWrapper(frame ? frame : void); /* allow false for backward compatibility */	};
	dolly.getFrame := [frameWrapper] => fn(frameWrapper){	return frameWrapper().clone();	};
};

return t;

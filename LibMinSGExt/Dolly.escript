/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 ** [PADrend] Util/Dolly.escript
 **
 ** Dolly for advanced camera movement & advanced alignment
 ** 2009-06-06
 **/


/* stereo
	mode: left, right, sideBySide, crossEye
	setRightEyeOffset
	enableRightRye
	enableLeftRye
	sideBySideEnabled = dataWrapper
	*/
//
//MinSG.VirtualFrameNodeTrait := new Traits.GenericTrait('MinSG.VirtualFrameNodeTrait');
//{
//   \todo disable transformation listening when updating camera node    
//
//    var t = MinSG.VirtualFrameNodeTrait;
//    
//    
//    var refreshCameras = fn(MinSG.Node node){
//        if(!this.frame)
//            return;
//        var frameTopLeft = new Geometry.Vec3(this.frame[0]);
//        var frameBottomLeft = new Geometry.Vec3(this.frame[1]);
//        var frameBottomRight = new Geometry.Vec3(this.frame[2]);
//        var frameUp = frameTopLeft-frameBottomLeft;
//        var frameNormal = frameUp.cross(frameBottomRight-frameBottomLeft);
//
//        foreach(MinSG.collectNodes(node,MinSG.CameraNode) as var camera){
//            var relCamPos = this.worldPosToLocalPos( camera.getWorldPos() );
//        
//            //...
//        }
//    };
//    
//    t.attributes.frame @(init) := fn(){    return DataWrapper.createFromValue(void); };
//    
//    t.onInit += [refreshCameras] => fn(refreshCameras, MinSG.ListNode node){
//        //! \see MinSG.NodeAddedObserverTrait
//        if(!Traits.queryTrait( node, MinSG.NodeAddedObserverTrait ))
//            Traits.addTrait( node, MinSG.NodeAddedObserverTrait );
//        node.onNodeAdded += refreshCameras;
//        
//        //! \see MinSG.TransformationObserverTrait
//        if(!Traits.queryTrait( node, MinSG.TransformationObserverTrait ))
//            Traits.addTrait( node, MinSG.TransformationObserverTrait );
//        node.onNodeTransformed += refreshCameras;
//        
//        node.frame.onDataChanged += [refreshCameras,node]=>fn(refreshCameras,node,...){    refreshCameras(node);    };
//    };
//}
//

var t = new Traits.GenericTrait('MinSG.DollyNodeTrait');


t.attributes.camera := void;
t.attributes.observerPosition := false;

t.attributes.observerPosition := false;
t.attributes.observerOffset := false;  		// (Array|false) added to the observer position if observerOffsetEnabled is true
t.attributes.observerOffsetEnabled := false;
t.attributes.frame := false;
t.attributes.name := "Dolly";

t.attributes.getCamera					:= fn(){	return camera;	};

// observer position: [x,y,z] | false
t.attributes.getObserverPosition 		:= fn(){	return observerPosition.clone();	};
t.attributes.setObserverPosition := fn(pos){
	if(pos!=observerPosition){
		observerPosition=pos;
		this.recalculateFramedCamera();
	}
};

// observer offset: [x,y,z] | false
t.attributes.setObserverOffset:=fn(offset){
	if(offset!=observerOffset){
		observerOffset=offset;
		if(observerOffsetEnabled)
			this.recalculateFramedCamera();
	}
};

t.attributes.getObserverOffset 			:= fn(){	return observerOffset.clone();	};
t.attributes.isObserverOffsetEnabled	:= fn(){	return observerOffsetEnabled;	};

t.attributes.setObserverOffsetEnabled := fn(Bool b){
	if(observerOffsetEnabled!=b){
		observerOffsetEnabled=b;
		this.recalculateFramedCamera();
		
	}
};

t.attributes.setCamera := fn(MinSG.Node newCam){
	this.camera = newCam;
	this.recalculateFramedCamera();
};

// frame
/**
 * @param Array [ [frameTopLeftX,frameTopLeftY,frameTopLeftZ] , frameBottomLeft..., frameBottomRight...]
 */
t.attributes.setFrame:=fn(newFrame){
	if(newFrame!=this.frame){
		this.frame = newFrame;
		this.recalculateFramedCamera();
	}
};
t.attributes.getFrame :=			fn(){	return frame;	};

t.attributes.recalculateFramedCamera:=fn(){
	if(!observerPosition )
		return;
	if(!frame){
		var pos = new Geometry.Vec3(observerPosition);
		if(observerOffset && observerOffsetEnabled)
			pos+= new Geometry.Vec3(observerOffset);
		this.camera.setRelPosition(pos);
		return;
	}
	var pos= new Geometry.Vec3(observerPosition);
	if(observerOffset && observerOffsetEnabled)
		pos+= new Geometry.Vec3(observerOffset);

	var frameTopLeft = new Geometry.Vec3(frame[0]);
	var frameBottomLeft = new Geometry.Vec3(frame[1]);
	var frameBottomRight = new Geometry.Vec3(frame[2]);
	var frameNormal = (frameTopLeft-frameBottomLeft).cross(frameBottomRight-frameBottomLeft);

	// - change orientation of the camera to orthogonally face the projection plane
	var lookingDirection = pos-pos.getProjection(frameBottomLeft,frameNormal);
	if(lookingDirection.length() == 0){
		out("Dolly: invalid position! \n");
		return;
	}
	var cameraSRT = new Geometry.SRT(pos, lookingDirection, (frameTopLeft-frameBottomLeft));
	camera.setSRT(cameraSRT);

	// - calculate corners relative to the camera
	var invCameraSRT = cameraSRT.inverse();
	var frameTopLeft_rotated = invCameraSRT*frameTopLeft;
	var frameBottomLeft_rotated = invCameraSRT*frameBottomLeft;
	var frameBottomRight_rotated = invCameraSRT*frameBottomRight;

	// - calculate and set the angles of the frustum
	var distanceToPlane=frameTopLeft_rotated.getZ();
	var leftAngle 	= -(frameTopLeft_rotated.getX()/distanceToPlane).atan();
	var rightAngle 	= -(frameBottomRight_rotated.getX()/distanceToPlane).atan();
	
	var bottomAngle	= -(frameBottomRight_rotated.getY()/distanceToPlane).atan();
	var topAngle= -(frameTopLeft_rotated.getY()/distanceToPlane).atan();
	
	camera.setAngles(leftAngle.radToDeg(),rightAngle.radToDeg(),bottomAngle.radToDeg(),topAngle.radToDeg());
};

t.onInit += fn(MinSG.ListNode dollyRoot, MinSG.Node camera){
	dollyRoot += camera;
	dollyRoot.setCamera(camera);

};


GLOBALS.MinSG.createDolly := [t]=>fn(t,camera){
    var dolly=new MinSG.ListNode;
    //! \see MinSG.DollyNodeTrait
    Traits.addTrait(dolly,t,camera);
    return dolly;
};

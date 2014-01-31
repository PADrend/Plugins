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


// -----------------------------------------------------------------

var t = new Traits.GenericTrait('MinSG.DollyNodeTrait');

t.attributes.observerOffset := false;  		// (Array|false) added to the observer position if observerOffsetEnabled is true
t.attributes.observerOffsetEnabled := false;
t.attributes.name := "Dolly";

t.attributes.getCamera					:= fn(){	return this.camera;	};

t.attributes.getObserverPosition 		:= fn(){	return this.camera.getRelPosition().toArray();	};
t.attributes.setObserverPosition := fn(pos){
	pos = pos ? new Geometry.Vec3(pos) : new Geometry.Vec3;
	if( pos.toArray()!=this.getObserverPosition() )
		this.camera.setRelPosition( pos );
};

// observer offset: [x,y,z] | false
t.attributes.setObserverOffset:=fn(offset){
	if(offset!=observerOffset){
		observerOffset=offset;
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

t.onInit += fn(MinSG.ListNode dollyRoot, MinSG.Node camera){
	
	//! \see LibMinSGExt/Traits/CameraFrameAdjustmentTrait
	Traits.addTrait(dollyRoot, Std.require( 'LibMinSGExt/Traits/CameraFrameAdjustmentTrait' ));
	
	dollyRoot += camera;
	dollyRoot.camera @(private) := camera;
	
	
//	CameraFrameAdjustmentTrait

};


GLOBALS.MinSG.createDolly := [t]=>fn(t,camera){
    var dolly=new MinSG.ListNode;
    //! \see MinSG.DollyNodeTrait
    Traits.addTrait(dolly,t,camera);
    return dolly;
};

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


// -----------------------------------------------------------------

/*!
	Dolly  ---> CameraFrame (\see LibMinSGExt/Traits/CameraFrameAdjustmentTrait)
	 |
	 \--------> HeadNode (MinSG.ListNode)
				 |
				 \----------> Camera (MinSG.CamerNode)
*/

var t = new Traits.GenericTrait('MinSG.DefaultDollyNodeTrait');

t.attributes.name := "Dolly";

t.attributes.getCamera					:= fn(){	return this.camera;	};
t.attributes.getHeadNode				:= fn(){	return this.head;	};

t.onInit += fn(MinSG.ListNode dollyRoot, MinSG.Node camera){
	
	//! \see LibMinSGExt/Traits/CameraFrameAdjustmentTrait
	Traits.addTrait(dollyRoot, Std.require( 'LibMinSGExt/Traits/CameraFrameAdjustmentTrait' ));
	
	var headNode = new MinSG.ListNode;
	headNode += camera;
	dollyRoot += headNode;

	dollyRoot.head @(private) := headNode;
	dollyRoot.camera @(private) := camera;
};

return t;

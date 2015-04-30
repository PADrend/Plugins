/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

return fn() {	
	static tools = module('../InternalTools');

	var door = new MinSG.ListNode;
	module('LibMinSGExt/SemanticObject').markAsSemanticObject(door);
	tools.registerNodeWithUniqueId(door,"Door");

	
	//! \see ObjectTraits/Animation/ConstrainedAnimatorTrait
	Std.Traits.addTrait( door, Std.module('ObjectTraits/Animation/ConstrainedAnimatorTrait'));

	//! \see ObjectTraits/Animation/RotationTrait
	Std.Traits.addTrait( door, Std.module('ObjectTraits/Animation/RotationTrait')); // set axis!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	//! \see ObjectTrait/Basic/NodeLinkTrait
	door.addLinkedNodes("animator", tools.createRelativeNodeQuery(door,door)); // the door's motor moves itself

	//! \see ObjectTraits/Basic/TransformationProxyTrait
	Std.Traits.addTrait( door, Std.module('ObjectTraits/Basic/TransformationProxyTrait'));

	tools.planInit( [door] => fn(MinSG.Node node,Array otherNodes){
		foreach(otherNodes as var n2){
			if(!MinSG.isInSubtree(node,n2)){  // if selected node is not an ancestor -> selected node is transformed by this node
				var query = tools.createRelativeNodeQuery(node,n2);
				if(query){
					PADrend.message("Transform: ",query);		
					node.addLinkedNodes( "transform", query, [n2]);
				}
			}
		}
	});


	// -------------------------------------------------
	// handle
	var handle = new MinSG.GeometryNode;
	door += handle;

	//! \see ObjectTraits/Basic/MetaObjectTrait
	Std.Traits.addTrait( handle, Std.module('ObjectTraits/Basic/MetaObjectTrait'));
	
	//! \see ObjectTraits/Geometry/DynamicBoxTrait
	Std.Traits.addTrait( handle, Std.module('ObjectTraits/Geometry/DynamicBoxTrait'));
	handle.boxDimX(0.10);
	handle.boxDimY(0.10);
	handle.boxDimZ(0.20);
	tools.addSimpleMaterial(handle,0.5,0.0,0,0.3);

	handle.moveRel( -0.7,0.5,0 );
	//! \todo add button trait

	//! \see ObjectTraits/Animation/ButtonTrait
	Std.Traits.addTrait( handle, Std.module('ObjectTraits/Animation/ButtonTrait'));
	
	handle.buttonFn1( "animatorGoToMax" );
	handle.buttonFn2( "animatorGoToMin" );
//	
	handle.buttonLinkRole("myDoor");
	//! \see ObjectTrait/Basic/NodeLinkTrait
	handle.addLinkedNodes( "myDoor", tools.createRelativeNodeQuery(handle,door) );

//	node.buttonLinkRole := node.getNodeAttributeWrapper('buttonLinkRole', "switch" );

	
//	static trait = new MinSG.PersistentNodeTrait('ObjectTraits/ButtonTrait');
	
	// ------------------------------------------------
	// hinge
	var hinge = new MinSG.GeometryNode;
	door += hinge;

	//! \see ObjectTraits/Basic/MetaObjectTrait
	Std.Traits.addTrait( hinge, Std.module('ObjectTraits/Basic/MetaObjectTrait'));
	
	//! \see ObjectTraits/Geometry/DynamicCylinderTrait
	Std.Traits.addTrait( hinge, Std.module('ObjectTraits/Geometry/DynamicCylinderTrait'));
	hinge.cylRadius(0.02);
	hinge.cylHeight(1.0);
	hinge.cylNumSegments(8);
	tools.addSimpleMaterial(hinge,0,0.0,0.5,0.3);


	// ------------------------------------------------------
	
	return door;
};


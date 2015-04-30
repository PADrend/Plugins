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

	var door = new MinSG.GeometryNode;
	module('LibMinSGExt/SemanticObject').markAsSemanticObject(door);
	tools.registerNodeWithUniqueId(door,"SlidingDoor");


	//! \see ObjectTraits/Basic/MetaObjectTrait
	Std.Traits.addTrait( door, Std.module('ObjectTraits/Basic/MetaObjectTrait'));
		
	//! \see ObjectTraits/Geometry/DynamicBoxTrait
	Std.Traits.addTrait( door, Std.module('ObjectTraits/Geometry/DynamicBoxTrait'));
	door.boxDimX(1.00);
	door.boxDimY(1.00);
	door.boxDimZ(0.05);
	tools.addSimpleMaterial(door,0.5,0.0,0,0.3);


	//! \see ObjectTraits/Animation/ConstrainedAnimatorTrait
	Std.Traits.addTrait( door, Std.module('ObjectTraits/Animation/ConstrainedAnimatorTrait'));

	//! \see ObjectTrait/Basic/NodeLinkTrait
	Std.Traits.addTrait( door, Std.module('ObjectTraits/Basic/NodeLinkTrait'));
	door.addLinkedNodes("animator", tools.createRelativeNodeQuery(door,door)); // the door's motor moves itself

	//! \see ObjectTraits/Basic/TransformationProxyTrait
	Std.Traits.addTrait( door, Std.module('ObjectTraits/Basic/TransformationProxyTrait'));

	tools.planInit( [door] => fn(MinSG.Node node,Array otherNodes){
		//! \see ObjectTraits/KeyFrameAnimationTrait
		node.animationKeyFrames( { 0 : node.getRelTransformationSRT(), 1 : node.getRelTransformationSRT().translate([1,0,0]) });

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

	//! \see ObjectTraits/Animation/ButtonTrait
	Std.Traits.addTrait( door, Std.module('ObjectTraits/Animation/ButtonTrait'));
	
	door.buttonFn1( "animatorGoToMax" );
	door.buttonFn2( "animatorGoToMin" );
//	
	door.buttonLinkRole("myDoor");
	//! \see ObjectTrait/Basic/NodeLinkTrait
	door.addLinkedNodes( "myDoor", tools.createRelativeNodeQuery(door,door) );


	
	//! \see ObjectTraits/Animation/KeyFrameAnimationTrait
	Std.Traits.addTrait( door, Std.module('ObjectTraits/Animation/KeyFrameAnimationTrait')); 
	
	return door;
};




return factories;

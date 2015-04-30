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

	var node = new MinSG.GeometryNode;
	
	module('LibMinSGExt/SemanticObject').markAsSemanticObject(node);
	
	//! \see ObjectTraits/DynamicCylinderTrait
	Std.Traits.addTrait( node, Std.module('ObjectTraits/Geometry/DynamicCylinderTrait'));
	node.cylRadius(0.05);
	node.cylHeight(1);
	node.cylNumSegments(6);


//	//! \see ObjectTraits/Helper/NodeSensorTrait
//	Std.Traits.addTrait( node, Std.module('ObjectTraits/Helper/NodeSensorTrait'));
//	node.nodeSensor_rootNode( PADrend.getCurrentScene() );
		
	//! \see ObjectTraits/RayCastSensorTrait
	Std.Traits.addTrait( node, Std.module('ObjectTraits/Misc/RayCastSensorTrait'));

	
	tools.planInit( [node] => fn(MinSG.Node node,Array otherNodes){
		//!	\see ObjectTraits/NodeLinkTrait
		node.addLinkedNodes( 'rayCastRoot' , tools.createRelativeNodeQuery(node,PADrend.getCurrentScene()) );	
	});
	
////////////////	
//	node.addLinkedNodes( 'rayCastRoot' ,  "./.." );	//!	\see ObjectTraits/NodeLinkTrait
	
	//! \see ObjectTraits/MetaObjectTrait
	Std.Traits.addTrait( node, Std.module('ObjectTraits/Basic/MetaObjectTrait'));
	
	tools.registerNodeWithUniqueId(node,"Sensor");
	tools.addSimpleMaterial(node,0,0.5,0.0,0.5);
	
	return node;
};

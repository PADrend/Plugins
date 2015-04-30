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
	
	//! \see ObjectTraits/DynamicBoxTrait
	Std.Traits.addTrait( node, Std.module('ObjectTraits/Geometry/DynamicBoxTrait'));
	node.boxDimX(0.25);
	node.boxDimY(0.25);
	node.boxDimZ(0.25);
	
	//! \see ObjectTraits/MetaObjectTrait
	Std.Traits.addTrait( node, Std.module('ObjectTraits/Basic/MetaObjectTrait'));
	
	tools.registerNodeWithUniqueId(node,"Proxy");
	tools.addSimpleMaterial(node,0.0,0.0,0.5,0.5);

	//! \see ObjectTraits/Basic/TransformationProxyTrait
	Std.Traits.addTrait( node, Std.module('ObjectTraits/Basic/TransformationProxyTrait'));
	
	
	tools.planInit( [node] => fn(MinSG.Node node,Array otherNodes){
		foreach(otherNodes as var n2){
			if(!MinSG.isInSubtree(node,n2)){ 
				var worldSRT = n2.getWorldTransformationSRT();
				worldSRT.setTranslation( n2.localPosToWorldPos( n2.getBB().getRelPosition(0.5,0,0.5) ) );
				worldSRT.setScale(1.0);
				node.setWorldTransformation(worldSRT);
			}
		}
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
	return node;
};

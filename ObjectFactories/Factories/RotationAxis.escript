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
	node.cylHeight(0.5);
	node.cylNumSegments(6);
		
	//! \see ObjectTraits/MetaObjectTrait
	Std.Traits.addTrait( node, Std.module('ObjectTraits/Basic/MetaObjectTrait'));
	
	//! \see ObjectTraits/RotationTrait
	Std.Traits.addTrait( node, Std.module('ObjectTraits/Animation/RotationTrait'));
	// connect to animator

	//! \see ObjectTraits/TransformationProxyTrait
	Std.Traits.addTrait( node, Std.module('ObjectTraits/Basic/TransformationProxyTrait'));

	tools.registerNodeWithUniqueId(node,"Axis");
	tools.addSimpleMaterial(node,0,0.0,0.5,0.5);

	tools.planInit( [node] => fn(MinSG.Node node,Array otherNodes){

		var animator;
		foreach(otherNodes as var n2){
			// use selected node as motor?
			if(Traits.queryTrait(n2,Std.module('ObjectTraits/Animation/_AnimatorBaseTrait'))){
				animator = n2;
			}// use selected node's motor
			else if(Traits.queryTrait(n2,Std.module('ObjectTraits/Animation/_AnimatedBaseTrait'))){
				
				//! \see ObjectTrait.NodeLinkTrait
				var arr = n2.getLinkedNodes("animator");
				if(!arr.empty())
					animator = arr.front();
			}else if(!MinSG.isInSubtree(node,n2)){  // if selected node is not an ancestor -> selected node is transformed by this node
				
				//! TEMP!
				if(var axis = n2.findAnchor("axis#0")){
					var aSRT = axis();
					node.setWorldTransformation( new Geometry.SRT(
											n2.localPosToWorldPos(aSRT.getTranslation()), 
											n2.localDirToWorldDir(aSRT.getUpVector()), 
											n2.localDirToWorldDir(aSRT.getDirVector())
									));
				}
				
				var query = tools.createRelativeNodeQuery(node,n2);
				if(query){
					PADrend.message("Transform: ",query);		
					node.addLinkedNodes( "transform", query, [n2]);
				}
			}
		}
			
		if(animator){
			//! \see ObjectTrait.NodeLinkTrait
			var query = tools.createRelativeNodeQuery(node,animator);
			if(query){
				node.addLinkedNodes("animator",query,[animator]);
				PADrend.message("Use animator:",query);		
				
			}
		}
	});

	return node;
};

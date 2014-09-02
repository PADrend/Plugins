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

/*!
    ...

    Links

        Node -- mount ------> Node
         |
         |----- target ---> Node

	Properties
		mountAnchor		String
		targetAnchor	String

*/
static addRevocably = fn( array, callback ){
	array += callback;
	var revocer = fn(){
		if(thisFn.array){
			thisFn.array -= thisFn.callback;
			thisFn.array = void;
			thisFn.callback = void;
		}
		return $REMOVE;
	}.clone();
	revocer.array := array;
	revocer.callback := callback;
	return revocer;
};


static trait = new (Std.require('LibMinSGExt/Traits/PersistentNodeTrait'))('ObjectTraits/PointingJointTrait');

trait.onInit += fn(MinSG.Node node){
    node.__mountNode := new DataWrapper;
    node.__targetNode := new DataWrapper;
    node.__mountAnchorId := node.getNodeAttributeWrapper('pJointMountAnchor',"anchor#0");
    node.__targetAnchorId := node.getNodeAttributeWrapper('pJointTargetAnchor',"anchor#0");

    // ---------------------------------------------------------

	//! \see ObjectTraits/NodeLinkTrait
	Traits.assureTrait(node,Std.require('ObjectTraits/NodeLinkTrait'));


	var updateLocation = [node] => fn(node, ...){
		var mNode = node.__mountNode();
		if(!mNode)
			return;
		var mAnchor = mNode.findAnchor( node.__mountAnchorId() );
		if(!mAnchor)
			return;
		mAnchor = mAnchor();
		var worldUp = mAnchor---|>Geometry.SRT ? mNode.localPosToWorldPos(mAnchor.getUpVector()) : node.getWorldTransformationSRT().getUpVector();
		var worldSource = mNode.localPosToWorldPos( mAnchor---|>Geometry.SRT ? mAnchor.getTranslation() : mAnchor );
		
		var targetNode = node.__targetNode();
		var worldTarget;
		
		if( targetNode ){
			var tAnchor = targetNode.findAnchor( node.__targetAnchorId() );
			if(tAnchor){
				tAnchor = tAnchor();
				worldTarget = targetNode.localPosToWorldPos( tAnchor---|>Geometry.SRT ? tAnchor.getTranslation() : tAnchor );
			}
			
		}
		
		if(worldTarget){
			node.setWorldTransformation(new Geometry.SRT( worldSource, worldTarget-worldSource, worldUp, node.getWorldTransformationSRT().getScale() ));
		}else{
			node.setWorldOrigin( worldSource );
		}
		
	};
	var registerTransformationListener = [updateLocation] => fn(updateLocation,revoce, newNode){
		revoce();
		//! \see  MinSG.TransformationObserverTrait
		Traits.assureTrait(newNode, Std.require('LibMinSGExt/Traits/TransformationObserverTrait'));
		revoce += addRevocably( newNode.onNodeTransformed, updateLocation);
	};

	node.__mountNode.onDataChanged += updateLocation;
	node.__mountNode.onDataChanged += [new MultiProcedure] => registerTransformationListener;
	node.__targetNode.onDataChanged += updateLocation;
	node.__targetNode.onDataChanged +=[new MultiProcedure] =>  registerTransformationListener;
	
	node.__mountAnchorId.onDataChanged += updateLocation;
	node.__targetAnchorId.onDataChanged += updateLocation;
	


	// ---------------------------------------------------
	{	// mount connection
		static roleName = "mountAnchor";

		//! \see ObjectTraits/NodeLinkTrait
		node.availableLinkRoleNames += roleName;

		//! \see ObjectTraits/NodeLinkTrait
		node.onNodesLinked += fn(role,Array nodes){
			if(role==roleName)
				this.__mountNode(nodes.empty() ? void : nodes.back());
		};

		// connect to existing links
		//! \see ObjectTraits/NodeLinkTrait
		if(!node.getLinkedNodes(roleName).empty())
			node.__mountNode( node.getLinkedNodes(roleName).back() );


		//! \see ObjectTraits/NodeLinkTrait
		node.onNodesUnlinked += fn(role,Array nodes){
			if(role==roleName)
				this.__mountNode(void);
		};
	}
	{	// target connection
		static roleName = "targetAnchor";

		//! \see ObjectTraits/NodeLinkTrait
		node.availableLinkRoleNames += roleName;

		//! \see ObjectTraits/NodeLinkTrait
		node.onNodesLinked += fn(role,Array nodes){
			if(role==roleName)
				this.__targetNode(nodes.empty() ? void : nodes.back());
		};

		// connect to existing links
		//! \see ObjectTraits/NodeLinkTrait
		if(!node.getLinkedNodes(roleName).empty())
			node.__targetNode( node.getLinkedNodes(roleName).back() );


		//! \see ObjectTraits/NodeLinkTrait
		node.onNodesUnlinked += fn(role,Array nodes){
			if(role==roleName)
				this.__targetNode(void);
		};
	}


};

trait.allowRemoval();

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "mountAnchorId",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.__mountAnchorId,
				GUI.OPTIONS_PROVIDER : [node] => fn(node){
					var entries = [];
					if(node.__mountNode()){
						foreach(node.__mountNode().findAnchors() as var name,var anchor)
							entries += name;
					}else{
						entries += "anchor#0";
					}
					return entries;
				}
				
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "targetAnchorId",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.__targetAnchorId,
				GUI.OPTIONS_PROVIDER : [node] => fn(node){
					var entries = [];
					if(node.__targetNode()){
						foreach(node.__targetNode().findAnchors() as var name,var anchor)
							entries += name;
					}else{
						entries += "anchor#0";
					}
					return entries;
				}
				
			},
		];
	});
});

return trait;


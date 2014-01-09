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


static trait = new MinSG.PersistentNodeTrait('ObjectTraits/TransformationProxyTrait');

trait.onInit += fn(MinSG.Node node){

	node.transformationProxyEnabled := new DataWrapper(true);
	
	@(once) static NodeLinkTrait = Std.require('ObjectTraits/NodeLinkTrait');

	//! \see ObjectTraits/NodeLinkTrait
	if(!Traits.queryTrait(node,NodeLinkTrait))
		Traits.addTrait(node,NodeLinkTrait);	
	
	static roleName = "transform";
	
	//! \see ObjectTraits/NodeLinkTrait
	node.availableLinkRoleNames += roleName;
	
	var transformedNodes = new Std.Set; 
	var connectTo = [transformedNodes] => fn(transformedNodes, MinSG.Node newNode){
		transformedNodes += newNode;
	};
	var disconnectFrom = [transformedNodes] => fn(transformedNodes, MinSG.Node removedNode){
		transformedNodes -= removedNode;
	};
	

	//! \see ObjectTraits/NodeLinkTrait
	node.onNodesLinked += [connectTo] => fn(connectTo, role,Array nodes,Array parameters){
		if(role==roleName){
			foreach(nodes as var node)
				connectTo(node);
		}
	};
	
	//! \see ObjectTraits/NodeLinkTrait
	node.onNodesUnlinked += [disconnectFrom] => fn(disconnectFrom, role,Array nodes,Array parameters){
		if(role==roleName){
			foreach(nodes as var node)
				disconnectFrom(node);
		}
	};
	
	// connect to existing links
	var connectedNodes = [];
	foreach( node.getNodeLinks(roleName) as var linkInfo)//! \see ObjectTraits/NodeLinkTrait
		connectedNodes.append(linkInfo[0]);
	foreach(connectedNodes as var cNode)
		connectTo(cNode);
		
	// ------------------
	
	{
		var wSRT =  node.getWorldSRT();
		wSRT.setScale(1.0);
		node._inverseWorldTrans := wSRT.inverse();
		
	}

	//! \see  MinSG.TransformationObserverTrait
	if(!Traits.queryTrait(node, MinSG.TransformationObserverTrait))
		Traits.addTrait(node, MinSG.TransformationObserverTrait);
		
	//! \see  MinSG.TransformationObserverTrait		
	node.onNodeTransformed += [transformedNodes] => fn(transformedNodes,node){
		if(node==this){
			var wSRT = this.getWorldSRT();
			wSRT.setScale(1.0);
			this._inverseWorldTrans.setScale(1.0);
	
			if(node.transformationProxyEnabled()){
				var relWorldTransformation = wSRT * this._inverseWorldTrans;
				var relWorldRotation = relWorldTransformation.getRotation();

				foreach(transformedNodes as var cNode){
					var clientWorldSRT = cNode.getWorldSRT();
					clientWorldSRT.setRotation( relWorldRotation * clientWorldSRT.getRotation());
					clientWorldSRT.setTranslation( relWorldTransformation * clientWorldSRT.getTranslation() );
					cNode.setWorldSRT(clientWorldSRT);
				}
			}
			this._inverseWorldTrans := wSRT.inverse();

		}
	};
};

trait.allowRemoval();
trait.onRemove += fn(node){
	node.transformationProxyEnabled(false);
//	node.buttonFn1(void);
//	node.buttonFn2(void);
//	node.buttonLinkRole(void);
};

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [ "Animation Proxy",
			{
				GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.TOOLTIP : "Remove trait",
				GUI.LABEL : "-",
				GUI.WIDTH : 20,
				GUI.ON_CLICK : [node,refreshCallback] => fn(node,refreshCallback){
					if(Traits.queryTrait(node,trait))
						Traits.removeTrait(node,trait);
					refreshCallback();
				}
			},		
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
				{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "active",
				GUI.WIDTH : 200,
				GUI.DATA_WRAPPER : node.transformationProxyEnabled
			},
		];
	});
});

return trait;

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Sascha Brandt <myeti@mail.uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

// 	module('LibMinSGExt/NodeAnchors').createAnchor(nodeContainer,'placingPos')(new Geometry.Vec3(0,0,0));

trait.onInit += fn(MinSG.Node node){
	node.lockAxisEnabled := new DataWrapper(true);
	node.lockXAxis := node.getNodeAttributeWrapper('lockAxis_lockXAxis',false);
	node.lockYAxis := node.getNodeAttributeWrapper('lockAxis_lockYAxis',false);
	node.lockZAxis := node.getNodeAttributeWrapper('lockAxis_lockZAxis',false);
	node.lockXRot := node.getNodeAttributeWrapper('lockAxis_lockXRot',false);
	node.lockYRot := node.getNodeAttributeWrapper('lockAxis_lockYRot',false);
	node.lockZRot := node.getNodeAttributeWrapper('lockAxis_lockZRot',false);

	static roleName = "lockAxis";

	//! \see ObjectTraits/BasicNodeLinkTrait
	Traits.assureTrait(node,module('../Basic/NodeLinkTrait'));

	//! \see ObjectTraits/NodeLinkTrait
	node.availableLinkRoleNames += roleName;

	var transformedNodes = new Map; // node -> [originalSRT, revocer]

	var updateLocation = [node, transformedNodes, new Std.DataWrapper(false)] => fn(node, transformedNodes, transformationInProgress, ...){
		if(node.lockAxisEnabled() && !transformationInProgress()) {
			try{
				transformationInProgress(true);
				foreach(transformedNodes as var targetNode, var entry) {
					var originalPos = entry[0].getTranslation();
					var originalRot = Geometry.Quaternion.matrixToQuaternion(entry[0].getRotation()).toEuler();
					var newSRT = targetNode.getRelTransformationSRT();
					var newPos = newSRT.getTranslation();
					var newRot = Geometry.Quaternion.matrixToQuaternion(newSRT.getRotation()).toEuler();
					if(node.lockXAxis())
						newPos.x(originalPos.x());
					if(node.lockYAxis())
						newPos.y(originalPos.y());
					if(node.lockZAxis())
						newPos.z(originalPos.z());
					if(node.lockYRot()) // heading
						newRot.x(originalRot.x());
					if(node.lockZRot()) // attitude
						newRot.y(originalRot.y());
					if(node.lockXRot()) // bank
						newRot.z(originalRot.z());
					newSRT.setTranslation(newPos);
					if(node.lockXRot() || node.lockYRot() || node.lockZRot()) {
						newSRT.setRotation(Geometry.Quaternion.eulerToQuaternion(newRot));
					}
					node.setRelTransformation(newSRT);
				}
			}catch(e){ // finally
				transformationInProgress(false);
				throw(e);
			}
		}
		transformationInProgress(false);
	};
	var registerTransformationListener = [updateLocation] => fn(updateLocation,revoce, newNode){
		revoce();
		//! \see  MinSG.TransformationObserverTrait
		if(newNode) {
			Traits.assureTrait(newNode, module('LibMinSGExt/Traits/TransformationObserverTrait'));
			revoce += Std.addRevocably( newNode.onNodeTransformed, updateLocation);
		}
	};
	var connectTo = [transformedNodes,registerTransformationListener] => fn(transformedNodes,registerTransformationListener, MinSG.Node newNode){
		var entry = [newNode.getRelTransformationSRT(), new Std.MultiProcedure];
		registerTransformationListener(entry[1], newNode);
		transformedNodes[newNode] = entry;
	};
	var disconnectFrom = [transformedNodes] => fn(transformedNodes, MinSG.Node removedNode){
		var entry = transformedNodes[removedNode];
		if(entry){
			entry[1]();
			transformedNodes.unset( removedNode );
		}
	};

	var updateLockedAxes = [transformedNodes] => fn(transformedNodes){
		foreach(transformedNodes as var targetNode, var entry){
			entry[0].setValue(targetNode.getRelTransformationSRT());
			//outln("updateLockedAxes: ",entry);
		}
	};

	node.lockAxisEnabled.onDataChanged += [updateLockedAxes]=>fn(updateLockedAxes,b){
		if(b) updateLockedAxes();
	};
	node.lockXAxis.onDataChanged += [updateLockedAxes]=>fn(updateLockedAxes,b){
		if(b) updateLockedAxes();
	};
	node.lockYAxis.onDataChanged += [updateLockedAxes]=>fn(updateLockedAxes,b){
		if(b) updateLockedAxes();
	};
	node.lockZAxis.onDataChanged += [updateLockedAxes]=>fn(updateLockedAxes,b){
		if(b) updateLockedAxes();
	};
	node.lockXRot.onDataChanged += [updateLockedAxes]=>fn(updateLockedAxes,b){
		if(b) updateLockedAxes();
	};
	node.lockYRot.onDataChanged += [updateLockedAxes]=>fn(updateLockedAxes,b){
		if(b) updateLockedAxes();
	};
	node.lockZRot.onDataChanged += [updateLockedAxes]=>fn(updateLockedAxes,b){
		if(b) updateLockedAxes();
	};

	//! \see ObjectTraits/Basic/NodeLinkTrait
	node.onNodesLinked += [connectTo,updateLockedAxes] => fn(connectTo,updateLockedAxes,role,Array nodes){
		if(role==roleName) {
			foreach(nodes as var node)
				connectTo(node);
			updateLockedAxes();
		}
	};

	//! \see ObjectTraits/Basic/NodeLinkTrait
	node.onNodesUnlinked += [disconnectFrom] => fn(disconnectFrom, role,Array nodes){
			if(role==roleName) {
				foreach(nodes as var node)
					disconnectFrom(node);
			}
	};

	// connect to existing links
	//! \see ObjectTraits/NodeLinkTrait
	foreach(node.getLinkedNodes(roleName) as var cNode)
		connectTo(cNode);

	updateLockedAxes();
};

trait.allowRemoval();
trait.onRemove += fn(node){
	node.lockAxisEnabled(false);
};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "active",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.lockAxisEnabled
			},
			GUI.NEXT_ROW,
			"Position: ",
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "x",
				GUI.SIZE : [GUI.WIDTH_ABS | GUI.HEIGHT_ABS,30,15 ],
				GUI.DATA_WRAPPER : node.lockXAxis
			},
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "y",
				GUI.SIZE : [GUI.WIDTH_ABS | GUI.HEIGHT_ABS,30,15 ],
				GUI.DATA_WRAPPER : node.lockYAxis
			},
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "z",
				GUI.SIZE : [GUI.WIDTH_ABS | GUI.HEIGHT_ABS,30,15 ],
				GUI.DATA_WRAPPER : node.lockZAxis
			},
			GUI.NEXT_ROW,
			"Rotation: ",
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "x",
				GUI.SIZE : [GUI.WIDTH_ABS | GUI.HEIGHT_ABS,30,15 ],
				GUI.DATA_WRAPPER : node.lockXRot
			},
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "y",
				GUI.SIZE : [GUI.WIDTH_ABS | GUI.HEIGHT_ABS,30,15 ],
				GUI.DATA_WRAPPER : node.lockYRot
			},
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "z",
				GUI.SIZE : [GUI.WIDTH_ABS | GUI.HEIGHT_ABS,30,15 ],
				GUI.DATA_WRAPPER : node.lockZRot
			},
		];
	});
});

return trait;

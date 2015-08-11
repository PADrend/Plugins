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


static PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.onInit += fn(MinSG.Node node){
	node.followCamera_offset := node.getNodeAttributeWrapper('followCamera_offset', "0 0 0" );
	node.followCameraEnabled := new DataWrapper(false);
	node.__followCameraRevoce := new DataWrapper(false);
	
	var dolly = PADrend.getDolly();
	
	node.followCamera_update := [node] => fn(node, dolly, ...) {
		if(!node || !node.isSet($__followCameraRevoce) || node.__followCameraRevoce())
			return $REMOVE;
		if(!node.followCameraEnabled())
			return;
		var offset = new Geometry.Vec3( node.followCamera_offset().split(" ")... );
		node.setWorldTransformation(dolly.getWorldTransformationSRT().translateLocal(offset));
	};
	
	node.followCamera_offset.onDataChanged += [dolly] => (node->node.followCamera_update) ;
	node.followCameraEnabled.onDataChanged += [dolly] => (node->node.followCamera_update) ;
	
	//! \see  MinSG.TransformationObserverTrait
	Std.Traits.assureTrait(dolly, module('LibMinSGExt/Traits/TransformationObserverTrait'));
	dolly.onNodeTransformed += node.followCamera_update;
	
	node.followCameraEnabled(true);
};

trait.allowRemoval();

trait.onRemove += fn(node){
	node.followCameraEnabled(false);
	node.__followCameraRevoce(true);
};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait, fn(node,refreshCallback){
		var entries = [
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "active",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.followCameraEnabled
			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.DATA_WRAPPER : node.followCamera_offset,
				GUI.LABEL : "Offset [x y z]",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
			}
		];
		return entries;
	});
});

return trait;


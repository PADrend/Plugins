/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Sascha Brandt <myet@mail.uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

 
 var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
 static trait = new PersistentNodeTrait(module.getId());

 trait.onInit += fn(MinSG.Node node){   
   	Traits.assureTrait(node,module('./_AnimatedBaseTrait'));
 };

 trait.allowRemoval();
 trait.onRemove += fn(node){
   // Reset to defaults
   node.animFrustumCulling(false);
   node.animFrustumCullingRate(0);
   node.animCullDistMin(0);
   node.animCullDist(0);
   outln("Remove Cull Animation");
 };

 module.on('../ObjectTraitRegistry', fn(registry){
 	registry.registerTrait(trait);
 	registry.registerTraitConfigGUI(trait, fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Frustum Culling",
				GUI.WIDTH : 200,
				GUI.DATA_WRAPPER : node.animFrustumCulling
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0, 10],
				GUI.LABEL : "Rate",
				GUI.WIDTH : 200,
				GUI.DATA_WRAPPER : node.animFrustumCullingRate
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
      "----",
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
      "Cull Distance",
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0, 1000],
				GUI.LABEL : "Min",
				GUI.WIDTH : 200,
				GUI.DATA_WRAPPER : node.animCullDistMin
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0, 1000],
				GUI.LABEL : "Max",
				GUI.WIDTH : 200,
				GUI.DATA_WRAPPER : node.animCullDist
			},
		];
 	});
 });


 return trait;

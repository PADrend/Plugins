/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Sascha Brandt <myeti@uni-paderborn.de>
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

 	node.pathMax := node.getNodeAttributeWrapper('pathMax',1.0);
 	node.pathMin := node.getNodeAttributeWrapper('pathMin',0.0);

	node.setPathRange := fn(Number min, Number max, ...) {
		this.pathMin(min);
		this.pathMax(max);
	};
 };

 trait.allowRemoval();

 module.on('../ObjectTraitRegistry', fn(registry){
 	registry.registerTrait(trait);
 	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
 		return [
 			{
 				GUI.TYPE : GUI.TYPE_NUMBER,
 				GUI.LABEL : "min",
 				GUI.SIZE : [GUI.WIDTH_FILL_REL | GUI.HEIGHT_ABS,0.5,15 ],
 				GUI.DATA_WRAPPER : node.pathMin
 			},
 			{
 				GUI.TYPE : GUI.TYPE_NUMBER,
 				GUI.LABEL : "max",
 				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
 				GUI.DATA_WRAPPER : node.pathMax
 			},
 		];
 	});
 });

 return trait;

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
    

    Links
		...

	Properties
		linkNames

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


static trait = new MinSG.PersistentNodeTrait('ObjectTraits/NodeLinkHighlightTrait');

trait.onInit += fn(MinSG.Node node){

	node.__NodeLinkHighlightTrait_revoce := new (Std.require('Std/MultiProcedure'));
	
	//! \see ObjectTraits/NodeLinkTrait
    @(once) static NodeLinkTrait = Std.require('ObjectTraits/NodeLinkTrait');
	if(!Traits.queryTrait(node,NodeLinkTrait))
		Traits.addTrait(node,NodeLinkTrait);

	static linkedNodeState;
	@(once){
		linkedNodeState = new MinSG.PolygonModeState;
		
		
		linkedNodeState.setParameters(linkedNodeState.getParameters().setMode(Rendering.PolygonModeParameters.POINT));
		linkedNodeState.setTempState(true);
	}
	
	static update = [node]=>fn(node,...){
		node.__NodeLinkHighlightTrait_revoce();
		
		//! \see ObjectTraits/NodeLinkTrait
		foreach(node.getLinkedNodes() as var n){
			node.__NodeLinkHighlightTrait_revoce += addRevocably( n, linkedNodeState);
			
			n.deactivate();
			node.__NodeLinkHighlightTrait_revoce += [n] => fn(node){ node.activate(); return $REMOVE;	};
		}
		
	};

	//! \see ObjectTraits/NodeLinkTrait
	node.onNodesLinked += update;
	//! \see ObjectTraits/NodeLinkTrait
	node.onNodesUnlinked += update;

	update();

};

trait.allowRemoval();

trait.onRemove += fn(node){
	node.__NodeLinkHighlightTrait_revoce();
};

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
		];
	});
});

return trait;


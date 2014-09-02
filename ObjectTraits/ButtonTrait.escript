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
 
 
 /*
     Use global listener, broadcast and time
 
 */

static trait = new (Std.require('LibMinSGExt/Traits/PersistentNodeTrait'))('ObjectTraits/ButtonTrait');

trait.onInit += fn(MinSG.Node node){

	@(once) static NodeLinkTrait = Std.require('ObjectTraits/NodeLinkTrait');

	if(!Traits.queryTrait(node,NodeLinkTrait))
		Traits.addTrait(node,NodeLinkTrait);	
	
	node.buttonFn1 := node.getNodeAttributeWrapper('buttonFn1', "animationPlay" );
	node.buttonFn2 := node.getNodeAttributeWrapper('buttonFn2', "animationPause" );
	node.buttonLinkRole := node.getNodeAttributeWrapper('buttonLinkRole', "switch" );
	
	//! \see ObjectTraits/NodeLinkTrait
	node.availableLinkRoleNames += "switch";
	
	node.buttonState := new DataWrapper(false);
	node.buttonState.onDataChanged += [node]=>fn(node, value){
		if(value) //! TEMP!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			node.setRelScaling(1.5);
		else
			node.setRelScaling(1.0);
		var time = PADrend.getSyncClock();
		
		//! \see ObjectTraits/NodeLinkTrait
		var nodes = node.getLinkedNodes( node.buttonLinkRole() );
	
		var fnName = value ? node.buttonFn1() : node.buttonFn2();
		if(node.buttonFn2().empty())
			fnName = node.buttonFn1();
		
		if(!fnName.empty()){
			foreach(nodes as var node){
				try{
					(node->node.getAttribute(fnName))(time);
				}catch(e){
					Runtime.warn(e);
				}
			}
		}
	};
	
	node.onClick := fn(evt){
		var ctxt = Util.requirePlugin( 'PADrend/SystemUI').getEventContext();
		if( evt.button == 0 && !ctxt.isAltPressed() && !ctxt.isCtrlPressed() )
			this.buttonState(!this.buttonState());
	};
	
};

trait.allowRemoval();
trait.onRemove += fn(node){
	node.buttonFn1(void);
	node.buttonFn2(void);
	node.buttonLinkRole(void);
};

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [ 
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "active",
				GUI.WIDTH : 200,
				GUI.DATA_WRAPPER : node.buttonState
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "fn1",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.buttonFn1
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "fn2",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.buttonFn2
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "linkRole",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.buttonLinkRole
			},	
			
		];
	});
});

return trait;

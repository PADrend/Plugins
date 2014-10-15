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

var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

static TreeQuery = module('LibMinSGExt/TreeQuery');
static queryRelNodes = fn(MinSG.Node source,String query){
	return TreeQuery.execute(query,PADrend.getSceneManager(),[source]).toArray();
};
static createRelativeNodeQuery = fn(MinSG.Node source,MinSG.Node target){
	return TreeQuery.createRelativeNodeQuery(PADrend.getSceneManager(),source,target);
};


trait.onInit += fn(MinSG.Node node){

	Traits.assureTrait(node,module('../Basic/NodeLinkTrait'));
	
	node.buttonFn1 := node.getNodeAttributeWrapper('buttonFn1', "animationPlay" );
	node.buttonFn2 := node.getNodeAttributeWrapper('buttonFn2', "animationPause" );
	node.buttonLinkRole := node.getNodeAttributeWrapper('buttonLinkRole', "switch" );
	
	//! \see ObjectTraits/NodeLinkTrait
	node.availableLinkRoleNames += "switch";
	
	node.buttonState := new DataWrapper(false);
	node._buttonFixedNextSwitchTime := void; // internal
	node.buttonState.onDataChanged += [node]=>fn(node, value){
		if(value) //! TEMP!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			node.setRelScaling(1.5);
		else
			node.setRelScaling(1.0);
		var time;
		if(node._buttonFixedNextSwitchTime) {
			time = node._buttonFixedNextSwitchTime;
			node._buttonFixedNextSwitchTime = void;
		}else{
			time = PADrend.getSyncClock();
			// distribute
			var pathToButton = createRelativeNodeQuery(PADrend.getCurrentScene(),node);
			
			@(once) static CommandHandling = Util.requirePlugin('PADrend/CommandHandling');
			CommandHandling.executeRemoteCommand( [pathToButton,time,value]=>fn(pathToButton,time,value){
				var button = Std.require('LibMinSGExt/TreeQuery').execute(pathToButton,PADrend.getSceneManager(),[PADrend.getCurrentScene()]).toArray().front();
				button._buttonFixedNextSwitchTime = time;
				button.buttonState(value);
			} );
			
			outln("Switch remote: ",pathToButton," ",time," ",value);
		}
		
		
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

module.on('../ObjectTraitRegistry', fn(registry){
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

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Spielerei/AnimationPlugin/Animations/NodeAnimation.escript
 ** 2011-04 Claudius
 **
 ** abstract NodeAnimation-Type
 **/

static AnimationBase = module('./AnimationBase');

// NodeAnimation ---|> AnimationBase
static T = new Type(AnimationBase);

Traits.addTrait(T,Traits.PrintableNameTrait,$NodeAnimation);

T.nodeId := "";

T.typeName ::= "NodeAnimation";

//! (ctor)
T._constructor ::= fn(_name="NodeAnimation",_startTime=0,_duration=1)@(super(_name,_startTime,_duration)){
	this.__status.node := void;
};

//! ---|> AnimationBase
T.doEnter @(override) ::= fn(){
	// call base type's function.
	(this->AnimationBase.doEnter)();

	if(!this.nodeId.empty()){
		this.__status.node = this.findNode();
		if(!this.__status.node){
			Runtime.warn("Node not found: '"+this.nodeId+"'");
		}
	}
};

////! ---|> AnimationBase
//T.doLeave ::= fn(){
//	// call base type's function.
//	(this->Animation.AnimationBase.doLeave)();
//	this.__status.node := void;
//};

//! ---|> AnimationBase
T.undo @(override) ::= fn(){
	this.__status.node := void;
	
	// call base type's function.
	(this->AnimationBase.undo)();
};

//! ---|> AnimationBase
T.getInfo @(override) ::= fn(){
	return (this->AnimationBase.getInfo)() + "\nNode:"+getNodeId();	
};
	
T.getNodeId ::= fn(){
	return this.nodeId;
};

T.getNode ::= fn(){
	return this.__status.node;
};

T.findNode ::= fn(){
	return PADrend.getSceneManager().getRegisteredNode(this.nodeId);
};

T.setNodeId ::= fn(String newNodeId){
	if(newNodeId!=this.nodeId){
		var wasActive = this.nodeId;
		// make shure that the old node is reverted to its original state
		if(wasActive){
			this.__status.active = false;
			this.undo();
		}
			
		this.nodeId = newNodeId;
		this._updated($NODE_ID_CHANGED,newNodeId);	
		
		//  if animation is currently active, apply changes immediately 
		if(wasActive){
			this.execute(this.__status.lastTime);
		}
	}
};

//! Try to select currently selected node, returns true on success.
T.setSelectedNode ::= fn(){
	var n = NodeEditor.getSelectedNode();
	if(!n){
		return false;
	}
	var id = PADrend.getSceneManager().getNameOfRegisteredNode(n);
	if(!id){
		return false;
	}
	this.setNodeId(id);
	return true;
};

PADrend.Serialization.registerType( T, "Animation.NodeAnimation")
	.initFrom( PADrend.Serialization.getTypeHandler(AnimationBase) ) //! --|> AnimationBase
	.addDescriber( fn(ctxt,T obj,Map d){		d['nodeId'] = obj.getNodeId();	})
	.addInitializer( fn(ctxt,T obj,Map d){	obj.setNodeId(d['nodeId']);	});

// -----------------------------------------------------------------
// GUI

//! ---o
T.getMenuEntries @(override) := fn(storyBoardPanel){
	// call base type's function.
	var m = (this->AnimationBase.getMenuEntries)(storyBoardPanel);
	m+="----";
	var idInput = gui.create({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "NodeId",
		GUI.WIDTH : 150,
		GUI.DATA_VALUE : this.getNodeId(),
		GUI.ON_DATA_CHANGED : this->fn(data){
			this.setNodeId(data);
		}
	});	
	m+=idInput;
	m+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Get id of selected node",
		GUI.WIDTH : 150,
		GUI.ON_CLICK : [this,idInput]->fn(){
			var n = NodeEditor.getSelectedNode();
			if(!n){
				Runtime.warn("No node selected.");
				return;
			}
			var id = PADrend.getSceneManager().getNameOfRegisteredNode(n);
			if(!id){
				Runtime.warn("Selected node has no id.");
				return;
			}
			this[0].setNodeId(id);
			this[1].setData(id);
		}
	};
	m+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Select Node",
		GUI.WIDTH : 150,
		GUI.ON_CLICK : this->fn(){
			var n = PADrend.getSceneManager().getRegisteredNode(this.getNodeId());
			if(!n){
				Runtime.warn("No node selected.");
			}else{
				NodeEditor.selectNode(n);
			}
		}
	};
	return m;
};

return T;

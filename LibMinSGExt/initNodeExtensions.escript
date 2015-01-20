/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[LibMinSGExt] NodeExtensions.escript
 **
 **  Node extensions
 **/

// ---------------------------
// Node extension


/*! Anchors \deprecated Use NodeAnchors-module instead */
static NodeAnchors = module('./NodeAnchors');

//! Create and return a new anchor-DataWrapper (see description above) 		\deprecated Use NodeAnchors.createAnchor instead 
MinSG.Node.createAnchor ::= 	fn(p...){		return NodeAnchors.createAnchor(this,p...);		};

//! Returns the node's anchor-DataWrapper with the given  @p name or void.	 \deprecated Use NodeAnchors.getAnchor instead 
MinSG.Node.getAnchor ::= 		fn(p...){		return NodeAnchors.getAnchor(this,p...);		};

//! Return a map of the node's anchor-DataWrappers							 \deprecated Use NodeAnchors.getAnchors instead 
MinSG.Node.getAnchors ::= 		fn(p...){		return NodeAnchors.getAnchors(this,p...);		};

//! Returns the node's or its prototype's anchor-DataWrapper with the given @p name or void.	 \deprecated Use NodeAnchors.findAnchor instead 
MinSG.Node.findAnchor ::= 		fn(p...){		return NodeAnchors.findAnchor(this,p...);		};

//! Return a map of the node's (and its prototype's) anchor-DataWrappers	 \deprecated Use NodeAnchors.findAnchors instead 
MinSG.Node.findAnchors ::= 		fn(p...){		return NodeAnchors.findAnchors(this,p...);		};

//! Sets the anchor-DataWrapper with the given @p name to false -- it then no longer stored as node attribute.  \deprecated Use NodeAnchors.invalidateAnchor instead 
MinSG.Node.invalidateAnchor ::= fn(p...){		return NodeAnchors.invalidateAnchor(this,p...);		};

// -------------

MinSG.Node.getNodeAttributeWrapper ::= fn(String key, defaultValue=void){
	var wrapper = DataWrapper.createFromFunctions(
		[this,key] => fn(node,key){			return node.findNodeAttribute(key); },
		[this,key] => fn(node,key,value){	node.setNodeAttribute(key,value); }
	);
	if(void==wrapper() && void!=defaultValue)
		wrapper(defaultValue);
	return wrapper;
};

MinSG.State.getStateAttributeWrapper ::= fn(String key, defaultValue=void){
	var wrapper = DataWrapper.createFromFunctions(
		[this,key] => fn(node,key){			return node.getStateAttribute(key); },
		[this,key] => fn(node,key,value){	node.setStateAttribute(key,value); }
	);
	if(void==wrapper() && void!=defaultValue)
		wrapper(defaultValue);
	return wrapper;
};

/*! Calls the given function for every node in the subtree with the node as parameter. 
	If the function returns $BREAK_TRAVERSAL for a node, the corresponding subtree is skipped.
	If the funciton returns $EXIT_TRAVERSAL, the traversal is stopped. 
	All other return values are ignored. */
MinSG.Node.traverse ::= fn(fun){
	var nodes=[this];
	while(!nodes.empty()){
		var node=nodes.popBack();
		var result = fun(node);
		if(result == $BREAK_TRAVERSAL){
			continue;
		}else if(result == $EXIT_TRAVERSAL){
			break;
		}// else CONTINUE_TRAVERSAL
		nodes.append(MinSG.getChildNodes(node));
	}
	return this;
};


/*! Calls the given function for every State in the subtree (including States contained in GroupStates).
	The parameter of the called function are the container (Node or GroupState) and the State.
	If the function returns $BREAK_TRAVERSAL for a GroupState, the corresponding subtree is skipped.
	If the funciton returns $EXIT_TRAVERSAL, the traversal is stopped. 
	All other return values are ignored. 
	\code
		subtreeRoot.traverseStates( fn(container,state){outln(container,":",state);} );
	*/
MinSG.Node.traverseStates ::= fn(fun){
	var stateContainers = [this];
	while(!stateContainers.empty()){
		var stateContainer = stateContainers.popBack();
		foreach(stateContainer.getStates() as var state){
			var result = fun(stateContainer,state);
			if(result == $BREAK_TRAVERSAL){
				continue;
			}else if(result == $EXIT_TRAVERSAL){
				break;
			}// else CONTINUE_TRAVERSAL
			if(state ---|>MinSG.GroupState){
				stateContainers+=state;
			}
		}
		if(stateContainer---|>MinSG.GroupNode){
			stateContainers.append( MinSG.getChildNodes(stateContainer) );
		}
	}
	return this;
};

MinSG.Node."+=" ::= fn( MinSG.State obj){
	this.addState(obj);
	return this;
};

MinSG.Node."-=" ::= fn( MinSG.State obj){
	this.removeState(obj);
	return this;
};

MinSG.GroupNode."+=" ::= fn( [MinSG.Node,MinSG.State] obj){
	if(obj.isA(MinSG.Node)){
		this.addChild(obj);
	}else{
		this.addState(obj);
	}
	return this;
};

MinSG.GroupNode."-=" ::= fn( [MinSG.Node,MinSG.State] obj){
	if(obj.isA(MinSG.Node)){
		this.removeChild(obj);
	}else{
		this.removeState(obj);
	}
	return this;
};

MinSG.Node.getPivotPosition ::= fn(){
	if(MinSG.isSet($JointNode)) {
		if(this.isA(MinSG.JointNode)) {
			return this.getWorldOrigin();
		}
	}
	 
	return this.getWorldBB().getCenter();
};

MinSG.Node.getOriginalNode ::= fn(){
	var n = this.getPrototype();
	return n ? n : this;
};

MinSG.Node.getBoundingBox ::= MinSG.Node.getBB;
MinSG.Node.getWorldBoundingBox ::= MinSG.Node.getWorldBB;

// --------------

MinSG.GroupState."+=" ::= fn( MinSG.State obj){
	this.addState(obj);
	return this;
};

MinSG.GroupState."-=" ::= fn( MinSG.State obj){
	this.removeState(obj);
	return this;
};

// --------------
MinSG.AbstractCameraNode.setNearPlane ::= fn(Number distance){
	return this.setNearFar( distance, this.getFarPlane() );
};
MinSG.AbstractCameraNode.setFarPlane ::= fn(Number distance){
	return this.setNearFar(  this.getNearPlane(),distance );
};

return true;

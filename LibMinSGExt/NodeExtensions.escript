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


/*! Anchors
	Anchors are locations (Vec3 or SRT) stored in a Node in Node-local coordinates.
	They can be used as pivot points, for snapping, as marker, etc.
	Anchors are accessed by DataWrappers containing a Vec3, SRT or false (for invalid anchors). They are automatically stored as node attribute.
	
	\code
		// add an unitialized 'snappingPoint' anchor to A node:
		myNode.createAnchor('snappingPoint');
		// ...
		myNode.getAnchor('snappingPoint')(new Geometry.Vec3(1,2,3)); // update the anchor's location
	\endcode
	
	Internal nodeAttribute format:
		type: string (json encoded)
		value: '{ 	"AttrName for Vec3 anchor" : [x,y,z],
					"AttrName for SRT anchor" : [x,y,z,xd,yd,zd,xup,yup,zup],
					...	}'
*/

//! (internal) Set anchor wrappers as node attribute
MinSG.Node._updateAnchorAttributes @(private) ::= fn(...){
	if(!this.isSet($__anchors)){
		return; // should not happen...
	}
	var m = new Map;
	foreach(this.__anchors as var anchorName,var anchorWrapper){
		var location = anchorWrapper();
		if(!location){
			continue;
		}else if(location---|>Geometry.Vec3){
			m[anchorName] = location.toArray();
		}else if(location---|>Geometry.SRT){
			var a = location.getTranslation().toArray();
			a.append( location.getDirVector().toArray() );
			a.append( location.getUpVector().toArray() );
			m[anchorName] = a;
		}else{
			Runtime.warn("MinSG.Node._updateAnchorAttributes: invalid anchor data: '"+location+"'");
		}
	}
	if(m.empty()){
		this.unsetNodeAttribute('anchors');
	}else{
		this.setNodeAttribute('anchors',toJSON(m,false));
	}

};
/*! (internal) Init anchor wrappers from node attribute
	@return true iff there are anchors
*/
MinSG.Node._initAnchors @(private) ::= fn(){
	if(this.isSet($__anchors)) // already initialized
		return true;
	var attr = this.getNodeAttribute('anchors');
	if(!attr) // no anchors present
		return false;

	var m = parseJSON(attr); // { name : [numbers*] }
	if(!m---|>Map){
		Runtime.warn("MinSG.Node._initAnchors: invalid anchor data: '"+attr+"'");
		return false;
	}
	this.__anchors := new Map;
	foreach(m as var attrName, var locationValues){
		var location;
		if(locationValues.count()==3){
			location = new Geometry.Vec3(locationValues);
		}else if(locationValues.count()==9){
			location = new Geometry.SRT( 
								new Geometry.Vec3(locationValues[0],locationValues[1],locationValues[2]),	// pos
								new Geometry.Vec3(locationValues[3],locationValues[4],locationValues[5]),	// dir
								new Geometry.Vec3(locationValues[6],locationValues[7],locationValues[8]));	// up
		}else{
			Runtime.warn("MinSG.Node._initAnchors: invalid value data: '"+locationValues+"'");
			continue;
		}
		var anchor = DataWrapper.createFromValue( location );
		anchor.onDataChanged += this->this._updateAnchorAttributes;
		this.__anchors[attrName] = anchor;
	}
	return true;
};

//! Create and return a new anchor-DataWrapper (see description above)
MinSG.Node.createAnchor ::= fn(String anchorName, [Geometry.Vec3,Geometry.SRT,false] location=false){
	if(!_initAnchors()){ // this is the first anchor
		this.__anchors := new Map;
	}
	var anchor = getAnchor(anchorName);
	if(!anchor){
		// create new anchor
		anchor = DataWrapper.createFromValue( void );
		anchor.onDataChanged += this->this._updateAnchorAttributes;
		this.__anchors[anchorName] = anchor;
	}
	anchor(location);
	return anchor;
};

//! Returns the node's anchor-DataWrapper with the given  @p name or void.
MinSG.Node.getAnchor ::= fn(String anchorName){
	return this._initAnchors() ? this.__anchors[anchorName] : void;
};
//! Return a map of the node's anchor-DataWrappers
MinSG.Node.getAnchors ::= fn(){
	return this._initAnchors() ? this.__anchors.clone() : new Map;
};
//! Returns the node's or its prototype's anchor-DataWrapper with the given @p name or void.
MinSG.Node.findAnchor ::= fn(String anchorName){
	var anchor;
	if( this._initAnchors() ) 
		anchor = this.__anchors[anchorName];
	if( !anchor && this.isInstance() )
		anchor = this.getPrototype().getAnchor(anchorName);
	return anchor;
};
//! Return a map of the node's (and its prototype's) anchor-DataWrappers
MinSG.Node.findAnchors ::= fn(){
	return this.isInstance() ? this.getPrototype().getAnchors().merge( this.getAnchors() ) : this.getAnchors();
};
//! Sets the anchor-DataWrapper with the given @p name to false -- it then no longer stored as node attribute.
MinSG.Node.invalidateAnchor ::= fn(String anchorName){
	var anchor = this.getAnchor(anchorName);
	if(anchor)
		anchor(false);
};

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
	if(obj---|>MinSG.Node){
		this.addChild(obj);
	}else{
		this.addState(obj);
	}
	return this;
};

MinSG.GroupNode."-=" ::= fn( [MinSG.Node,MinSG.State] obj){
	if(obj---|>MinSG.Node){
		this.removeChild(obj);
	}else{
		this.removeState(obj);
	}
	return this;
};

MinSG.Node.getPivotPosition ::= fn()
{
    if(MinSG.isSet($JointNode)) {
        if(this ---|> MinSG.JointNode) {
            return this.getWorldOrigin();
        }
    }
     
    return this.getWorldBB().getCenter();
};

MinSG.Node.getOriginalNode ::= fn(){
	var n = this.getPrototype();
	return n ? n : this;
};

// --------------

MinSG.GroupState."+=" ::= fn( MinSG.State obj){
	this.addState(obj);
	return this;
};

MinSG.GroupState."-=" ::= fn( MinSG.State obj){
	this.removeState(obj);
	return this;
};

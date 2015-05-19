/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static NodeAnchors = new Namespace;
 
/*! Anchors
	Anchors are locations (Vec3 or SRT) stored in a Node in Node-local coordinates.
	They can be used as pivot points, for snapping, as marker, etc.
	Anchors are accessed by DataWrappers containing a Vec3, SRT or false (for invalid anchors). They are automatically stored as node attribute.
	
	\code
		// add an unitialized 'snappingPoint' anchor to A node:
		NodeAnchors.createAnchor(myNode,'snappingPoint');
		// ...
		NodeAnchors.getAnchor(myNode,'snappingPoint')(new Geometry.Vec3(1,2,3)); // update the anchor's location
	\endcode
	
	Internal nodeAttribute format:
		type: string (json encoded)
		value: '{ 	"AttrName for Vec3 anchor" : [x,y,z],
					"AttrName for SRT anchor" : [x,y,z,xd,yd,zd,xup,yup,zup],
					...	}'
*/

static NODE_ATTR_ANCHORS = 'anchors';

//! (internal) Set anchor wrappers as node attribute
static updateAnchorAttributes = fn(node,...){
	if(!node.isSet($__anchors)){
		return; // should not happen...
	}
	var m = new Map;
	foreach(node.__anchors as var anchorName,var anchorWrapper){
		var location = anchorWrapper();
		if(!location){
			continue;
		}else if(location.isA(Geometry.Vec3)){
			m[anchorName] = location.toArray();
		}else if(location.isA(Geometry.SRT)){
			var a = location.getTranslation().toArray();
			a.append( location.getDirVector().toArray() );
			a.append( location.getUpVector().toArray() );
			m[anchorName] = a;
		}else{
			Runtime.warn("updateAnchorAttributes: invalid anchor data: '"+location+"'");
		}
	}
	if(m.empty()){
		node.unsetNodeAttribute(NODE_ATTR_ANCHORS);
	}else{
		node.setNodeAttribute(NODE_ATTR_ANCHORS,toJSON(m,false));
	}

};
/*! (internal) Init anchor wrappers from node attribute
	@return true iff there are anchors
*/
static initAnchors = fn(node){
	if(node.isSet($__anchors)) // already initialized
		return node;
	var attr = node.getNodeAttribute(NODE_ATTR_ANCHORS);
	if(!attr) // no anchors present
		return false;

	var m = parseJSON(attr); // { name : [numbers*] }
	if(!m.isA(Map)){
		Runtime.warn("MinSG.Node._initAnchors: invalid anchor data: '"+attr+"'");
		return false;
	}
	node.__anchors := new Map;
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
		var anchor = new Std.DataWrapper( location );
		anchor.onDataChanged += [node] => updateAnchorAttributes;
		node.__anchors[attrName] = anchor;
	}
	return true;
};

//! Create and return a new anchor-DataWrapper (see description above)
NodeAnchors.createAnchor := fn(MinSG.Node node,String anchorName, [Geometry.Vec3,Geometry.SRT,false] location=false){
	if(!initAnchors(node)){ // this is the first anchor
		node.__anchors := new Map;
	}
	var anchor = NodeAnchors.getAnchor(node,anchorName);
	if(!anchor){
		// create new anchor
		anchor = new Std.DataWrapper( void );
		anchor.onDataChanged += [node] => updateAnchorAttributes;
		node.__anchors[anchorName] = anchor;
	}
	anchor(location);
	return anchor;
};

//! Returns the node's anchor-DataWrapper with the given  @p name or void.
NodeAnchors.getAnchor := fn(MinSG.Node node,String anchorName){
	return initAnchors(node) ? node.__anchors[anchorName] : void;
};
//! Return a map of the node's anchor-DataWrappers
NodeAnchors.getAnchors := fn(MinSG.Node node){
	return initAnchors(node) ? node.__anchors.clone() : new Map;
};
//! Returns the node's or its prototype's anchor-DataWrapper with the given @p name or void.
NodeAnchors.findAnchor := fn(MinSG.Node node,String anchorName){
	var anchor;
	if( initAnchors(node) ) 
		anchor = node.__anchors[anchorName];
	if( !anchor && node.isInstance() )
		anchor = NodeAnchors.getAnchor( node.getPrototype(),anchorName );
	return anchor;
};
//! Return a map of the node's (and its prototype's) anchor-DataWrappers
NodeAnchors.findAnchors := fn(MinSG.Node node){
	return node.isInstance() ? 
					NodeAnchors.getAnchors( node.getPrototype() ).merge( NodeAnchors.getAnchors( node ) ) : 
					NodeAnchors.getAnchors( node );
};
//! Sets the anchor-DataWrapper with the given @p name to false -- it then no longer stored as node attribute.
NodeAnchors.invalidateAnchor := fn(MinSG.Node node,String anchorName){
	var anchor = NodeAnchors.getAnchor(node, anchorName);
	if(anchor)
		anchor(false);
};

return NodeAnchors;

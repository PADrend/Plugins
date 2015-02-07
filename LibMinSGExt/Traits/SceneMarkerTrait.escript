/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

 
/*! Marks a node as representing a separate virtual scene.
	To locate the scene, a ndoe lies in, you can use the following:
	
	\code
	var scene;
	var t = Std.require('LibMinSGExt/Traits/SceneMarkerTrait');
	for(var n = node; n; n=n.getParent())
		if( Std.Traits.queryTrait(n, t) )
			scene = n;
	
	outln("Node '",node,"' lies in scene '"+scene+"'");
	\endcode
	
	Parameters:
		[optional] ExtObject to store scene specific data at the node.
	Adds the following attributes:
	 - sceneData  	ExtObject to store scene specific data at the node.		*/

var trait = new Std.Traits.GenericTrait(module.getId());
trait.onInit += fn(MinSG.Node node, [ExtObject,void] dataObject=void){
	node.sceneData := dataObject?dataObject : new ExtObject;
};

return trait;

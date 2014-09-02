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


/*! After a node is removed from the node's subtree, node.onNodeRemoved(parent, removedNode) is called.
	Parameters:
		[optional] functions that are initially added to the observer MultiProcedure.
	Adds the following attributes:
	 - onNodeRemoved  	MultiProcedure		*/
MinSG.NodeRemovedObserverTrait := new Traits.GenericTrait('MinSG.NodeRemovedObserverTrait');
{
	var t = MinSG.NodeRemovedObserverTrait;
	t.attributes.onNodeRemoved @(init) := MultiProcedure;
	t.onInit += fn(MinSG.Node node,p...){
		node._enableNodeRemovedObserver();
		foreach(p as var fun)
			node.onNodeRemoved += fun;
	};
}

return MinSG.NodeRemovedObserverTrait;

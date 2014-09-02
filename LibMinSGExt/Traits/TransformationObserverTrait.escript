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

/*! Each transformation of a node in the node's subtree invokes a call to node.onNodeTransformed(transformedNode).
	Parameters:
		[optional] functions that are initially added to the observer MultiProcedure.
	Adds the following attributes:
	 - onNodeTransformed  	MultiProcedure		*/
MinSG.TransformationObserverTrait := new Traits.GenericTrait('MinSG.TransformationObserverTrait');
{
	var t = MinSG.TransformationObserverTrait;
	t.attributes.onNodeTransformed @(init) := MultiProcedure;
	t.onInit += fn(MinSG.Node node,p...){
		node._enableTransformationObserver();
		foreach(p as var fun)
			node.onNodeTransformed += fun;
	};
}

return MinSG.TransformationObserverTrait;

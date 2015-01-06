/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
 /*! 
		[LibMinSGExt] SemanticObject.escript
		
		Helper functions for marking Nodes as semantic objects.
 */

var NS = new Namespace;

static NODE_ATTR_IS_SEMANTIC_OBJ = 'sObj';

NS.markAsSemanticObject := fn(MinSG.Node node,Bool b=true){
	if(b){
		node.setNodeAttribute(NODE_ATTR_IS_SEMANTIC_OBJ,true);
	}else{
		node.unsetNodeAttribute(NODE_ATTR_IS_SEMANTIC_OBJ);
	}
};

NS.isSemanticObject := fn(MinSG.Node node){
	return node.findNodeAttribute(NODE_ATTR_IS_SEMANTIC_OBJ);
};

NS.getContainingSemanticObject := fn(MinSG.Node node){
	for(node = node.getParent(); node ; node = node.getParent()){
		if( node.findNodeAttribute(NODE_ATTR_IS_SEMANTIC_OBJ) )
			return node;
	}
	return void;
};

NS.collectNextSemanticObjects := fn(MinSG.Node node){
	return MinSG.collectNextNodesReferencingAttribute(node,NODE_ATTR_IS_SEMANTIC_OBJ);
};

//! Returns the tightest semantic object containing nodes @p node1 and @p node2 or void.
NS.getCommonSemanticObject := fn(MinSG.Node node1, MinSG.Node node2){
	var sObjs1 = new Set;
	for(var n = node1; n ; n=n.getParent()){
		if(isSemanticObject(n))
			sObjs1 += n;
	}
	for(var n = node2; n ; n=n.getParent()){
		if(isSemanticObject(n)){
			if(sObjs1.contains(n))
				return n;
		}
	}
	return void;
};

return NS;

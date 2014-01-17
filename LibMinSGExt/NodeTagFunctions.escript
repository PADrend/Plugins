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

static ATTR_TAGS = "tags";

static getLocalTags = fn(MinSG.Node node){
	var attr = node.getAttribute(ATTR_TAGS);
	return attr---|>String ? attr.split(",") : [];
}

static setLocalTags = fn(MinSG.Node node,Array tags){
	if(tags.empty()){
		node.unsetNodeAttribute(ATTR_TAGS);
	}else{
		node.setNodeAttribute(ATTR_TAGS,tags.implode(","));
	}
}

static getTags = fn(MinSG.Node node){
	var tags = getLocalTags(node);
	if(node.isInstance()){
		foreach( getLocalTags(node.getPrototype()) as var tag )
			if(!tags.contains(tag))
				tags += tag;
	}
	return tags;
};

//! { node -> [tag*]}
static collectTaggedNodes = fn(MinSG.Node root){
	var taggedNodes = new Map; // node -> tags*
	foreach( MinGS.collectNodesReferencingAttribute(root,ATTR_TAGS) as var node)
		taggedNodes[node] = getTags(node);
	return taggedNodes
};

static collectNodesByTag = fn(MinSG.Node root, String tag){
	var nodes = [];
	foreach( collectTaggedNodes(root) as var node,var tags){
		if(tags.contains(tag))
			nodes += node
	}
	return nodes;
};

static addTag = fn(MinSG.Node node,String tag){
	var tags = getLocalTags(node);
	if(!tags.contains(tag)){
		tags+=tag;
		setLocalTags(node,tags);
	}
};

static removeLocalTag = fn(MinSG.Node node,String tag){
	setLocalTags(node,getLocalTags(node).removeValue(tag));
};

static clearLocalTags = fn(MinSG.Node node){
	setLocalTags(node,[]);
};

var Functions = new Namespace;
Functions.addTag := addTag;
Functions.clearLocalTags := clearLocalTags;
Functions.collectTaggedNodes := collectTaggedNodes;
Functions.collectNodesByTag := collectNodesByTag;
Functions.getTags := getTags;
Functions.getLocalTags := getLocalTags;
Functions.removeLocalTag := removeLocalTag;
return Functions;

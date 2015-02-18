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

//!	Collection of functions to store certain meta-information as node attributes.
static getDataWrapper = fn(String key,MinSG.Node node){
	if(!node.isSet($__metaInf))
		node.__metaInf := new Map;
	
	var __metaInf = node.__metaInf;
	if(!__metaInf[key]){
		var initialValue = node.getNodeAttribute(key);
		if(void===initialValue)
			initialValue = "";
		var d = new Std.DataWrapper( initialValue );
		d.onDataChanged += [node,key] => fn(node,key, value){	
			if(value=="" || void===value)
				node.unsetNodeAttribute(key);
			else
				node.setNodeAttribute(key,value);	
		};
		__metaInf[key] = d;
	}
	return __metaInf[key];

};
var query = fn(String key,MinSG.Node node, defaultValue=void){
	if(node.isSet($__metaInf)){
		var wrapper = node.__metaInf[key];
		if(wrapper)
			return ""==wrapper() ? defaultValue : wrapper();
	}
	var attr = node.getNodeAttribute(key);
	return void==attr ? defaultValue : attr;
};


var NS = new Namespace;
NS.accessMetaInfo_Author 			:= ["META_AUTHOR"] => getDataWrapper;
NS.accessMetaInfo_CreationDate 		:= ["META_CREATION_DATE"] => getDataWrapper;
NS.accessMetaInfo_License 			:= ["META_LICENSE"] => getDataWrapper;
NS.accessMetaInfo_Note 				:= ["META_NOTE"] => getDataWrapper;
NS.accessMetaInfo_Title 			:= ["META_NAME"] => getDataWrapper;
NS.queryMetaInfo_Author 			:= ["META_AUTHOR"] => query;
NS.queryMetaInfo_CreationDate 		:= ["META_CREATION_DATE"] => query;
NS.queryMetaInfo_License 			:= ["META_LICENSE"] => query;
NS.queryMetaInfo_Note 				:= ["META_NOTE"] => query;
NS.queryMetaInfo_Title 				:= ["META_NAME"] => query;

return NS;

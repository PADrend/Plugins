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

var plugin = new Plugin({
		Plugin.NAME : 'PADrend/RemoteControl',
		Plugin.DESCRIPTION : "Basic functions for remote control",
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend'],
		Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) := fn(){
	registerFunction(	'PADrend.about', fn(){
		return PADrend.about().implode("\n");
	});
	
	broadcast += this.callFunction;
		
	return true;
};

static rpcRegistry = new Map;

plugin.getFunction @(public) := fn(rpcName){
	return rpcRegistry[rpcName];
};

//! Can be extended from outside.
plugin.broadcast @(public) := new MultiProcedure; // fn( rpcname, parameters... )
	
plugin.callFunction @(public) := fn(rpcName, parameters...){
	var rpc = rpcRegistry[rpcName];
	if(!rpc){
		Runtime.warn("Invalid RPC: ",rpcName,"(",parameters.implode(","),")");
		return;
	}
	return rpc(parameters...);
};

plugin.registerFunction @(public) := fn(rpcName, fun){
	rpcRegistry[ ""+rpcName] = fun;
};

plugin.registerFunctions @(public) := fn(Map m){
	foreach(m as var name,var fun)
		rpcRegistry[ ""+name ] = fun;
};

return plugin;
// ------------------------------------------------------------------------------

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
		Plugin.EXTENSION_POINTS : [

			/* [ext:PADrend_RemoteControl_QueryRPCs]
			 * @param callback to call with a Map { rpcName -> rpcCallable }
			 */
			'PADrend_RemoteControl_QueryRPCs'
		]
});

plugin.init @(override) := fn(){
	registerExtension('PADrend_RemoteControl_QueryRPCs',this->fn(callback){
		callback( {
			'PADrend.about' : fn(){
				return PADrend.about().implode("\n");
			}
		});
	});
	
	return true;
};

plugin.rpcRegistry @(private) := void;

plugin.refreshFunctions @(public) := fn(){
	this.rpcRegistry = new Map;
	executeExtensions('PADrend_RemoteControl_QueryRPCs',[this.rpcRegistry] => fn(registry,Map rpcs){
		registry.merge(rpcs);
	});
};

plugin.getFunction @(public) := fn(rpcName){
	if(!this.rpcRegistry)
		this.refreshFunctions();
	return this.rpcRegistry[rpcName];
};
	
plugin.callFunction @(public) := fn(rpcName, parameters...){
	if(!this.rpcRegistry)
		this.refreshFunctions();
	var rpc = this.rpcRegistry[rpcName];
	if(!rpc){
		Runtime.warn("Invalid RPC: ",rpcName,"(",parameters.implode(","),")");
		return;
	}
	return rpc(parameters...);
};

return plugin;
// ------------------------------------------------------------------------------

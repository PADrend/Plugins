/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var plugin = new Plugin({
		Plugin.NAME : 'InstanceSyncing',
		Plugin.DESCRIPTION : "Basic plugin to sync properties between multiple PADrend instances over network.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius Jaehn",
		Plugin.OWNER : "Claudius Jaehn, Benjamin Eikel, Ralf Petring",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.REQUIRES : ['PADrend','PADrend/CommandHandling','PADrend/EventLoop'],
		Plugin.EXTENSION_POINTS : [	
			
			/* [ext:InstanceSyncing_AddServerFeatures]
			 * @param  InstanceSyncing.Server object
			 * @result  void
			 */
			'InstanceSyncing_AddServerFeatures',
		
			/* [ext:InstanceSyncing_AddClientFeatures]
			 * @param  InstanceSyncing.Client object
			 * @result  void
			 */
			'InstanceSyncing_AddClientFeatures',
		
		]
});

Std.Traits.addTrait(plugin,Util.ReloadablePluginTrait);	//!	\see Util.ReloadablePluginTrait

plugin.init @(override) := fn() {

	this.config := new (module('LibUtilExt/ConfigGroup'))(systemConfig,'MultiView');
	this.serverPort := Std.DataWrapper.createFromEntry(this.config,'port',2000);
	this.serverName := Std.DataWrapper.createFromEntry(this.config,'IP',"127.0.0.1");

	module('LibUtilExt/initNetworkUtils');
	module('./initBasicSyncFeatures'); // --> initFeatures
	module('./GUI'); 

	return true;
};

// ------------------------------

plugin.connectClient := fn(serverName,Number serverPort){
	var client = new (module('./Client'))(serverName,serverPort);
	Util.executeExtensions('InstanceSyncing_AddClientFeatures',client); //!	\see [ext:InstanceSyncing_AddClientFeatures]
	client.connect();
};

plugin.createServer := fn(Number port){
	var server = new (module('./Server'))(port);
	Util.executeExtensions('InstanceSyncing_AddServerFeatures',server); //!	\see [ext:InstanceSyncing_AddServerFeatures]
	server.start();
};
return plugin;
// ------------------------------------------------------------------------------

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010 Robert Gmyr
 * Copyright (C) 2010,2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tracking] Tracking/Plugin.escript
 **/

var plugin = new Plugin({
		Plugin.NAME : 'Tracking',
		Plugin.DESCRIPTION :  "Tracking tools (like head tracking).",
		Plugin.VERSION :  2.0,
		Plugin.AUTHORS : "Gmyr, Claudius Jaehn",
		Plugin.OWNER : "Claudius Jaehn",
		Plugin.LICENSE : "PROPRIETARY",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) :=fn(){

	module.on('PADrend/gui',this->fn(gui){
		gui.register('PADrend_MainWindowTabs.20_Tracking', this->createMainWindowTab);
	});
	var modules = [
        __DIR__+"/FakeTrack/Plugin.escript",
        __DIR__+"/Applications/Plugin.escript"
	];
	Util.loadPlugins( modules,true);
		
	return true;
};

plugin.createMainWindowTab @(private) := fn(){
	var page = gui.create({
		GUI.TYPE		:	GUI.TYPE_PANEL,
		GUI.SIZE		:	GUI.SIZE_MAXIMIZE
	});
	foreach( gui.createComponents('Tracking_drivers') as var c){
		page += c;
		page++;
	}
	page += '----';
	page++;
	foreach( gui.createComponents('Tracking_applications') as var c){
		page += c;
		page++;
	}
	
	return {
		GUI.TYPE : GUI.TYPE_TAB,
		GUI.LABEL : "Tracking",
		GUI.TOOLTIP : getDescription(),
		GUI.TAB_CONTENT : page
	};
};


return plugin;
// ------------------------------------------------------------------------------

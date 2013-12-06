/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011-2012 Sascha Brandt
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tests] Test/Plugin.escript
 **
 ** Collection of various Testcases concerning PADrend.
 ** The purpose of this plugin is to better detect if some high-level functionality has been broken.
 **/

/***
 **  ---|> Plugin
 **/
var plugin = new Plugin({
		Plugin.NAME : 'Tests',
		Plugin.DESCRIPTION : 'Collection of various Testcases concerning PADrend.',
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

// -------------------

/**
 * Plugin initialization.
 * ---|> Plugin
 */
plugin.init:=fn() {
	if(!queryPlugin('PADrend/GUI')){
		registerExtension('PADrend_Init',this->initAutoTest,Extension.LOW_PRIORITY*10);
	} else { 
		// Register ExtensionPointHandler:
        if(queryPlugin('PADrend/GUI')){
			registerExtension('PADrend_Init', this->fn(){
				gui.registerComponentProvider('PADrend_PluginsMenu.tests',{
					GUI.TYPE : GUI.TYPE_MENU,
					GUI.LABEL : "Tests",
					GUI.MENU : 'Tests_TestsMenu'
				});
			});
        }
    }

	var testModules = [
		__DIR__+"/Tests_GUI.escript",
		__DIR__+"/Tests_Scene.escript",
		__DIR__+"/Tests_Automated.escript",
		__DIR__+"/Tests_Distributed.escript" ];
	
	if(GLOBALS.isSet($Sound))
		testModules += __DIR__+"/Tests_Sound.escript";

	if(MinSG.isSet($Triangulation)) {
		testModules += __DIR__ + "/Tests_Triangulation.escript";
	}

	loadPlugins( testModules,false);

	return true;
};

plugin.initAutoTest := fn(){
	PADrend.message("(Tests-Plugin) PADrend started without gui -> starting auto test mode.");

	var results = Tests.AutomatedTestsPlugin.execute();
	print_r(results);
	if(!results['result']){
		GLOBALS._processResult = new Exception("(AutomatedTestsPlugin) " + results['resultString']);
	}
};

return plugin;
// ------------------------------------------------------------------------------

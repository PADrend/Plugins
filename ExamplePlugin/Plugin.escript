/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:ExamplePlugin] ExamplePlugin/Plugin.escript
 **
 ** Example plugin. 
 **	Features:
 **
 **	- Extends several extension points
 ** - Provides an extension point
 ** - Adds a button to the "plugin"-menu
 ** - Opens a simple popup-window
 ** - Uses a DataWrapper for synchronization with the gui and persistent value storage
 **/
 
var plugin = new Plugin({
		Plugin.NAME : 'ExamplePlugin',
		Plugin.DESCRIPTION : 'Simple example plugin.',
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius Jaehn",
		Plugin.OWNER : "All",
		Plugin.LICENSE : "Public Domain",
		Plugin.REQUIRES : ['PADrend/GUI'],
		Plugin.EXTENSION_POINTS : [ 
			/* [ext:ExamplePlugin_OnRedButtonPressed]
			 * Called whenever the red button is pressed.
			 * @param   empty
			 * @result  void
			 */
			'ExamplePlugin_OnRedButtonPressed',
		
		]
});

// (optional) mark the plugin as reloadable
Traits.addTrait(plugin,Util.ReloadablePluginTrait);	//!	\see Util.ReloadablePluginTrait
//!	\see Util.ReloadablePluginTrait
plugin.onRemovePlugin += fn(){
	outln("Bye!");
};

plugin.cash := void; // holds your current amount of gold

/**
 * Plugin initialization.
 * ---|> Plugin
 */
plugin.init:=fn() {
	{ // Register ExtensionPointHandler:
        registerExtension('PADrend_Init',this->this.ex_Init); 
		registerExtension('ExamplePlugin_OnRedButtonPressed',this->fn(){
			PADrend.message("You just pressed the red button! That costs you 10 gold!");
			cash(cash()-10);
		});
    }
	return true;
};

//!	[ext:PADrend_Init]
plugin.ex_Init := fn(){
	out("ExmaplePlugin: Hello World! Init init init...\n");
	// cash = DataWrapper.createFromValue(100); // always start with 100 gold
	cash = DataWrapper.createFromConfig( PADrend.configCache,'ExamplePlugin.gold',100 ); // automatically store the gold in the config
	cash.onDataChanged += fn(value)	{	PADrend.message("You now have "+value+" gold.\n");	};
	
	// init menu entries
	gui.registerComponentProvider('PADrend_PluginsMenu.examplePlugin',{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "ExamplePlugin",
		GUI.ON_CLICK : this->showWindow
	});

};

plugin.showWindow := fn(){
	var w = gui.createPopupWindow(300,100,"ExamplePlugin-Window");
	w+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "RED BUTTON",
		GUI.COLOR : GUI.RED,
		GUI.FONT : GUI.FONT_ID_LARGE,
		GUI.TOOLTIP : "Dangerous button! Do not press!",
		GUI.ON_CLICK : fn(){	executeExtensions('ExamplePlugin_OnRedButtonPressed');	}
	};
	w+={
		GUI.TYPE : GUI.TYPE_NUMBER,
		GUI.LABEL : "Cash",
		GUI.DATA_WRAPPER : cash,
		GUI.TOOLTIP : "Your current amount of gold.",
	};
	w.addAction("Cancel",fn(){	PADrend.message("Bye!"); },"Run away!");
	w.init();
};

// -------------------
return plugin;
// ------------------------------------------------------------------------------

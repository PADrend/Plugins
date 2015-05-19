/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2015 Claudius Jähn <claudius@uni-paderborn.de>
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
		Plugin.VERSION : 0.2,
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

static cash; // holds your current amount of gold

/**
 * Plugin initialization.
 * ---|> Plugin
 */
plugin.init @(override) :=fn() {
	// cash = new Std.DataWrapper(100); // always start with 100 gold
	cash = Std.DataWrapper.createFromEntry( PADrend.configCache,'ExamplePlugin.gold',100 ); // automatically store the gold in the config
	cash.onDataChanged += fn(value)	{	
		PADrend.message("You now have "+value+" gold.\n");
	};

	module.on('PADrend/gui', initGUI); // call initGUI when PADrend/gui is ready.
	
	Util.registerExtension('ExamplePlugin_OnRedButtonPressed', fn(){
		PADrend.message("You just pressed the red button! That costs you 10 gold!");
		cash(cash()-10);
	});

	return true; // plugin successful initialized 
};

static initGUI = fn(_gui){
	static gui = _gui;
	outln("ExmaplePlugin: Init GUI...");
	
	// init menu entries
	gui.register('PADrend_PluginsMenu.examplePlugin',[
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "ExamplePlugin",
			GUI.ON_CLICK : fn(){
				// for openDialog documentation, see LibGUIExt/Factory_Dialogs.escript
				gui.openDialog({
					GUI.TYPE : GUI.TYPE_POPUP_DIALOG,
					GUI.LABEL : "ExamplePlugin-Window",
					GUI.SIZE : [300,100],
					GUI.ACTIONS : [
						[ "Cancel",fn(){	PADrend.message("Bye!"); }, "Tooltip: Run away!" ]
					],
					GUI.OPTIONS : 'ExamplePlugin_WindowEntries'
				});
			}
		}
	]);
	
	gui.register('ExamplePlugin_WindowEntries.cash',[ 
		{// for gui component documentation, see LibGUIExt/Factory_Components.escript
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "RED BUTTON",
			GUI.COLOR : GUI.RED,
			GUI.FONT : GUI.FONT_ID_LARGE,
			GUI.TOOLTIP : "Dangerous button! Do not press!",
			GUI.ON_CLICK : fn(){	Util.executeExtensions('ExamplePlugin_OnRedButtonPressed');	}
		},
		{
			GUI.TYPE : GUI.TYPE_NUMBER,
			GUI.LABEL : "Cash",
			GUI.DATA_WRAPPER : cash,
			GUI.TOOLTIP : "Your current amount of gold.",
		}
	]);

};

return plugin;
// ------------------------------------------------------------------------------

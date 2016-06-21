/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var plugin = new Plugin({
		Plugin.NAME : 'PADrend/GUI/MainWindow',
		Plugin.DESCRIPTION : "PADrend's main window.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend/GUI'],
		Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) := fn(){

	module.on('PADrend/gui', fn(_gui){
		static window;
		static gui = _gui;
		
		gui.register('PADrend_MainToolbar.25_openMainWindow',{
			GUI.TYPE		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"->",
			GUI.ICON		:	"#Window",
			GUI.PRESET		:	'./toolIcon',
			GUI.ON_CLICK	:	fn() { 
					if(!window){
						window = createMainWindow(gui);
					}else{
						window.toggleVisibility();
					}
				},
			GUI.TOOLTIP		:	"Show/Hide Main Window [F1]"
		});
		// toggle main window on [F1]
		Util.registerExtension( 'PADrend_KeyPressed',fn(evt){
			if (evt.key == Util.UI.KEY_F1) { // F1
				if(!window){
					window = createMainWindow(gui);
				}else{
					window.toggleVisibility();
				}
				return true;
			}
			return false;
		},Extension.LOW_PRIORITY); // use low priority to allow the toolbar listener to catch the event before.
		
	});
	return true;
};

 //! Creates the main window containing the tabs
static createMainWindow = fn(gui){

    var width = 500;
    var height = 450;
    var window = gui.createWindow(width,height,"Main");
    window.setPosition(5,40);
    window.setLogo(gui.getIcon('#PADrendLogoSmall'));
    var pos=0;
    var tPanel =gui.createTabbedPanel(width,height,GUI.AUTO_MAXIMIZE);
    window += tPanel;
	
		Std.Traits.addTrait(window, Std.module('LibGUIExt/Traits/StorableRectTrait'),
							Std.DataWrapper.createFromEntry(PADrend.configCache, "MainWindow.winRect", [5,40,500,450]));

	registerExtension('PADrend_OnAvgFPSUpdated',window->fn(fps){
		this.setTitle("Main "+fps+"fps");
	});


	tPanel.addTabs('PADrend_MainWindowTabs');
 
	tPanel.setActiveTabIndex(0);
 
//    window.setEnabled(visible);
    return window;
};


return plugin;
// ------------------------------------------------------------------

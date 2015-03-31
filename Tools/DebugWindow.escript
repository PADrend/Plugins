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
var plugin = new Plugin({
		Plugin.NAME : 'Tools/DebugWindow',
		Plugin.DESCRIPTION : "Window for scripting and debugging. Opened with [^] key.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius Jaehn",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend/EventLoop'],
		Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) := fn(){

	module.on('PADrend/gui', fn(gui){
		gui.register('PADrend_PluginsMenu.dbgWindow',[{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Debug Tools",
			GUI.ON_CLICK : toggleWindow
		}]);
	});
	Util.registerExtension('PADrend_KeyPressed', fn(evt) {
		if((evt.key == Util.UI.KEY_CIRCUMFLEX || evt.key == Util.UI.KEY_GRAVE) && 
				!PADrend.getEventContext().isCtrlPressed()) {
			toggleWindow();
			return true;
		}
		return false;
	});

	return true;
};

static window;

static toggleWindow = fn(){
	if( window&&!window.isDestroyed() ){
		window.destroy();
		window = void;
	}else{
		window = gui.create({
			GUI.TYPE : GUI.TYPE_WINDOW,
			GUI.FLAGS : GUI.ONE_TIME_WINDOW,
			GUI.LABEL : "Debugging",
			GUI.SIZE : [320,200],
			GUI.POSITION : [100,100], 
		});
		//! \see GUI.StorableRectTrait
		Std.Traits.addTrait(window, Std.module('LibGUIExt/Traits/StorableRectTrait'), 
						DataWrapper.createFromConfig(PADrend.configCache, "Tools.debug", [200,200,300,300]));

		var tabPanel = gui.create({
			GUI.TYPE:	GUI.TYPE_TABBED_PANEL,
			GUI.SIZE:	GUI.SIZE_MAXIMIZE
		});
		window += tabPanel;
		tabPanel.addTabs('Tools_DebugWindowTabs');
		
		tabPanel.setActiveTabIndex(0);
	}
};

return plugin;
// ------------------------------------------------------------------------------

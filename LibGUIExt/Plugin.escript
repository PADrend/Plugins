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
 **	[Plugin:LibGUIExt] LibGUIExt/Plugin.escript
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
		Plugin.NAME : 'LibGUIExt',
		Plugin.DESCRIPTION : 'Extended GUI functionalities',
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius Jaehn",
		Plugin.OWNER : "All",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

/**
 * Plugin initialization.
 * ---|> Plugin
 */
plugin.init:=fn() {
	loadOnce(__DIR__+"/ComponentExtensions.escript");
	loadOnce(__DIR__+"/ComponentRegistry.escript");
	loadOnce(__DIR__+"/Factory_ComponentGroups.escript");
	loadOnce(__DIR__+"/Factory_Dialogs.escript");
	loadOnce(__DIR__+"/Factory_Components.escript");
	loadOnce(__DIR__+"/FileDialog.escript");
	loadOnce(__DIR__+"/FontHandling.escript");
	loadOnce(__DIR__+"/GUI_Utils.escript");
	loadOnce(__DIR__+"/IconHandling.escript");
	loadOnce(__DIR__+"/MenuHandling.escript");
	loadOnce(__DIR__+"/NewComponents.escript");
	loadOnce(__DIR__+"/PresetManager.escript");

	return true;
};

return plugin;
// ------------------------------------------------------------------------------

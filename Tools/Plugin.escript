/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 David Maicher
 * Copyright (C) 2010-2013 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tools] Tools/Plugin.escript
 ** 2010-03-21
 **/

var plugin = new Plugin({
		Plugin.NAME : 'Tools',
		Plugin.DESCRIPTION : "Container for various std. tools",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

/*! ---|> Plugin	*/
plugin.init @(override) := fn() {
	{ // Register ExtensionPointHandler:
		registerExtension('PADrend_Init',this->registerMenus);
	}
	
	var resourceFolder = __DIR__+"/resources";
	gui.loadIconFile( resourceFolder+"/ToolIcons.json");
		
	var modules = [];
	modules+=__DIR__+"/Camera/Plugin.escript";
	modules+=__DIR__+"/Console.escript";
	modules+=__DIR__+"/DebugWindow.escript";
	modules+=__DIR__+"/DistanceMeasuring.escript";
	modules+=__DIR__+"/EObjectInfo.escript";
	modules+=__DIR__+"/ErrorNotifier.escript";
	modules+=__DIR__+"/FrameAnalyzer.escript";
	modules+=__DIR__+"/FrameStats.escript";
	modules+=__DIR__+"/GamePadConfig.escript";
	modules+=__DIR__+"/GUIInfo.escript";
	modules+=__DIR__+"/JumpNRun.escript";
	modules+=__DIR__+"/MovementConstraints.escript";
	modules+=__DIR__+"/OrientationVisualization.escript";
	modules+=__DIR__+"/QuickScript.escript";
	modules+=__DIR__+"/Avatar.escript";
    modules+=__DIR__+"/ImportScene.escript";
    modules+=__DIR__+"/ExportScene.escript";
	modules+=__DIR__+"/Screenshot.escript";
	modules+=__DIR__+"/SpeedDial.escript";
	modules+=__DIR__+"/StatisticsWindow.escript";

	loadPlugins(modules,false);

    return true;
};


plugin.registerMenus:=fn(){
  	gui.registerComponentProvider('PADrend_MainToolbar.60_tools',{
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "Tools",
		GUI.MENU : 'Tools_ToolsMenu',
		GUI.MENU_WIDTH : 150,
		GUI.ICON : "#Tools",
		GUI.ICON_COLOR : GUI.BLACK,
  	});
  	
	gui.registerComponentProvider('Tools_ToolsMenu.info',[
		"*Info*",
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Scene Info",
			GUI.ON_CLICK : fn() {
				var node=PADrend.getCurrentScene();
				out("\n----\nSceneRoot: ",node,
				"\nBB:\t",node.getWorldBB().toString(),
				"\nGeometryNodes:\t",MinSG.countGeoNodes(node),
				"\nCamera:\t",camera.getWorldOrigin(),
				"\n-------\n");
			},
			GUI.TOOLTIP : "Output scene information to stdout."
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Output memory usage",
			GUI.ON_CLICK : fn() {
				Util.outputProcessMemory();
			},
			GUI.TOOLTIP : "Output memory usage information to standard output."
		}
	]);
	
};

return plugin;
// ------------------------------------------------------------------------------

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Mouns R. Husan Almarrani
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:SceneEditor]
 **
 ** Graphical tools for editing the scene, e.g. select Nodes, zoom.
 **/

declareNamespace($SceneEditor);

SceneEditor.plugin := new Plugin({
		Plugin.NAME : 'SceneEditor',
		Plugin.DESCRIPTION : 'Editing Scene.',
		Plugin.AUTHORS : "Mouns, Claudius",
		Plugin.OWNER : "All",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

var plugin = SceneEditor.plugin;

plugin.windowEnabled @(private) := DataWrapper.createFromValue(false);
plugin.window @(private):= void;

plugin.init @(override) := fn(){

	windowEnabled.onDataChanged += this->fn(value){
		if(value){
			if(!window)
				showWindow();
		}else{
			if(window){
				var w = window;
				window = void;
				w.close();
			}
		}
	};

	module.on('PADrend/gui',this->fn(gui){
		gui.register('PADrend_ToolsToolbar.90_showSceneEditorWindow',{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.PRESET : './toolIcon',
			GUI.ICON : '#SceneEditorWindow',
			GUI.LABEL : "Scene Editor2",
			GUI.WIDTH : 24,
			GUI.TOOLTIP : "Show scene editor's window.",
			GUI.ON_CLICK : this->fn(){	windowEnabled(!windowEnabled());	},
		});

		gui.register('PADrend_ConfigMenu.25_sceneEditor', [
			'----',
			{
				GUI.TYPE		:	GUI.TYPE_MENU,
				GUI.LABEL		:	"SceneEditor",
				GUI.MENU		:	'SceneEditor_ConfigMenu',
				GUI.MENU_WIDTH	:	150
			}
		]);

		var resourceFolder = __DIR__+"/resources";
		gui.loadIconFile( resourceFolder+"/ToolbarIcons.json");
	});
	Util.registerExtension( 'PADrend_KeyPressed',this->fn(evt){
		if(evt.key == Util.UI.KEY_F2) {
			windowEnabled(!windowEnabled());
			return true;
		}
		return false;
	},Extension.LOW_PRIORITY);

	var modules = [
		__DIR__+"/Selection/Plugin.escript",
		__DIR__+"/TransformationTools/Plugin.escript",
		__DIR__+"/ObjectPlacer/Plugin.escript",
		__DIR__+"/VisualHelper/Plugin.escript",
		__DIR__+"/NodeRepeater/Plugin.escript",
		__DIR__+"/ObjectExplorer/Plugin.escript",
		__DIR__+"/GroupStorage/Plugin.escript",
	];
	loadPlugins( modules,true);

	return true;
};


//GUI.

plugin.showWindow := fn(){
	window = gui.create({
		GUI.TYPE : GUI.TYPE_WINDOW,
		GUI.FLAGS : GUI.ONE_TIME_WINDOW,
		GUI.LABEL : "Scene Editor",
		GUI.ON_WINDOW_CLOSED : this->fn(){
			windowEnabled(false);
		}
	});

	Std.Traits.addTrait(window, Std.module('LibGUIExt/Traits/StorableRectTrait'),
						DataWrapper.createFromConfig(PADrend.configCache, "SceneEditor.winRect", [100,100,300,350]));

	var tabPanel =gui.create({
		GUI.TYPE:	GUI.TYPE_TABBED_PANEL,
		GUI.SIZE:	GUI.SIZE_MAXIMIZE
	});
	window += tabPanel;
	tabPanel.addTabs('SceneEditor_ToolsConfigTabs');
};

return plugin;

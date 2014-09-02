/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Mouns R. Husan Almarrani
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor/ObjectPlacer]
 **
 ** Manage/Insert Objects
 **/

//! ---|> Plugin
var plugin = new Plugin({
		Plugin.NAME : 'SceneEditor/ObjectPlacer',
		Plugin.DESCRIPTION : '...',
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['NodeEditor'],
		Plugin.EXTENSION_POINTS : [

			/* [ext:ObjectPlacer_OnObjectInserted]
			 * Called whenever an object (=node) has been inserted
			 * @param   The inserted MinSG.Node
			 * @result  void
			 */
			'ObjectPlacer_OnObjectInserted',
		]
});


plugin.init @(override) := fn(){
	registerExtension('PADrend_Init',this->this.ex_Init);
	registerExtension('ObjectPlacer_OnObjectInserted',	Std.require('LibMinSGExt/Traits/PersistentNodeTrait').initTraitsInSubtree );

	var modules = [
        __DIR__+"/BuiltinLib.escript",
        __DIR__+"/FileLib.escript",
	];
	loadPlugins( modules,true);

	return true;
};

//!	[ext:PADrend_Init]
plugin.ex_Init := fn(){
	//! \see SceneEditor
	gui.registerComponentProvider('SceneEditor_ToolsConfigTabs.Prototypes',this->createUITab);
};


plugin.createUITab := fn(){
	var panel = gui.create({
		GUI.TYPE : GUI.TYPE_PANEL
	});
	var tv = gui.create({
		GUI.TYPE : GUI.TYPE_TREE,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_FILL_ABS , 10.0,30.0 ]
	});
	panel += tv;

	//! \see ObjectPlacer.AcceptsObjectCreatorsTrait
	Traits.addTrait(tv,ObjectPlacer.AcceptsObjectCreatorsTrait);


	var refreshTv = tv->fn(){
		destroyContents();
		foreach(gui.createComponents('SceneEditor_ObjectProviderEntries') as var entry)
			this += entry;
	};

	gui.addComponentProviderListener('SceneEditor_ObjectProviderEntries',refreshTv);
	refreshTv();

	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.MENU : 'SceneEditor_AddObjectProvider',
		GUI.LABEL : "Add library"
	};

	return {
		GUI.TYPE : GUI.TYPE_TAB,
		GUI.TAB_CONTENT : panel,
		GUI.LABEL : "ObjectPlacer"
	};
};

//----------------------------------------------------------------------------


return plugin;

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var plugin = new Plugin({
		Plugin.NAME : 'NodeEditor/Tools',
		Plugin.DESCRIPTION : 'Collection of tools to modify nodes, meshes or the scene tree.',
		Plugin.VERSION : 0.2,
		Plugin.REQUIRES : ['NodeEditor/GUI'],
		Plugin.EXTENSION_POINTS : [	]
});

plugin.init @(override) := fn() {

	registerExtension('PADrend_Init',this->registerMenus);
	return true;
};

plugin.registerMenus := fn(){
	gui.registerComponentProvider('PADrend_SceneToolMenu.10_nodeTools',fn(){
		var nodes = NodeEditor.getSelectedNodes();
		if(nodes.empty())
			return [];
		return [
			{
				GUI.LABEL : "Node tools",
				GUI.MENU_WIDTH : 100,
				GUI.MENU : 'NodeEditor_NodeToolsMenu',
				GUI.MENU_CONTEXT : nodes,
			}
		];
	});

	gui.registerComponentProvider('NodeEditor_NodeToolsMenu.00_nodeId',fn(Array nodes){
		var menu = [];
		if(nodes.count()==1){
			var node = nodes.front();
			var id = PADrend.getSceneManager().getNameOfRegisteredNode(node);
			menu+={
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "NodeId:",
				GUI.DATA_VALUE : id ? id : "",
				GUI.ON_DATA_CHANGED : node->fn(data){
					var newId = data.trim();			
					if(newId.empty()){
						var oldId = PADrend.getSceneManager().getNameOfRegisteredNode(this);
						if(oldId){
							PADrend.message("Unregistering node '",oldId,"'\n");
							PADrend.getSceneManager().unregisterNode(oldId);
						}
					}else{
						PADrend.message("Registering node with id '",newId,"'\n");
						PADrend.getSceneManager().registerNode(newId,this);
					}
				}
			};
		}
		return menu;
	});

	load(__DIR__+"/AddNodeMenu.escript");
	load(__DIR__+"/MaterialMenu.escript");
	load(__DIR__+"/MeshMenu.escript");
	load(__DIR__+"/MiscMenu.escript");
	load(__DIR__+"/TreeMenu.escript");
};

return plugin;
// ------------------------------------------------------------------------------

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

gui.register('NodeEditor_NodeToolsMenu.addNode',fn(Array nodes){
	if( nodes.size()!=1 || !(nodes.front()---|>MinSG.GroupNode))
		return [];

	return [
		'----',
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Add new node",
			GUI.MENU : [nodes.front()] => fn(parentNode){
				var subMenu=[];
				foreach(NodeEditor.nodeFactories  as var name,var factory){
					subMenu += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "Create "+name,
						GUI.ON_CLICK :  [parentNode,name,factory] => fn(parentNode,name,factory){
							outln("Adding new ",name," to ",NodeEditor.getString(parentNode),".");
							var n = factory();
							parentNode.addChild(n);
							NodeEditor.selectNode(n);
						}
					};
				}
				return subMenu;
			},
			GUI.MENU_WIDTH : 150
		}
	];
});


// add clone of existing node
// add node from file
 
// ------------------------------------------------------------------------------


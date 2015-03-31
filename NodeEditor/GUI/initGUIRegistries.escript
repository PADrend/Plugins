/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] NodeEditor/GUI/GUI_Registries.escript
 ** 
 **  Registries for ...
 **		- configPanel providers
 **		- configTreeEntry providers
 **		- icons
 **/
 
declareNamespace($NodeEditor);

NodeEditor._objConfigurator := new (Std.module('LibGUIExt/ObjectConfigurator'));

// --------------------------------------------------------------------------------------------------------------

//! @name Config Panels
//	@{
NodeEditor.createConfigPanel := NodeEditor._objConfigurator -> NodeEditor._objConfigurator.createConfigPanel;

/*! Register a config panel factory for a given Type (Node, State or Behaviour).
	The factory method has to accept two parameters:
	 1. The GUI.Panel to which the config components should be added.
	 2. The object to configure.
	\example
		NodeEditor.registerConfigPanelProvider(MinSG.GroupNode, fn(MinSG.GroupNode node, panel){
			panel += "The node has "+node.countChildren()+" many children";
		});
	\note
		There may be more than one handler registered for one type.
*/
NodeEditor.registerConfigPanelProvider := NodeEditor._objConfigurator -> NodeEditor._objConfigurator.addConfigPanelProvider;
//	@}

// --------------------------------------------------------------------------------------------------------------


//! @name Config Tree Entries
//	@{

/*! Register a config tree entry factory for a given Type (Node, State or Behaviour).
	The factory method has to accept two parameters:
	 1. The object to configure.
	 2. The GUI.TreeViewEntry to which the config components should be added.
	\example
		NodeEditor.addConfigTreeEntryProvider(MinSG.GroupNode, fn(entry,MinSG.GroupNode node){
			entry += "The node has "+node.countChildren()+" many children";
		});
	\note
		There may be more than one handler registered for one type.	*/
NodeEditor.addConfigTreeEntryProvider := NodeEditor._objConfigurator -> NodeEditor._objConfigurator.addEntryProvider;


/*! Basic ConfigTreeProvider for 'Object'.
	This provider adds the basic components and several access functions to the created entry, which
	can be used by providers for inherited Types.
	
	Entry:
		|-----------------------------------------------------------------|
		| (Icon |) Label                    |   ButtonContainer  |  Menu  |
		|-----------------------------------------------------------------|
		
	 - entry.addOption(Component)
	 - entry.addMenuProvider( fun(entry,menuEntryMap){...} )
	 - entry.setLabel(String)
	 - entry.setColor(Color4ub)
	 - entry.getSubentry(name)
	 - entry.registerSubentry(name,entry)
*/
NodeEditor.addConfigTreeEntryProvider(Object,fn( obj,entry ){ 
	var icon = NodeEditor.getIcon(obj);
	if(icon){
		entry.getBaseContainer() += icon;
	}

	entry._label := gui.create({
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.LABEL : NodeEditor.getString(obj),
		GUI.POSITION : [ (icon ? 18 : 0) ,0]
	});
	entry.getBaseContainer() += entry._label;
	
	entry._buttonContainer := gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.LAYOUT : (new GUI.FlowLayouter()).setPadding(2).setMargin(0),
		GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
						GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP,25,0],
		GUI.SIZE : [GUI.WIDTH_CHILDREN_ABS,0,0]
	});
	entry.getBaseContainer() += entry._buttonContainer;

	entry._menuProvider := void;
	
	entry.setLabel := fn(String s){		_label.setText(s);	};
	entry.addOption := fn(c){	_buttonContainer+=c;	};
	entry.addMenuProvider := fn(c){
		if(!_menuProvider){
			this._menuProvider = [];
			getBaseContainer() += gui.create({
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "",
				GUI.CONTENTS : [GUI.OPTIONS_MENU_MARKER],
//				GUI.ICON : '#DownSmall',
//				GUI.ICON_COLOR : new Util.Color4ub(0x30,0x30,0x30,0xff),
//				GUI.ICON : "#OptionsSmall",
//				GUI.ICON_COLOR : GUI.BLACK,
				GUI.WIDTH : 15,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
							GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP, 0,0],
				GUI.MENU_WIDTH : 200,
				GUI.MENU : this->fn(){
					var entries  = new Map;
					foreach(_menuProvider as var p){
						p(this,entries);
					}
					var arr = [];
					foreach(entries as var group)
						arr.append(group);
					return arr;
				}
			});
		}
		_menuProvider+=c;
	};
	entry.setColor := fn(c){	_label.setColor(c);	};
});
//	@}

// --------------------------------------------------------------------------------------------------------------

//! @name Icon registry (for elements on the object configurator)
// @{
/*! Get an icon (or icon description) for the given object (e.g. a Node) based on its type.
	\note If no icon is available for the object's type, false is returned. 
	\example 
		// Register an icon for the type 'MinSG.Node'
		NodeEditor.getIcon += [MinSG.Node, fn(node){ 
			return {
				GUI.TYPE : GUI.TYPE_ICON,
				GUI.ICON : "#NodeSmall",
				GUI.ICON_COLOR : NodeEditor.NODE_COLOR
			};
		}];
	*/
NodeEditor.getIcon := new (Std.module('LibUtilExt/TypeBasedHandler'))(false);
NodeEditor.getIcon += [Object,fn(obj){return false;}]; // false is returned per default.
//	@}


return true;

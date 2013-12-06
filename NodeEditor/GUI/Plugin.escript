/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] NodeEditor/GUI/Plugin.escript
 ** Configuration tool for nodes of the scene graph.
 **/
 

/***
 **  ---|> Plugin
 **/
var plugin = new Plugin({
		Plugin.NAME : 'NodeEditor/GUI',
		Plugin.DESCRIPTION : 'Configuration tool for nodes of the scene graph.',
		Plugin.VERSION : 2.1,
		Plugin.OWNER : "All",
		Plugin.AUTHORS :  "Claudius",
		Plugin.REQUIRES : ['NodeEditor','PADrend/GUI'],
		Plugin.EXTENSION_POINTS : [	]
});

//!	---|> Plugin
plugin.init := fn() {
	loadOnce(__DIR__+"/GUI_Basics.escript");
	loadOnce(__DIR__+"/GUI_Registries.escript");
	
	{ // register at extension points
		
		registerExtension('PADrend_Init',this->this.registerGUIProviders);
	}

	return true;
};


plugin.registerGUIProviders := fn(){

	// node selection
	gui.registerComponentProvider('PADrend_SceneToolMenu.05_selectNode',[
		'----',
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Select Node",
			GUI.MENU_WIDTH : 200,
			GUI.MENU_PROVIDER : (fn(plugin){
				var subMenu=[];

				var node;
				if(NodeEditor.getSelectedNodes().count()==1){
					node = NodeEditor.getSelectedNode();
					if(node.isInstance()){
						subMenu+={
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Select prototype '"+NodeEditor.getString(node.getPrototype())+"'",
							GUI.TOOLTIP : "Select the prototype from which this node is cloned from.",
							GUI.ON_CLICK : (fn(prototype){
								NodeEditor.selectNode(prototype);
								PADrend.message("Prototype selected: '"+prototype+"'");
							}).bindLastParams(node.getPrototype())
						};
					}else{
						subMenu+={
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Select instances of '"+NodeEditor.getString(node)+"'",
							GUI.TOOLTIP : "Select the instances of this node in the current scene.",
							GUI.ON_CLICK : (fn(node){
								var instances = MinSG.collectInstances(PADrend.getCurrentScene(),node);
								NodeEditor.selectNodes(instances);
								PADrend.message("" + instances.count() + " instances selected.");
							}).bindLastParams(node)
						};
					}
					subMenu+='----';
				}
				var a=[];
				var currentNode=(node && node!=PADrend.getRootNode()) ? node : PADrend.getCurrentScene();
				while(currentNode){
					if(currentNode==node){
						a.pushFront("*"+NodeEditor.getString(currentNode)+"*");
					}else{
						var label;
						if(currentNode==PADrend.getRootNode()){
							label="RootNode";
						}else if(currentNode==PADrend.getCurrentScene()){
							label="Scene: "+currentNode.name;
						}else{
							label=NodeEditor.getString(currentNode);
						}
						a.pushFront({
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : label,
							GUI.ON_CLICK : currentNode->fn(){
								NodeEditor.selectNode(this);
								gui.closeAllMenus();
							}
						});
					}
					currentNode=currentNode.getParent();
				}
				subMenu.append(a);

				if(node ---|> MinSG.GroupNode){
					subMenu+="----";
					subMenu+={
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "Children",
						GUI.ON_CLICK : (fn(plugin){
							plugin.openChildSelectorMenu(getAbsPosition()+new Geometry.Vec2(0,10),NodeEditor.getSelectedNode());
						}).bindLastParams(plugin)
					};
				}
				return subMenu;
			}).bindLastParams(this)
		}
	]);
	
	/*! ______________
		| Node Editor \ _____________________________________________
		| [Tools] [^] [...Navbar.................................]  |
		| [ConfiguratorContainer]									|
		|															|
		| 															|
		|-----------------------------------------------------------|
	*/
	gui.registerComponentProvider('PADrend_MainWindowTabs.10_NodeEditor', this->fn() {
		var page = gui.create({
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.LAYOUT : GUI.LAYOUT_FLOW,
		});

		var toolbarEntries=[];
		toolbarEntries += {
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Tools",
			GUI.MENU_PROVIDER : fn(){
				return gui.createMenu('NodeEditor_NodeToolsMenu',150,NodeEditor.getSelectedNodes());
			}
			
		};

		toolbarEntries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.ICON : "#UpSmall",
			GUI.TOOLTIP : "Select parent of current node.",
			GUI.ICON_COLOR : NodeEditor.NODE_COLOR,
			GUI.SIZE : [ GUI.WIDTH_ABS|GUI.HEIGHT_ABS ,18,15],
			GUI.ON_CLICK : fn(){ 
				var node = NodeEditor.getSelectedNode();
				if(node && node.hasParent())
					NodeEditor.selectNode(node.getParent());
			}
		};
		

		toolbarEntries+=" ";

		toolbarEntries+=_createNavBar(-80,15);

		var tb=gui.createToolbar(480,20,toolbarEntries,50);
		tb.setExtLayout(
					GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
					new Geometry.Vec2(0,0),new Geometry.Vec2(-4,20) );

		page+=tb;

		page++;
		var configuratorContainer = gui.create({
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_FILL_ABS,-8,4],
		});
		_fillConfiguratorContainer(configuratorContainer);
		page+=configuratorContainer;
		
		// reselect nodes to initially fill the gui elements.
		NodeEditor.selectNodes(NodeEditor.getSelectedNodes());
		
		return {
			GUI.TYPE : GUI.TYPE_TAB,
			GUI.LABEL : "Node Editor",
			GUI.TOOLTIP : getDescription(),
			GUI.TAB_CONTENT : page
		};
	});
};

//! (internal) used by 'ex_createControlTab'
plugin._createNavBar:=fn(width,height){

	var panel=gui.createContainer(1,1,GUI.LOWERED_BORDER);
	panel.setExtLayout(
			GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
			new Geometry.Vec2(0,0),new Geometry.Vec2(width,height) );
	panel.refresh:= (fn( selectednodes,plugin ){
		destroyContents();
		var breadcrumbNodes=[];

		var text="";
		if(selectednodes.count()==1){
			text=NodeEditor.getString(selectednodes.front());
			for(var p=selectednodes.front().getParent(); p ; p=p.getParent())
				breadcrumbNodes.pushFront(p);
		}else {
			if(selectednodes.count()==0)
				text=" ---- ";
			else
				text=""+selectednodes.count()+" nodes";
			breadcrumbNodes+=PADrend.getRootNode();
			var scene = PADrend.getCurrentScene();
			if(scene)
				breadcrumbNodes+=scene;
		}
		var pos=0;
		// breadcrumb
		foreach(breadcrumbNodes as var node){
			var s=NodeEditor.getString(node);

			var bText;
			var flat = true;
			if(node==PADrend.getRootNode()){
				bText="R";
				flat=false;
			}else if(node==PADrend.getCurrentScene()){
				bText="S";
				flat=false;
			}else{
				bText="_";
			}

			this += {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : bText,
				GUI.TOOLTIP : "Select Node: "+s,
				GUI.POSITION : [pos,0],
				GUI.COLOR : NodeEditor.NODE_COLOR,
				GUI.FLAGS : flat ? GUI.FLAT_BUTTON : 0,
				GUI.WIDTH : 18,
				GUI.ON_CLICK : node->fn(){	NodeEditor.selectNode(this); }
			};

			pos+=18;

			this += {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.ICON : "#RightSmall",
				GUI.TOOLTIP : "Open child selector for "+s,
				GUI.POSITION : [pos,0],
				GUI.ICON_COLOR : NodeEditor.NODE_COLOR,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.WIDTH : 12,
				GUI.ON_CLICK : (fn(plugin,node){ 
						plugin.openChildSelectorMenu(getAbsPosition()+new Geometry.Vec2(0,10),node); 
				}).bindLastParams(plugin,node)
			};
			
			pos+=14;

		}


		var isGroupNode = selectednodes.front()---|>MinSG.GroupNode;
		var labelWidth = -pos - (isGroupNode?15:1);
		
		var icon;
		if(selectednodes.count() == 1) 
			icon = NodeEditor.getIcon(selectednodes.front());
		else if(selectednodes.count() > 1) 
			icon = gui.getIcon("#NodesSmall",NodeEditor.NODE_COLOR);
		if(icon){
			labelWidth -= 15;
			var component = gui.create(icon);
			component.setPosition(new Geometry.Vec2(pos,0));
			this += component;
			pos += 15;
		}


		// label
		var label=gui.createLabel();
		label.setTextStyle(GUI.TEXT_ALIGN_MIDDLE);
		label.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
			GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
			new Geometry.Vec2(pos,0),new Geometry.Vec2(labelWidth,15) );
		pos+=labelWidth;
		label.setText(text);
		add(label);
//		label.setColor(GUI.ACTIVE_COLOR_3);

		// searchButton
		if(isGroupNode){
			var node = selectednodes.front();
			this += {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.ICON : "#RightSmall",
				GUI.TOOLTIP : "Open child selector for "+NodeEditor.getString(node),
				GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT, 0,0],
				GUI.ICON_COLOR : node.countChildren() > 0 ? NodeEditor.NODE_COLOR : NodeEditor.NODE_COLOR_PASSIVE,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.WIDTH : 12,
				GUI.ON_CLICK : (fn(plugin,node){ 
						plugin.openChildSelectorMenu(getAbsPosition()+new Geometry.Vec2(0,10),node); 
				}).bindLastParams(plugin,node)
			};
		}

	}).bindLastParams(this);

	registerExtension('NodeEditor_OnNodesSelected', panel->fn(nodes){	refresh(nodes);	});
	return panel;
};


/*! (internal)  used by 'ex_createControlTab'

	|-GUI.TYPE_CONTAINER----------------------------------------|
	| entryContainer:TreeView									|
	| 															|
	|===========================================================|
	| configPanelContainer:Container							|
	| 															|
	| 															|
	|-----------------------------------------------------------|	*/
plugin._fillConfiguratorContainer := fn(GUI.Container page) {

	var configPanelContainer = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
//		GUI.FLAGS : GUI.LOWERED_BORDER,
		GUI.SIZE : [GUI.WIDTH_REL , 1.0 ,0 ]
	});
	var entryContainer = gui.create({
		GUI.TYPE : GUI.TYPE_TREE,
		GUI.SIZE : [GUI.WIDTH_REL , 1.0 ,0 ], 
		GUI.HEIGHT : 100
	});

	page += entryContainer;
	page += gui.createHSplitter();
	page += configPanelContainer;

	NodeEditor._objConfigurator.initTreeViewConfigPanelCombo(entryContainer,configPanelContainer);

	registerExtension('NodeEditor_OnNodesSelected',entryContainer->fn(nodes) {
		var limit = 25;
		if(nodes.count()<limit){
			this.update(nodes);
		}else{
			var objWrappers = [];
			var i = 0;
			foreach(nodes.chunk(limit) as var part){
				objWrappers += new NodeEditor.Wrappers.MultipleObjectsWrapper("Nodes "+i+"..."+ (i+part.count()-1),part);
				i+=part.count();
			}
			this.update(objWrappers);
		}
	});
};


/*! (internal)  used by 'ex_createControlTab'

	|-GUI.TYPE_MENU-----------------|
	| filterText:GUI.TYPE_TEXT		|
	|-------------------------------|
	| entries:GUI.TYLE_LIST			|
	| ...							|
	| 								|
	|-------------------------------|	*/
plugin.openChildSelectorMenu:=fn(Geometry.Vec2 pos,MinSG.GroupNode n){
	var m=gui.createMenu();
	var entries = [];
	foreach(MinSG.getChildNodes(n) as var c){
		var s = NodeEditor.getString(c);
		entries += [c,s,s.toLower()];
	}
	m.refresh := (fn(String filterText,entries){
		tv.clear();
		filterText = filterText.toLower();
		var t = new Util.Timer();
		foreach(entries as var entry){
			if(filterText.empty() || entry[2].find(filterText)){
				tv += {
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : entry[1],
					GUI.FLAGS : GUI.FLAT_BUTTON,
					GUI.TEXT_ALIGNMENT : (GUI.TEXT_ALIGN_LEFT | GUI.TEXT_ALIGN_MIDDLE),
					GUI.ON_CLICK : (fn(node){
						NodeEditor.selectNode(node);
						gui.closeAllMenus();
					}).bindLastParams(entry[0])
				};
			}
		}
	}).bindLastParams(entries);
	m+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.ON_DATA_CHANGED : m->m.refresh,
		GUI.TOOLTIP : "Filter (case insensitive)",
		GUI.WIDTH : 250
	};
	var tv = gui.create({
		GUI.TYPE : GUI.TYPE_LIST,
		GUI.WIDTH : 250,
		GUI.HEIGHT : 200,
		GUI.TOOLTIP : "Select an entry to select the node."
	});
								
	m.tv := tv;
	m+=tv;
	m.refresh("");

	m.open( pos );
};


return plugin;
// --------------------------------------------------------------------------

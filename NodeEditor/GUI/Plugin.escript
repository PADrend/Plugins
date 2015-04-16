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

var plugin = new Plugin({
		Plugin.NAME : 'NodeEditor/GUI',
		Plugin.DESCRIPTION : 'Configuration tool for nodes of the scene graph.',
		Plugin.VERSION : 2.1,
		Plugin.OWNER : "All",
		Plugin.AUTHORS :  "Claudius",
		Plugin.REQUIRES : ['NodeEditor','PADrend/GUI'],
		Plugin.EXTENSION_POINTS : [	]
});

plugin.init @(override) := fn() {
	module( './initGUIBasics' );
	module( './initGUIRegistries' );
	module.on('PADrend/gui',this->this.registerGUIProviders);
	return true;
};


plugin.registerGUIProviders := fn(_gui){
	static gui = _gui;
	
	// node selection
	gui.register('PADrend_FileMenu.25_exportSelectedNode',fn(){
		var entries = [];
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Save node as...",
			GUI.TOOLTIP : 	"Show a dialog to export the selected node into a .minsg file.",
			GUI.FLAGS : (NodeEditor.getSelectedNodes().count()!=1 || NodeEditor.getSelectedNode()==PADrend.getRootNode() || NodeEditor.getSelectedNode()==PADrend.getCurrentScene())?GUI.LOCKED : 0,
			GUI.ON_CLICK : fn(){
				var node = NodeEditor.getSelectedNode();
				gui.openDialog({
					GUI.TYPE :		GUI.TYPE_FILE_DIALOG,
					GUI.LABEL :		"Export node: "+NodeEditor.getNodeString(node),
					GUI.ENDINGS :	[".minsg", ".dae", ".DAE"],
					GUI.FILENAME : 	node.isSet($filename) ? node.filename : PADrend.getScenePath()+"/Neu.minsg",
					GUI.ON_ACCEPT : [node] => fn(node, filename){
								
						var save = [node,filename] => fn(node,filename){
							PADrend.message("Save node \""+filename+"\"");
							if(filename.endsWith(".dae")||filename.endsWith(".DAE")) {
								MinSG.SceneManagement.saveCOLLADA(filename,PADrend.getRootNode());
							} else {
								MinSG.SceneManagement.saveMinSGFile( PADrend.getSceneManager(),filename,[node]);
							}
						};
						
						if(Util.isFile(filename)){
							gui.openDialog({
								GUI.TYPE :				GUI.TYPE_POPUP_DIALOG ,
								GUI.LABEL :				"Overwrite?",
								GUI.ACTIONS : 			[ ["overwrite",save] , ["cancel"]],
								GUI.OPTIONS : 			["The file '"+filename+"' exists."],
								GUI.SIZE : 		 		[320,80]
							});
						}else{
							save();
						}
					}
				});
			}
		};
	
		return entries;
	});

	// node selection
	gui.register('PADrend_SceneToolMenu.05_selectNode',[
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Select Node",
			GUI.MENU_WIDTH : 300,
			GUI.MENU : [this] => fn(plugin){
				var subMenu=[];

				var node = NodeEditor.getSelectedNode();
				if(!NodeEditor.getSelectedNodes().empty()){
					subMenu += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "Unselect all",
						GUI.ON_CLICK : fn(){
							NodeEditor.selectNode(void);
							gui.closeAllMenus();
						}
					};
					subMenu += '----';
				}
				
				var a=[];
				var currentNode=(node && node!=PADrend.getRootNode()) ? node : PADrend.getCurrentScene();
				var level = 0;
				while(currentNode){
					if(currentNode==node){
						a.pushFront({
							GUI.TYPE : GUI.TYPE_LABEL,
							GUI.LABEL : "(0) "+NodeEditor.getString(currentNode),
							GUI.TOOLTIP : "Currently selected node"
						});
					}else{
						var label;
						if(currentNode==PADrend.getRootNode()){
							label="RootNode";
						}else if(currentNode==PADrend.getCurrentScene()){
							label="Scene ("+NodeEditor.getString(currentNode)+")";
						}else{
							label=NodeEditor.getString(currentNode);
						}
						a.pushFront({
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "("+level+") "+label,
							GUI.ON_CLICK : currentNode->fn(){
								NodeEditor.selectNode(this);
								gui.closeAllMenus();
							},
							GUI.TOOLTIP : "Select node '"+label+"'."
						});
					}
					currentNode=currentNode.getParent();
					--level;
				}
				subMenu.append(a);
				
				if(node.isA(MinSG.GroupNode)){
					subMenu+="----";
					subMenu+={
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "Select child node...",
						GUI.ON_CLICK : fn(){
							openChildSelectorMenu(getAbsPosition()+new Geometry.Vec2(0,10),NodeEditor.getSelectedNode());
						}
					};
				}
				if(NodeEditor.getSelectedNodes().count()==1){
					subMenu+="----";
					if(node.isInstance()){
						subMenu+={
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Select prototype '"+NodeEditor.getString(node.getPrototype())+"'",
							GUI.TOOLTIP : "Select the prototype from which this node is cloned from.",
							GUI.ON_CLICK : [node.getPrototype()]=>fn(prototype){
								NodeEditor.selectNode(prototype);
								PADrend.message("Prototype selected: '"+prototype+"'");
							}
						};
					}else{
						subMenu+={
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Select instances of '"+NodeEditor.getString(node)+"'",
							GUI.TOOLTIP : "Select the instances of this node in the current scene.",
							GUI.ON_CLICK : [node] => fn(node){
								var instances = MinSG.collectInstances(PADrend.getCurrentScene(),node);
								NodeEditor.selectNodes(instances);
								PADrend.message("" + instances.count() + " instances selected.");
							}
						};
					}
				}
				return subMenu;
			}
		}
	]);
	
	
	// node selection
	gui.register('PADrend_ConfigMenu.37_NodeEditor',[
		'----',
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Node Editor",
			GUI.MENU : 'NodeEditor_ConfigMenu',
			GUI.MENU_WIDTH : 300,
		}
	]);

	gui.register('NodeEditor_ConfigMenu.10_Picking',fn(){
		var entries = [ 
			"*Selection picking [strg]*" ,
		];
		var node = NodeEditor.getSelectedNode();
		var sRoot = NodeEditor.pickingSelectionRoot();
		entries+={
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Picking selection-root: " + ((!sRoot || sRoot==PADrend.getCurrentScene()) ? "Current scene" : NodeEditor.getString(sRoot)),
			GUI.ON_CLICK : [node]=>fn(node){
				NodeEditor.pickingSelectionRoot( node );
				PADrend.message("Selected new root for picking-selections.");
				this.getGUI().closeAllMenus();
			},
			GUI.TOOLTIP : "Set the currently selected node \n'"+NodeEditor.getString(node)+"'\nas root node used for picking with [strg]+[l-click]."
		};
		return entries;
	});
	
	/*! ______________
		| Node Editor \ _____________________________________________
		| [Tools] [^] [...Navbar.................................]  |
		| [ConfiguratorContainer]									|
		|															|
		| 															|
		|-----------------------------------------------------------|
	*/
	gui.register('PADrend_MainWindowTabs.10_NodeEditor', this->fn() {
		var page = gui.create({
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.LAYOUT : GUI.LAYOUT_FLOW,
		});

		var toolbarEntries=[];
		toolbarEntries += {
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Tools",
			GUI.MENU_WIDTH  : 150,
			GUI.MENU : fn(){
				return gui.createComponents({
						GUI.TYPE : GUI.TYPE_MENU_ENTRIES,
						GUI.PROVIDER : 'NodeEditor_NodeToolsMenu',
						GUI.WIDTH : 150,
						GUI.CONTEXT : NodeEditor.getSelectedNodes()
				});
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
	panel.refresh:= fn( selectednodes ){
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
				GUI.ON_CLICK : [node] => fn(node){ 
						openChildSelectorMenu(getAbsPosition()+new Geometry.Vec2(0,10),node); 
				}
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
				GUI.ON_CLICK : [node] => fn(node){ 
						openChildSelectorMenu(getAbsPosition()+new Geometry.Vec2(0,10),node); 
				}
			};
		}

	};

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

	NodeEditor._objConfigurator.initTreeViewConfigPanelCombo(entryContainer,configPanelContainer,'NodeEditor_ObjConfig_'  );

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
static openChildSelectorMenu = fn(Geometry.Vec2 pos,MinSG.GroupNode n){
	var m = gui.createMenu();
	var entries = [];
	foreach(MinSG.getChildNodes(n) as var c){
		var s = NodeEditor.getString(c);
		entries += [c,s,s.toLower()];
	}
	m.refresh := [entries] => fn(entries,String filterText){
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
					GUI.ON_CLICK : [entry[0]] => fn(node){
						NodeEditor.selectNode(node);
						gui.closeAllMenus();
					}
				};
			}
		}
	};
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

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Mouns R. Husan Almarrani
 * Copyright (C) 2010-2011 Paul Justus
 * Copyright (C) 2011-2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


gui.registerComponentProvider('NodeEditor_NodeToolsMenu.treeTools',fn(Array nodes){
	return nodes.empty() ? [] : [
		'----',
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Tree tools",
			GUI.MENU : 'NodeEditor_TreeToolsMenu',
			GUI.MENU_WIDTH : 150,
			GUI.TOOLTIP: "these operations perform on all nodes of the currently selected (sub)tree"
		}
	];
});

// ----------------------------------------------------------
gui.registerComponentProvider('NodeEditor_TreeToolsMenu.transformations',[
	'*Transformations*',
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Assure affine transformations",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();

			PADrend.message("Assure affine transformations...");
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				var stats = new ExtObject({
					$conversions : 0,
					$srts : 0,
					$overall : 0,

				});
				subtree.traverse(stats->fn(node){
					++overall;
					if(node.hasTransformation()){
						if(node.hasRelTransformationSRT()){
							++srts;
						}else{
							node.setRelTransformation(node.getRelTransformationMatrix().toSRT());
							++conversions;
						}
					}
				});
				print_r(stats._getAttributes());
			}
		},
		GUI.TOOLTIP: "For all nodes in the subtree,\nconvert the matrices into srts."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Transformations --> Leaves",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				MinSG.moveTransformationsIntoLeaves(subtree);
				out("moved transformations to leaves: ", subtree, "\n");
			}
		},
		GUI.TOOLTIP: "Move all transformations to the leaf nodes"
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Transformations --> Closed Nodes",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				MinSG.moveTransformationsIntoClosedNodes(subtree);
				out("moved transformations to closed nodes: ", subtree, "\n");
			}
		},
		GUI.TOOLTIP: "Move all transformations to the closed nodes"
	},
]);



// ----------------------------------------------------------
gui.registerComponentProvider('NodeEditor_TreeToolsMenu.treeOperations',[
	'----',
	"*Tree operations*",

	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Combine leafs",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();
			MinSG.combineLeafs(NodeEditor.getSelectedNode(),1);
		},
		GUI.TOOLTIP: "Combine the meshes of leaf nodes, which have the same set of states and the same VertexDescription."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Delete Node",
		GUI.ON_CLICK:fn(){
			var parent;

			foreach(NodeEditor.getSelectedNodes() as var node){
				parent = node.getParent();
				MinSG.destroy(node);
			}
			NodeEditor.selectNode(parent);
		},
		GUI.TOOLTIP:  "Delete selected node."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Group nodes in common subtree",
		GUI.ON_CLICK:fn(){
			if(!NodeEditor.getSelectedNodes().empty()){
				var subtreeRoot = NodeEditor.getSelectedNodes()[0];
				foreach(NodeEditor.getSelectedNodes() as var node){
					subtreeRoot = MinSG.getRootOfCommonSubtree(subtreeRoot,node);
					assert(subtreeRoot);
				}
				var newGroup = new MinSG.ListNode;
				subtreeRoot += newGroup;
				foreach(NodeEditor.getSelectedNodes() as var node){
					MinSG.changeParentKeepTransformation(node, newGroup);
				}
				NodeEditor.selectNode( newGroup );
			}
		},
		GUI.TOOLTIP: "Place all selected nodes in one common subtree."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Open all inner Nodes",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				MinSG.openAllInnerNodes(subtree);
				out("opened inner nodes of: ", subtree);
			}
		},
		GUI.TOOLTIP: "MinSG.openAllInnerNodes(subtree)"
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Optimize meshes",
		GUI.ON_CLICK : fn() {
			foreach(NodeEditor.getSelectedNodes() as var node)
				MinSG.optimizeMeshes(node);
		},
		GUI.TOOLTIP : "Optimize the meshes in the scene for vertex-cache locality."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Pull up States",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				var n=MinSG.pullUpStates(subtree);
				out("\nRemoved redundant states:",n,"\n");
			}
		},
		GUI.TOOLTIP: "If all children have the same states then \nmove these states to the parent"
	},

	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Remove all states",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				MinSG.removeAllStates(subtree);
			}
		},
		GUI.TOOLTIP: "MinSG.removeAllStates(subtree)"
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Shrink meshes",
		GUI.ON_CLICK : fn() {
			MinSG.shrinkMeshes(NodeEditor.getSelectedNode());
		},
		GUI.TOOLTIP : "Use smaller data types for color and normal vertex data."
	},
	{
		GUI.TYPE		:	GUI.TYPE_BUTTON,
		GUI.LABEL		:	"Show statistics",
		GUI.TOOLTIP		:	"Show number of nodes, number of states, number of triangles etc.",
		GUI.ON_CLICK	:	fn() {
								var dialogOptions = [];
								var statistics = MinSG.collectTreeStatistics(NodeEditor.getSelectedNode());
								foreach(statistics as var description, var value) {
									if(value ---|> Number) {
										dialogOptions += {
											GUI.TYPE			:	GUI.TYPE_NUMBER,
											GUI.LABEL			:	description,
											GUI.DATA_VALUE		:	value,
											GUI.FLAGS			:	GUI.LOCKED
										};
									} else if(value ---|> Array) {
										var options = [];
										foreach(value as var key, var entry) {
											options += "" + key + ": " + entry;
										}
										dialogOptions += description + ":";
										dialogOptions += {
											GUI.TYPE			:	GUI.TYPE_LIST,
											GUI.OPTIONS			:	options,
											GUI.FLAGS			:	GUI.LOCKED,
											GUI.HEIGHT			:	15 * options.count()
										};
									}
								}
								gui.openDialog({
									GUI.TYPE		:	GUI.TYPE_POPUP_DIALOG,
									GUI.LABEL		:	"Tree Statistics",
									GUI.OPTIONS		:	dialogOptions,
									GUI.ACTIONS		:	["Close"],
									GUI.SIZE		:	[250, 400]
								});
							}
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"States --> Closed Nodes",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				MinSG.moveStatesIntoClosedNodes(subtree);
				out("moved states to closed nodes: ", subtree, "\n");
			}
		},
		GUI.TOOLTIP: "Move all states to the closed nodes"
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"States --> Leaves",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				MinSG.moveStatesIntoLeaves(subtree);
				out("moved states to leaves: ", subtree, "\n");
			}
		},
		GUI.TOOLTIP: "Move all states to the leaf nodes"
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Remove State",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();
			out("Remove state...\n");
			var dataWrap =new ExtObject({
				$state : DataWrapper.createFromValue( "" ),
			});
			var popup = gui.createPopupWindow( 180,180,"Remove state" );
			var states = new Map();
			var entries =new Map();
			var collectStates = (MinSG.collectStates(PADrend.getRootNode())).clone();
			foreach(collectStates as var state){
				states[state]=state;
			};
			foreach(states as  var id, var state)
				entries[state.getTypeName()]=state.getTypeName();
			popup.addOption({
				GUI.TYPE  : GUI.TYPE_TEXT,
				GUI.LABEL : "State",
				GUI.OPTIONS : entries,
				GUI.DATA_WRAPPER : dataWrap.state,
			});
			popup.addAction("Remove", [dataWrap,states] => fn(dataWrap,states){
					foreach(states as var id, var state){
						if(state.getTypeName()==dataWrap.state()){
							var nodes = MinSG.collectNodesWithState(PADrend.getRootNode(),state);
							foreach(nodes as var node){
								node.removeState(state);
							}
						}
					};
				}
			);
			popup.addAction("Cancel");
			popup.init();

		},
		GUI.TOOLTIP: "Remove the selected state from the scene."
	},
]);
gui.registerComponentProvider('NodeEditor_TreeToolsMenu.cleanups',[
	"*Cleanups*",
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Close nodes having states",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				MinSG.closeNodesHavingStates(subtree);
				out("closed all nodes with states: ", subtree);
			}
		},
		GUI.TOOLTIP: "MinSG.closeNodesHavingStates(subtree)"
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Close semantic objects",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();
			static counter = 0;
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				subtree.traverse( fn(node){
					if(MinSG.SemanticObjects.isSemanticObject(node) ){
						if(!node.isClosed()){
							++counter;
							node.setClosed(true);
						}
					}
				});
				PADrend.message("Number of closed nodes: " +counter);
			}
		}
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Remove duplicate Textures",
		GUI.ON_CLICK:fn(){

			var textures = new Map();
			var nodes = MinSG.collectNodes(NodeEditor.getSelectedNode());

			var node;
			foreach(nodes as node){
				foreach( node.getStates() as var state){
					if(state ---|> MinSG.TextureState){
							var file = state.getTexture().getFileName();
							if(!textures[file]) {
								textures[file] = state;
								Util.info("new tex: ",file,"\n");
							}
						}
				}
			}
			foreach(nodes as node){
				foreach( node.getStates() as var state){
					if(state ---|> MinSG.TextureState){
							var file = state.getTexture().getFileName();
							node.removeState(state);
							node.addState(textures[file]);
						}
				}
			}
		},
		GUI.TOOLTIP:  "Removes duplicate Textures inside the selected subtree"
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Remove open Nodes",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				if(subtree ---|> MinSG.GroupNode)
					MinSG.removeOpenNodes(subtree);
			}
		},
		GUI.TOOLTIP: "Remove all (open) inner nodes and empty leafs.\nThe transformations are preserved; the states of the inner nodes are not."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Remove invalid NodeTraits",
		GUI.ON_CLICK:fn(){
			static PersistentNodeTrait = Std.require('LibMinSGExt/Traits/PersistentNodeTrait');
			showWaitingScreen();
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				subtree.traverse( fn(node){
					PersistentNodeTrait.removeInvalidTraitNames(node);
					if(node.isInstance())
						PersistentNodeTrait.removeInvalidTraitNames( node.getPrototype() );
				});
			}
		},
		GUI.TOOLTIP: "Remove all (open) inner nodes and empty leafs.\nThe transformations are preserved; the states of the inner nodes are not."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"Tree cleanup",
		GUI.ON_CLICK:fn(){
			showWaitingScreen();
			out("Tree cleanup...\n");
			var n = NodeEditor.getSelectedNode();
			if(n==PADrend.getCurrentScene()){
				foreach(MinSG.getChildNodes(n) as var child)
					MinSG.cleanupTree(child,PADrend.getSceneManager());
				out("SceneRoot...\n");
			}else{
				MinSG.cleanupTree(n,PADrend.getSceneManager());
			}

		},
		GUI.TOOLTIP: "Remove empty GroupNodes and replace \nGroupNodes with single child by that child."
	},
]);


gui.registerComponentProvider('NodeEditor_TreeToolsMenu.prototypes',[
	'----',
	"*Prototypes/Instances*",
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Refresh instances",
		GUI.TOOLTIP : "Replace all node instances in the subtree \nby fresh copies of the original.",
		GUI.ON_CLICK : fn(){
			var instanceCounter = 0;
			var nodes = NodeEditor.getSelectedNodes().clone();
			while(!nodes.empty()){
				var node = nodes.popBack();

				if(node.isInstance()){
					++instanceCounter;
					MinSG.updatePrototype(node,node.getPrototype());
				}else{
					nodes.append(MinSG.getChildNodes(node));
				}
			}
			PADrend.message("Refreshed #"+instanceCounter+" instances.");
		}
	},		
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Un-clone subtree",
		GUI.TOOLTIP : "Remove the reference to prototype nodes\n from the nodes in the selected subtree.",
		GUI.ON_CLICK : fn(){
			var nodes = NodeEditor.getSelectedNodes().clone();
			var counter = [0];
			while(!nodes.empty()){
				var node = nodes.popBack();
				if(node.isInstance()){
					// up
					for(var n=node;n&&n.isInstance();n=n.getParent()){
						++counter[0];
						n._setPrototype(void);
					}
					// down
					node.traverse( counter->fn(node){
						if(node.isInstance()){
							node._setPrototype(void);
							++this[0];
						}});
				}else{
					nodes.append(MinSG.getChildNodes(node));
				}
			}
			PADrend.message(""+counter[0]+" nodes un-cloned.");
		}
	},
]);

// ----------------------------------------------------------------------------------
// tree building operations

gui.registerComponentProvider('NodeEditor_TreeToolsMenu.treeBuilding',[
	'----',
	"*Tree building op.*",
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL:"rebuild tree as ...",
		GUI.ON_CLICK:fn(){

			var options = new ExtObject();
			options.func := MinSG.TreeBuilder.rebuildAsOcTree;
			options.map := new Map();
			options.map[MinSG.TreeBuilder.MAX_TREE_DEPTH] = 10;
			options.map[MinSG.TreeBuilder.MAX_CHILD_COUNT] = 10;
			options.map[MinSG.TreeBuilder.LOOSE_FACTOR] = 2;
			options.map[MinSG.TreeBuilder.PREFERE_CUBES] = true;
			options.map[MinSG.TreeBuilder.USE_GEOMETRY_BB] = true;
			options.map[MinSG.TreeBuilder.EXACT_CUBES] = false;

			var popup = gui.createPopupWindow( 380,240,"rebuild tree", GUI.NO_MINIMIZE_BUTTON|GUI.ALWAYS_ON_TOP);
			popup.addOption({
				GUI.LABEL			: 	"tree type",
				GUI.TYPE 			: 	GUI.TYPE_SELECT,
				GUI.OPTIONS			: 	[
											[MinSG.TreeBuilder.rebuildAsList, "List", void, "builds a simple list."],
											[MinSG.TreeBuilder.rebuildAsQuadTree, "Quad-Tree", void, "builds several variants of quadtrees."],
											[MinSG.TreeBuilder.rebuildAsOcTree, "Oc-Tree", void, "builds several variants of octrees."],
											[MinSG.TreeBuilder.rebuildAsKDTree, "KD-Tree", void, "builds several variants of kd-trees."],
											[MinSG.TreeBuilder.rebuildAsBinaryTree, "Binary-Tree", void, "builds a binary tree \nby splitting allways the largest dimension."]
										],
				GUI.DATA_VALUE		:	options.func,
				GUI.ON_DATA_CHANGED	:	[options]=>fn(options, data){options.func = data;},
				GUI.TOOLTIP			: 	"select the base type of the tree to be created \ndepending on this selection some of the following parameters may be ignored."
			});
			popup.addOption({
				GUI.LABEL			: 	"maximum tree depth",
				GUI.TYPE 			: 	GUI.TYPE_RANGE,
				GUI.RANGE 			:	[0,20],
				GUI.RANGE_STEPS 	:	20,
				GUI.DATA_VALUE		:	options.map[MinSG.TreeBuilder.MAX_TREE_DEPTH],
				GUI.ON_DATA_CHANGED	:	[options]=>fn(options, data){options.map["MAX_TREE_DEPTH"] = data;},
				GUI.TOOLTIP			:	"the maximum depth of the created tree\nleaves in depth >= maximum will not be split."
			});
			popup.addOption({
				GUI.LABEL			: 	"maximum child count",
				GUI.TYPE 			: 	GUI.TYPE_RANGE,
				GUI.RANGE 			:	[0,10],
				GUI.RANGE_FN_BASE	:	2,
				GUI.RANGE_STEPS 	:	10,
				GUI.DATA_VALUE		:	options.map[MinSG.TreeBuilder.MAX_CHILD_COUNT],
				GUI.ON_DATA_CHANGED	:	[options]=>fn(options, data){options.map["MAX_CHILD_COUNT"] = data;},
				GUI.TOOLTIP			:	"the maximum number of nodes stored in leaves,\nleaves with mor nodes will be split up as long as\nthe maximum depth is not reached."
			});
			popup.addOption({
				GUI.LABEL			: 	"loose factor",
				GUI.TYPE 			: 	GUI.TYPE_RANGE,
				GUI.RANGE 			:	[1,4],
				GUI.RANGE_STEPS 	:	30,
				GUI.DATA_VALUE		:	options.map[MinSG.TreeBuilder.LOOSE_FACTOR],
				GUI.ON_DATA_CHANGED	:	[options]=>fn(options, data){options.map["LOOSE_FACTOR"] = data;},
				GUI.TOOLTIP			:	"the scale factor for boxes when inserting nodes\nif you don't want a loose tree, set this value to one."
			});
			popup.addOption({
				GUI.LABEL			: 	"prefere cubes",
				GUI.TYPE 			: 	GUI.TYPE_BOOL,
				GUI.DATA_VALUE		:	options.map["PREFERE_CUBES"],
				GUI.ON_DATA_CHANGED	:	[options]=>fn(options, data){options.map[MinSG.TreeBuilder.PREFERE_CUBES] = data;},
				GUI.TOOLTIP			:	"quadtree, octree, kd-tree:\nif selected, octrees split not allways in all dimensions\nif ratio between maximum and minimum extend of the BoundingBox\ngets greater squareroot of two, only the large dimensions are splitted."
			});
			popup.addOption({
				GUI.LABEL			: 	"use geometry bounding boxes",
				GUI.TYPE 			: 	GUI.TYPE_BOOL,
				GUI.DATA_VALUE		:	options.map["USE_GEOMETRY_BBs"],
				GUI.ON_DATA_CHANGED	:	[options]=>fn(options, data){options.map[MinSG.TreeBuilder.USE_GEOMETRY_BB] = data;},
				GUI.TOOLTIP			:	"quadtree, octree, binary tree, kd-tree:\nif selected, bounding boxes of the geometry instead of\nthose of the previous step are used for splitting."
			});
			popup.addOption({
				GUI.LABEL			: 	"use exact cubes",
				GUI.TYPE 			: 	GUI.TYPE_BOOL,
				GUI.DATA_VALUE		:	options.map["EXACT_CUBES"],
				GUI.ON_DATA_CHANGED	:	[options]=>fn(options, data){options.map[MinSG.TreeBuilder.EXACT_CUBES] = data;},
				GUI.TOOLTIP			:	"quadtree, octree:\nif selected, scene bounding box is expanded to a cube/square before splitting\ndon't forget to disable `use geometry bounding boxes´"
			});
			popup.addAction(
				"Build Tree",
				[options] => fn(options){
					if(!(NodeEditor.getSelectedNode()---|>MinSG.GroupNode)){
						Runtime.warn("Build Tree: Select a group node to rebuild\n");
					}else if(!NodeEditor.getSelectedNode().hasParent()){
						Runtime.warn("Build Tree: don't apply this to the root node\n");
					}else if(NodeEditor.getSelectedNode().isClosed()){
						Runtime.warn("Build Tree: Can't rebuild closed node.\n");
					}else{
						options.func(NodeEditor.getSelectedNode(), options.map);
					}
					return true;
				}
			);
			popup.init();
		}
	}
]);

// ----------------------------------------------

if(MinSG.isSet($mergeGeometry)) {
	var fn_buildABTree = fn() {
		var data = new ExtObject();
		data.numTriangles := 1000;
		data.bbEnlargement := 0.0;
		var w = gui.createPopupWindow(400, 120, "Build ABTree");
		w.addOption({
			GUI.LABEL			: "Maximum number of triangles",
			GUI.TOOLTIP			: "The construction of the tree stops when the number of triangles in all nodes falls below this limit.",
			GUI.TYPE			: GUI.TYPE_RANGE,
			GUI.RANGE			: [0, 100000],
			GUI.RANGE_STEPS		: 10000,
			GUI.DATA_OBJECT		: data,
			GUI.DATA_ATTRIBUTE	: $numTriangles
		});
		w.addOption({
			GUI.LABEL			: "Bounding box enlargement",
			GUI.TOOLTIP			: "If this value is greater than zero, the size of bounding boxes of child nodes will be increased on construction to prevent cutting of triangles.\nThis value limits the percantage of the increase.",
			GUI.TYPE			: GUI.TYPE_RANGE,
			GUI.RANGE			: [0.0, 1.0],
			GUI.RANGE_STEPS		: 20,
			GUI.DATA_OBJECT		: data,
			GUI.DATA_ATTRIBUTE	: $bbEnlargement
		});

		w.addAction(
			"Build",
			data -> fn() {
				var geoNodes = MinSG.collectGeoNodes(NodeEditor.getSelectedNode());
				if(geoNodes.size() != 1) {
					out("Failed to extract exactly one GeometryNode. No tree was created.\n");
					return;
				}
				var tree = MinSG.createABTree(geoNodes[0].getMesh(),
											this.numTriangles,
											this.bbEnlargement);
				tree.name := "ABTree scene=" + PADrend.getCurrentScene().name +
							" triangles=" + this.numTriangles +
							" enlargement=" + this.bbEnlargement;
				PADrend.registerScene(tree);
				PADrend.selectScene(tree);
				PADrend.getSceneManager().registerGeometryNodes(tree);
			},
			"Start the construction of an Advanced Binary tree using the triangles of the current scene."
		);
		w.addAction("Cancel");
		w.init();
	};

	var fn_buildkDTree = fn() {
		var data = new ExtObject();
		data.numTriangles := 1000;
		data.bbEnlargement := 0.0;
		var w = gui.createPopupWindow(400, 120, "Build kDTree");
		w.addOption({
			GUI.LABEL			: "Maximum number of triangles",
			GUI.TOOLTIP			: "The construction of the tree stops when the number of triangles in all nodes falls below this limit.",
			GUI.TYPE			: GUI.TYPE_RANGE,
			GUI.RANGE			: [0, 100000],
			GUI.RANGE_STEPS		: 10000,
			GUI.DATA_OBJECT		: data,
			GUI.DATA_ATTRIBUTE	: $numTriangles
		});
		w.addOption({
			GUI.LABEL			: "Bounding box enlargement",
			GUI.TOOLTIP			: "If this value is greater than zero, the size of bounding boxes of child nodes will be increased on construction to prevent cutting of triangles.\nThis value limits the percantage of the increase.",
			GUI.TYPE			: GUI.TYPE_RANGE,
			GUI.RANGE			: [0.0, 1.0],
			GUI.RANGE_STEPS		: 20,
			GUI.DATA_OBJECT		: data,
			GUI.DATA_ATTRIBUTE	: $bbEnlargement
		});

		w.addAction(
			"Build",
			data -> fn() {
				var geoNodes = MinSG.collectGeoNodes(NodeEditor.getSelectedNode());
				if(geoNodes.size() != 1) {
					out("Failed to extract exactly one GeometryNode. No tree was created.\n");
					return;
				}
				var tree = MinSG.createkDTree(geoNodes[0].getMesh(),
											this.numTriangles,
											this.bbEnlargement);
				tree.name := "kDTree scene=" + PADrend.getCurrentScene().name +
							" triangles=" + this.numTriangles +
							" enlargement=" + this.bbEnlargement;
				PADrend.registerScene(tree);
				PADrend.selectScene(tree);
				PADrend.getSceneManager().registerGeometryNodes(tree);
			},
			"Start the construction of a k-D tree using the triangles of the current scene."
		);
		w.addAction("Cancel");
		w.init();
	};

	var fn_buildOctree = fn() {
		var data = new ExtObject();
		data.numTriangles := 1000;
		data.looseFactor := 1.0;
		var w = gui.createPopupWindow(400, 100, "Build Octree");
		w.addOption({
			GUI.LABEL			: "Maximum number of triangles",
			GUI.TOOLTIP			: "The construction of the tree stops when the number of triangles in all nodes falls below this limit.",
			GUI.TYPE			: GUI.TYPE_RANGE,
			GUI.RANGE			: [0, 100000],
			GUI.RANGE_STEPS		: 10000,
			GUI.DATA_OBJECT		: data,
			GUI.DATA_ATTRIBUTE	: $numTriangles
		});
		w.addOption({
			GUI.LABEL			: "Loose factor",
			GUI.TOOLTIP			: "The side length of the bounding boxes will be multiplied by this factor.\n1.0 creates a standard octree, everything greater 1.0 creates a loose octree (2.0 is usually used).",
			GUI.TYPE			: GUI.TYPE_RANGE,
			GUI.RANGE			: [1.0, 5.0],
			GUI.RANGE_STEPS		: 8,
			GUI.DATA_OBJECT		: data,
			GUI.DATA_ATTRIBUTE	: $looseFactor
		});

		w.addAction(
			"Build",
			data->fn() {
				var geoNodes = MinSG.collectGeoNodes(NodeEditor.getSelectedNode());
				if(geoNodes.size() != 1) {
					out("Failed to extract exactly one GeometryNode. No tree was created.\n");
					return;
				}
				var tree = MinSG.createOctree(geoNodes[0].getMesh(),
											this.numTriangles,
											this.looseFactor);
				tree.name := "Octree scene=" + PADrend.getCurrentScene().name +
							" triangles=" + this.numTriangles +
							" looseFactor=" + this.looseFactor;
				PADrend.registerScene(tree);
				PADrend.selectScene(tree);
				PADrend.getSceneManager().registerGeometryNodes(tree);
			},
			"Start the construction of an octree using the triangles of the current scene."
		);
		w.addAction("Cancel");
		w.init();
	};

	var fn_buildRST = fn() {
		var data = new ExtObject();
		var w = gui.createPopupWindow(400, 100, "Build Randomized Sample Tree");

		w.addAction(
			"Build",
			data->fn() {
				var geoNodes = MinSG.collectGeoNodes(NodeEditor.getSelectedNode());
				if(geoNodes.size() != 1) {
					out("Failed to extract exactly one GeometryNode. No tree was created.\n");
					return;
				}
				var tree = MinSG.createRandomizedSampleTree(geoNodes[0].getMesh());
				tree.name := "RandomizedSampleTree scene=" + PADrend.getCurrentScene().name;

				var filterState = new MinSG.ProjSizeFilterState();
				filterState.setMaximumProjSize(10);
				filterState.setTargetChannel("NO_CHANNEL");
				tree.addState(filterState);

				PADrend.registerScene(tree);
				PADrend.selectScene(tree);
				PADrend.getSceneManager().registerGeometryNodes(tree);
			},
			"Start the construction of a Randomized Sample Tree using the triangles of the current scene."
		);
		w.addAction("Cancel");
		w.init();
	};

	gui.registerComponentProvider('NodeEditor_TreeToolsMenu.triangleTrees',[
		'----',
		"*Triangle Trees*",
		{
			GUI.TYPE 		: 	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Merge meshes into single mesh",
			GUI.ON_CLICK	:	fn() {
									var geoNodes = [];
									foreach(NodeEditor.getSelectedNodes() as var selectedNode) {
										geoNodes.append(MinSG.collectGeoNodes(selectedNode));
									}
									var mesh = MinSG.mergeGeometry(geoNodes);
									if(mesh == void) {
										Runtime.warn("No mesh returned.");
										return;
									}
									var geoNode = new MinSG.GeometryNode();
									geoNode.setMesh(mesh);
									var listNode = new MinSG.ListNode();
									listNode.addChild(geoNode);
									PADrend.registerScene(listNode);
									PADrend.selectScene(listNode);
								},
			GUI.TOOLTIP		:	"Collect all meshes from the currently selected nodes,\nmerge them into a single mesh, and create a new scene containing only that mesh."
		},
		{
			GUI.TYPE 		: 	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Build ABTree",
			GUI.ON_CLICK	:	fn_buildABTree,
			GUI.TOOLTIP		:	"Open a dialog for creating an Adaptive Binary tree."
		},
		{
			GUI.TYPE 		: 	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Build kDTree",
			GUI.ON_CLICK	:	fn_buildkDTree,
			GUI.TOOLTIP		:	"Open a dialog for creating a k-D tree."
		},
		{
			GUI.TYPE 		: 	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Build Octree",
			GUI.ON_CLICK	:	fn_buildOctree,
			GUI.TOOLTIP		:	"Open a dialog for creating an octree."
		},
		{
			GUI.TYPE 		: 	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Build Randomized Sample Tree",
			GUI.ON_CLICK	:	fn_buildRST,
			GUI.TOOLTIP		:	"Open a dialog for creating a Randomized Sample Tree."
		}
	]);
}

// ------------------------------------------------------------------------------


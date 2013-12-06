/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010-2011 David Maicher
 * Copyright (C) 2012 Mouns R. Husan Almarrani
 * Copyright (C) 2010-2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] StateConfig/Plugin.escript
 **
 ** Shows and modifies the properties of nodes of he scene graph.
 ** \note Combination of old StateConfig-, GraphDisplay (by Benjamin Eikel)- and MeshTool-Plugin
 **/

declareNamespace($NodeEditor);


/***
 **   NodeEditorPlugin ---|> Plugin
 **/
GLOBALS.NodeEditorPlugin:=new Plugin({
		Plugin.NAME : 'NodeEditor',
		Plugin.DESCRIPTION : "Modifies nodes and states of the scene graph.",
		Plugin.VERSION : 0.2,
		Plugin.REQUIRES : ['PADrend','PADrend/Navigation'],
		Plugin.EXTENSION_POINTS : [


			/* [ext:NodeEditor_OnNodesSelected]
			 * Called whenever the selected nodes change
			 * @param   Array of currently selected nodes (do not change!)
			 * @result  void
			 */
			'NodeEditor_OnNodesSelected',

			/* [ext:NodeEditor_QueryAvailableBehaviours]
			 * Add behaviourss to the list of availabe behaviourss.
			 * @param   Map of available behaviours
			 *          name -> Behaviour | function which returns a Behaviour
			 * @result  void
			 */
			'NodeEditor_QueryAvailableBehaviours',

			/* [ext:NodeEditor_QueryAvailableStates]
			 * Add states to the list of availabe states.
			 * @param   Map of available states (e.g. rendering states)
			 *          name -> State | function which returns a State
			 * @result  void
			 */
			'NodeEditor_QueryAvailableStates'

		]
});

var plugin = NodeEditorPlugin;

// -------------------

plugin.keyMap @(private) := new Map;
plugin.storedSelections := [];
plugin.nodeClipboard @(private):= [];
plugin.nodeClipboardMode @(private) := $COPY; // || $CUT


/**
 * Plugin initialization.
 * ---|> Plugin
 */
plugin.init:=fn() {

	{ /// Register ExtensionPointHandler:
		registerExtension('PADrend_Init',this->this.ex_Init);
		registerExtension('PADrend_UIEvent',this->this.ex_UIEvent);
		registerExtension('PADrend_KeyPressed',this->this.ex_KeyPressed);
		registerExtension('PADrend_AfterRenderingPass',this->this.ex_AfterRenderingPass);
		registerExtension('PADrend_OnSceneSelected',this->this.selectNode); // automatically select the scene
	}

	loadOnce(__DIR__+"/NodeEditor.escript");

	var modules = [
				__DIR__+"/GUI/Plugin.escript",
				__DIR__+"/Transformations.escript",
				__DIR__+"/BehaviourConfig/Plugin.escript" ,
				__DIR__+"/NodeConfig/Plugin.escript" ,
				__DIR__+"/StateConfig/Plugin.escript" ,
				__DIR__+"/Tools/Plugin.escript"
	];

	loadPlugins( modules,true);

	return true;
};

//! [ext:PADrend_Init]
plugin.ex_Init:=fn() {

    this.selectNode(PADrend.getCurrentScene());


	this.keyMap[Util.UI.KEY_DELETE] = this->fn(){				// [entf] delete selected nodes
		var p;
		foreach(NodeEditor.getSelectedNodes() as var node){
			if(node == PADrend.getCurrentScene() || node == PADrend.getRootNode()){
				Runtime.warn("Can't delete active scene or root node.");
				continue;
			}
			p = node.getParent();
			MinSG.destroy(node);
		}
		NodeEditor.selectNode(p);
		return true;
	};
	this.keyMap[Util.UI.KEY_PAGEUP] = this->fn(){				// [pgUp] Select parent nodes of selected nodes
		var oldSelection = this.getSelectedNodes().clone();
		this.selectNode(void);
		foreach(oldSelection as var node){
			if(node.hasParent())
				this.addSelectedNode(node.getParent());
		}
		return true;
	};
	this.keyMap[Util.UI.KEY_PAGEDOWN] = this->fn(){			// [pgDown] Select child nodes of selected nodes
		var selection = new Set;
		foreach(this.getSelectedNodes() as var node){
			foreach(MinSG.getChildNodes(node) as var child){
				selection += child;

				if(selection.count()>=500){
					Runtime.warn("Number of selected Nodes reached 500. Stopping here... ");
					this.selectNodes(selection.toArray());
					return true;
				}
			}
		}
		this.selectNodes(selection.toArray());
		return true;
	};
	this.keyMap[Util.UI.KEY_HOME] = this->fn(){				// [pos1] Select current scene
		this.selectNode( PADrend.getCurrentScene());
		return true;
	};
	this.keyMap[Util.UI.KEY_C] = this->fn(){					// [ctrl] + [c] copy out
		if(PADrend.getEventContext().isCtrlPressed() && !this.getSelectedNodes().empty()){
			this.nodeClipboard = this.getSelectedNodes().clone();
			this.nodeClipboardMode = $COPY;
			PADrend.message(""+this.nodeClipboard.count()," selected nodes copied to clipboard. ");
			return true;
		}
		return false;
	};
	this.keyMap[Util.UI.KEY_D] = this->fn(){					// [ctrl] + [d] duplicate   // \todo USE COMMAND
		if(PADrend.getEventContext().isCtrlPressed()){
			var newNodes = [];
			foreach(this.getSelectedNodes() as var node){
				if(!node.hasParent() || !node.getParent().hasParent()){
					PADrend.message("Can't duplicate scene or root.");
				}else{
					var c = node.clone();
					node.getParent() += c;
					newNodes += c;
					MinSG.initPersistentNodeTraits(c);
				}
			}
			PADrend.message(""+newNodes.count()+" nodes duplicated." );
			this.selectNodes(newNodes);
			return true;
		}

		return false;
	};	
	this.keyMap[Util.UI.KEY_J] = this->fn(){					// [j] Jump to selection
		this.jumpToSelection();
		return true;
	};
	this.keyMap[Util.UI.KEY_X] = this->fn(){					// [ctrl] + [x] cut out
		if(PADrend.getEventContext().isCtrlPressed() && !this.getSelectedNodes().empty()){
			this.nodeClipboard = this.getSelectedNodes().clone();
			this.nodeClipboardMode = $CUT;
			PADrend.message(""+this.nodeClipboard.count()," selected nodes cut out. ");
			return true;
		}
		return false;
	};
	this.keyMap[Util.UI.KEY_V] = this->fn(){					// [ctrl] + [v] paste \todo check for cycles!!!!!!!!!!!!!!!!!!!!!!!!!1
		if(PADrend.getEventContext().isCtrlPressed()){
			// transformations
			if(this.getSelectedNodes().count()!=1 || !(this.getSelectedNode()---|>MinSG.GroupNode)){
				Runtime.warn("Select one GroupNode for pasting.");
				return true;
			}
			var parentNode = this.getSelectedNode();
			if(nodeClipboardMode == $CUT){
				out("Moving cut out nodes to ",NodeEditor.getString(parentNode),": ");
				foreach(this.nodeClipboard as var node){

					if(MinSG.isInSubtree(parentNode,node)){
						Runtime.warn("Skipping node to prevent cycle.");
						continue;
					}
					MinSG.changeParentKeepTransformation(node,parentNode);
					out(".");
				}
				this.selectNodes(nodeClipboard);
				this.nodeClipboard.clear();
				out("\n");
			}else{
				out("Copying nodes to ",NodeEditor.getString(parentNode),": ");
				var clones=[];
				foreach(this.nodeClipboard as var node){

					if(MinSG.isInSubtree(parentNode,node)){
						Runtime.warn("Skipping node to prevent cycle.");
						continue;
					}

					var n2=node.clone();
					MinSG.changeParentKeepTransformation(n2,parentNode);
					clones+=n2;
					MinSG.initPersistentNodeTraits(n2);

					out(".");
				}
				this.selectNodes(clones);
				out("\n");
			}


			return true;
		}

		return false;
	};

	// [0...9] restore selection
	// [ctrl] + [0...9] store selection
	foreach( [Util.UI.KEY_0, Util.UI.KEY_1, Util.UI.KEY_2, Util.UI.KEY_3, Util.UI.KEY_4, Util.UI.KEY_5] as var index,var sym){
		this.keyMap[sym] = this -> (fn(index){
			if(PADrend.getEventContext().isShiftPressed()) // no shift
				return false;

			if(PADrend.getEventContext().isCtrlPressed()){ // store
				out("Storing current selection at #",index,"\n");
				var selection = this.getSelectedNodes().clone();
				this.storedSelections[index] = selection;

				// TEMP This is a temporary solution which is eventually replaced by the scene editor's group management feature
				var ids = [];
				foreach(selection as var node){
					var id = PADrend.getSceneManager().getNameOfRegisteredNode(node);
					if(id)
						ids += id;
				}
				var selectionRegistry = PADrend.getCurrentScene().getNodeAttribute('NodeEditor_selections');
				if(!selectionRegistry)
					selectionRegistry = new Map;

				if(ids.empty()){
					selectionRegistry.unset(index);
				}else{
					selectionRegistry[index] = ids;
				}
				if(selectionRegistry.empty()){
					PADrend.getCurrentScene().unsetNodeAttribute('NodeEditor_selections');
				}else{
					PADrend.getCurrentScene().setNodeAttribute('NodeEditor_selections',selectionRegistry);
				}

			} else {
				var selection = this.storedSelections[index];
				if(!selection){
					var selectionRegistry = PADrend.getCurrentScene().getNodeAttribute('NodeEditor_selections');
					if(selectionRegistry && selectionRegistry[index]){
						selection = [];
						foreach(selectionRegistry[index] as var nodeId){
							var n = PADrend.getSceneManager().getRegisteredNode(nodeId);
							if(n)
								selection += n;
						}
						this.storedSelections[index] = selection;
					}
				}
				if(!selection){
					Runtime.warn("No selection stored at #"+index);
				}else{
					if(selection == this.getSelectedNodes()){
						this.jumpToSelection();
					} else {
						out("Restoring selection #",index,"\n");
						this.selectNodes(selection);

					}
				}
			}
			return true;
		}).bindLastParams(index);
	}
	this.storedSelections[0] = [PADrend.getRootNode()];



	// temporary!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	this.follower := void;
	this.keyMap[Util.UI.KEY_L] = this->fn(){					// [l] Lock to selection
		var dolly = PADrend.getDolly();
		var camera = PADrend.getActiveCamera();
		if(follower){
				PADrend.message("Following Object stopped.");
			follower.active = false;
			follower = void;
			var originalPos = camera.getWorldPosition();
			camera.setRelPosition(new Geometry.Vec3(0,0,0));
			dolly.moveLocal( dolly.worldDirToLocalDir(originalPos-camera.getWorldPosition()  ));
		}else if(NodeEditor.getSelectedNode()) {
			PADrend.message("Following Object '"+NodeEditor.getSelectedNode()+"'");
			follower = new ExtObject({
				$active : true,
				$node : NodeEditor.getSelectedNode(),
				$execute : fn(p...){
					if(!active)
						return Extension.REMOVE_EXTENSION;
					dolly.setWorldPosition(node.getWorldBB().getCenter());
					return Extension.CONTINUE;
				}
			});
			registerExtension('PADrend_AfterFrame',follower->follower.execute);
			camera.setRelPosition(new Geometry.Vec3(0,0,NodeEditor.getSelectedNode().getWorldBB().getDiameter()));
			out(-NodeEditor.getSelectedNode().getWorldBB().getDiameter()*1.5);
		}
		return true;
	};


};

//! [ext:PADrend_KeyPressed]
plugin.ex_KeyPressed:=fn(evt) {
	var handler = this.keyMap[evt.key];
	return handler ? handler() : false;
};

//! [ext:UIEvent]
plugin.ex_UIEvent:=fn(evt){
	if(	evt.type==Util.UI.EVENT_MOUSE_BUTTON &&
			(evt.button == Util.UI.MOUSE_BUTTON_LEFT || evt.button == Util.UI.MOUSE_BUTTON_RIGHT) &&
			evt.pressed &&
			PADrend.getEventContext().isCtrlPressed()) {

		var r=new MinSG.RendRayCaster;

		var node = r.queryNodeFromScreen(frameContext,PADrend.getRootNode(),new Geometry.Vec2(evt.x,evt.y),true);
		if(node && evt.button == Util.UI.MOUSE_BUTTON_RIGHT)
			node = objectIdentifier(node);

		if(PADrend.getEventContext().isShiftPressed()){
			if(node){
				if(isNodeSelected(node))
					unselectNode(node);
				else
					addSelectedNode(node);
			}
		}else{
			selectNode(node);
		}
		return true;
	}


	return false;
};

plugin.COLOR_BG_NODE := new Util.Color4f(0,0,0,1);
plugin.COLOR_BG_SEM_OBJ := new Util.Color4f(0,0.4,0,1);
plugin.COLOR_TEXT_ORIGINAL := new Util.Color4f(1,1,1,1);
plugin.COLOR_TEXT_INSTANCE := new Util.Color4f(0.9,0.9,0.9,1);

//! [ext:PADrend_AfterRenderingPass]
plugin.ex_AfterRenderingPass:=fn(pass){
	var skipAnnotations = selectedNodes.count()>20;
	foreach(selectedNodes as var node){
		if(!node || node==PADrend.getCurrentScene() || node==PADrend.getRootNode())
			continue;

		
		if(!skipAnnotations){
			frameContext.showAnnotation(node,NodeEditor.getString(node),0,true,
										node.isInstance() ? COLOR_TEXT_INSTANCE : COLOR_TEXT_ORIGINAL,
										MinSG.SemanticObjects.isSemanticObject(node) ? COLOR_BG_SEM_OBJ : COLOR_BG_NODE  );
		}

		renderingContext.pushMatrix();
		renderingContext.resetMatrix();
		renderingContext.multMatrix(node.getWorldMatrix());

		var bb = node.getBB();

		var blending=new Rendering.BlendingParameters();
		blending.enable();
		blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA, Rendering.BlendFunc.ONE);
		renderingContext.pushAndSetBlending(blending);
		renderingContext.pushAndSetDepthBuffer(true, false, Rendering.Comparison.LEQUAL);
		renderingContext.pushAndSetLighting(false);
		renderingContext.pushAndSetPolygonOffset(-1.0, -1.0);
		renderingContext.applyChanges();
		Rendering.drawWireframeBox(renderingContext, bb, new Util.Color4f(1.0, 1.0, 1.0, 0.4));
		Rendering.drawBox(renderingContext, bb, new Util.Color4f(1.0, 1.0, 1.0, 0.2));
		renderingContext.popMatrix();
		renderingContext.popPolygonOffset();
		renderingContext.popLighting();
		renderingContext.popDepthBuffer();
		renderingContext.popBlending();
	}
    return;
};

//--------------------------------

//! @name Node selection
// @{
plugin.selectedNodes @(private):= [];
plugin.selectedNodesSet @(private):= new Set;
plugin.objectIdentifier @(private):= fn(node){
	
	var semObj = MinSG.SemanticObjects.isSemanticObject(node) ? node :	MinSG.SemanticObjects.getContainingSemanticObject(node);
	if( semObj ){
		
		//! \todo This should be integrated into the selection method.
		while(true){
			var next = MinSG.SemanticObjects.getContainingSemanticObject(semObj);
			if(!next || isNodeSelected(next))
				break;
			semObj = next;
		}
		return semObj;
	}

	while( node && node.isInstance()&& node.hasParent()&&node.getParent().isInstance())
		node = node.getParent();
	return node;
};

plugin.addSelectedNode :=	fn(MinSG.Node node){	addSelectedNodes([node]);	};

plugin.addSelectedNodes:=fn(Array nodesToSelect){
	foreach(nodesToSelect as var n){
		if(!n || selectedNodesSet.contains(n))
			continue;
		selectedNodesSet+=n;
		selectedNodes+=n;
	}
	onSelectionChanged();
};

plugin.clearNodeSelection := fn(){
	selectedNodes.clear();
	selectedNodesSet.clear();
	onSelectionChanged();
};

plugin.getSelectedNode := 	fn(){   	return this.selectedNodes.front();	};
plugin.getSelectedNodes := 	fn(){		return this.selectedNodes.clone();	};
plugin.isNodeSelected := 	fn(node){	return this.selectedNodesSet.contains(node);	};

plugin.jumpToSelection := fn(time=0.5){
	if( getSelectedNode() ){
		var box = MinSG.combineNodesWorldBBs(selectedNodes);

		var targetDir = (box.getCenter() - PADrend.getDolly().getWorldPosition()).normalize();
		var target = new Geometry.SRT( box.getCenter() - targetDir * box.getExtentMax() * 1.0, -targetDir, PADrend.getWorldUpVector());
		PADrend.Navigation.flyTo(target);
	}
};

/*! Called whenever the node selection is changed. May be called explicitly to trigger
	an update of all corresponding listeners.*/
plugin.onSelectionChanged := fn(){		executeExtensions('NodeEditor_OnNodesSelected',selectedNodes);	};

plugin.selectNode:=fn([MinSG.Node,void] node){
    if(node){
		selectedNodes.clear();
		selectedNodesSet.clear();
		addSelectedNode(node);
    }else{
		clearNodeSelection();
    }
};

plugin.selectNodes:=fn(Array nodesToSelect){
    selectedNodes.clear();
    selectedNodesSet.clear();
	addSelectedNodes(nodesToSelect);
};

plugin.setObjectIdentifier := 	fn(fun){		objectIdentifier = fun;	};

plugin.unselectNode :=			fn(MinSG.Node node){	unselectNodes([node]);	};

plugin.unselectNodes:=fn(Array nodesToRemove){
	foreach(nodesToRemove as var n){
		if(objectIdentifier)
			n = objectIdentifier(n);
		if(n)
			selectedNodesSet -= n;
	}
	selectedNodes.filter( [selectedNodesSet] => fn(selectedNodesSet,node){ return selectedNodesSet.contains(node);} );
	onSelectionChanged();
};

// @}

//--------------------------------
// aliases

NodeEditor.addSelectedNode := plugin->plugin.addSelectedNode;
NodeEditor.addSelectedNodes := plugin->plugin.addSelectedNodes;
NodeEditor.getSelectedNode := plugin->plugin.getSelectedNode;
NodeEditor.getSelectedNodes := plugin->plugin.getSelectedNodes;
NodeEditor.onSelectionChanged := plugin->plugin.onSelectionChanged;
NodeEditor.selectNode := plugin->plugin.selectNode;
NodeEditor.selectNodes := plugin->plugin.selectNodes;
NodeEditor.setObjectIdentifier := plugin->plugin.setObjectIdentifier;
NodeEditor.unselectNode := plugin->plugin.unselectNode;
NodeEditor.unselectNodes := plugin->plugin.unselectNodes;


// -------------------------------

return plugin;
// ------------------------------------------------------------------------------

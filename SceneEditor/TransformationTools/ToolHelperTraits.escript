/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static ToolHelperTraits = new Namespace;

// -----------------------------------------------------------------------------------


/*! The given type represents an UITool.
	Adds the following methods:

	- onToolActivation_static		Static MultiProcedure called whenever the tool is enabled.
	- onToolActivation				MultiProcedure called whenever the tool is enabled.
	- onToolDeactivation_static		Static MultiProcedure called whenever the tool is disabled.
	- onToolDeactivation			MultiProcedure called whenever the tool is disabled.
*/
ToolHelperTraits.UIToolTrait := new Traits.GenericTrait("ToolHelperTraits.UIToolTrait");
{
	var t = ToolHelperTraits.UIToolTrait;

	t.attributes.onToolActivation_static ::= void;
	t.attributes.onToolActivation @(init) := Std.MultiProcedure;
	
	t.attributes.onToolDeactivation_static ::= void;
	t.attributes.onToolDeactivation @(init) := Std.MultiProcedure;
	
	t.attributes.onToolInitOnce_static ::= void;
	t.attributes.onToolInitOnce @(init) := Std.MultiProcedure;
	
	t.attributes.activateTool ::= fn(){
		if(onToolInitOnce){
			onToolInitOnce_static();
			onToolInitOnce();
			onToolInitOnce = void;
		}
		onToolActivation_static();
		onToolActivation();
		return this;
	};

	t.attributes.deactivateTool ::= fn(){
		onToolDeactivation();
		onToolDeactivation_static();
		return this;
	};
	
	t.onInit += fn(obj){
		obj.onToolActivation_static = new MultiProcedure;
		obj.onToolDeactivation_static = new MultiProcedure;
		obj.onToolInitOnce_static = new MultiProcedure;
	};
}

// -----------------------------------------------------------------------------------

/*!	Adds a handler that is called before each frame while enabled.
	Adds the following methods:

	- enableFrameListener		Enables the frame listening (may be safely called if already enabled).
	- disableFrameListener		Disables the frame listening  (may be safely called if already disabled).
	- isFrameListenerActive		Returns whether the frame listening is enabled.
	- onFrame					MultiProcedure called before each frame while enabled.
	- onFrame_static			Static MultiProcedure called before each frame while enabled.

*/
ToolHelperTraits.FrameListenerTrait := new Traits.GenericTrait("ToolHelperTraits.FrameListenerTrait");
{
	var t = ToolHelperTraits.FrameListenerTrait;
	
	t.attributes.onFrame_static ::= void;
	t.attributes.onFrame @(init) := Std.MultiProcedure;
	t.attributes._revoceFrameListener @(private) := void; // void | MultiProcedure

	t.attributes.enableFrameListener ::= fn(){
		if(!this._revoceFrameListener){
			this._revoceFrameListener = new Std.MultiProcedure;
			// use beforeRendering instead of afterRendering to keep the editNode and the moved nodes in sync.
			this._revoceFrameListener += Util.registerExtensionRevocably('PADrend_BeforeRendering', this->fn(...){
				this.onFrame_static();
				this.onFrame();
			}); 
		}
		return this;
	};

	t.attributes.disableFrameListener ::= fn(){
		if(this._revoceFrameListener){
			this._revoceFrameListener();
			this._revoceFrameListener = void;
		}
		return this;
	};
	t.attributes.isFrameListenerActive ::= fn(){
		return true & this._revoceFrameListener;
	};
	t.onInit += fn(obj){
		obj.onFrame_static = new MultiProcedure;
	};
}

// -----------------------------------------------------------------------------------

/*!	Adds a handler that is called whenever the NodeEditor's node selection changes.
	The handler is also called when the listener is started with the initially selected nodes 
	and -- if nodes are selected while the listener is finalized -- when the listener is finalized 
	with an empty array.

	Adds the following methods:
	
	- finalizeNodeSelectionListener	Disables the listening and if nodes are selected, calls the onNodesSelected 
									handlers with an empty array. (may be safely called if already disabled).
	- getSelectedNodes				returns the array of currently selected nodes.
	- onNodesSelected(nodes)		MultiProcedure called when the node selection changes. The selected Nodes are given as parameter.
	- onNodesSelected_static(nodes)	Static MultiProcedure called when the node selection changes. The selected Nodes are given as parameter.
	- startNodeSelectionListener	Enables the listening and calls the onNodesSelected handlers
									with the initially selected nodes (may be safely called if already enabled) 

	\see NodeEditor Plugin
*/
ToolHelperTraits.NodeSelectionListenerTrait := new Traits.GenericTrait("ToolHelperTraits.NodeSelectionListenerTrait");
{
	var t = ToolHelperTraits.NodeSelectionListenerTrait;
	
	t.attributes._nodeSelectionChangedHandler @(private) := void; 
	t.attributes._selectedNodes @(private,init) := Array;

	t.attributes.onNodesSelected_static ::= void;
	t.attributes.onNodesSelected @(init) := Std.MultiProcedure;

	t.attributes.startNodeSelectionListener ::= fn(){
		if(!_nodeSelectionChangedHandler){
			_nodeSelectionChangedHandler = this->fn(Array nodes){
				_selectedNodes.swap(nodes.clone());
				onNodesSelected_static(_selectedNodes);
				onNodesSelected(_selectedNodes);
			};
			Util.registerExtension('NodeEditor_OnNodesSelected', _nodeSelectionChangedHandler);
			_nodeSelectionChangedHandler( NodeEditor.getSelectedNodes() );
		}
		return this;
	};
	t.attributes.finalizeNodeSelectionListener ::= fn(){
		if(_nodeSelectionChangedHandler){
			removeExtension('NodeEditor_OnNodesSelected', _nodeSelectionChangedHandler);
			if(!_selectedNodes.empty())
				_nodeSelectionChangedHandler( [] ); //clean up by calling handler with empty array.
			_nodeSelectionChangedHandler = void;
		}
		return this;
	};
	
	t.attributes.getSelectedNodes ::= fn(){
		return _selectedNodes;
	};
	
	t.onInit += fn(obj){
		obj.onNodesSelected_static = new MultiProcedure;
	};
}

// -----------------------------------------------------------------------------------

/*! Adds methods to add entries to the right-click context menu.
	Adds the following methods:
	
	- (---o) doCreateContextMenu()	Function returning a gui menu (Array, componentId, ...).
	- enableContextMenu()			Set the menu provider.
	- disableContextMenu()		Remove a menu provider if set.
	
	\see PADrend.GUI
*/
ToolHelperTraits.ContextMenuProviderTrait := new Traits.GenericTrait("ToolHelperTraits.ContextMenuProviderTrait");
{
	var t = ToolHelperTraits.ContextMenuProviderTrait;
	
	//! ---o
	t.attributes.doCreateContextMenu ::= fn(){	return [];	};
	
	t.attributes.enableContextMenu ::= fn(){
		gui.register('PADrend_UIToolConfig.01_ToolConfig',this->doCreateContextMenu);
	};
	t.attributes.disableContextMenu ::= fn(){
		gui.unregisterComponentProvider('PADrend_UIToolConfig.01_ToolConfig');
	};
}

/*!	Adds methods to handle the transformation of nodes based on Commands.
	Adds the following methods:

	- applyNodeTransformations()		Applies all pending transformations by creating an corresponding command.
	- getTransformedNodes()				Get all nodes set by the last setTransformedNodes(...) call.
	- getTransformedNodesOrigins()		Get a map from all transformed nodes mapped to their original transformation matrices.
	- setTransformedNodes(Array nodes)	Applies the pending transformations by calling applyNodeTransformations() and
										memorizes the new transformed nodes and their current transformations.

	\see PADrend.CommandHandling
*/
ToolHelperTraits.NodeTransformationHandlerTrait := new Traits.GenericTrait("ToolHelperTraits.NodeTransformationHandlerTrait");
{
	var t = ToolHelperTraits.NodeTransformationHandlerTrait;
	
	t.attributes._transfomredNodesOrigins @(init,private):= Map; //!< During transformation, this contains node -> original matrix.
	t.attributes._transformedNodes @(init,private):= Array; 
	
	t.attributes._doApplyTransformations @(private) ::= fn(){
		if(!_transfomredNodesOrigins.empty()){
			var aExecute = [];
			var aUndo = [];
			var differenceFound = false;
			foreach(_transfomredNodesOrigins as var node,var origin){
				var newMatrix = node.getRelTransformationMatrix();
				if(origin!=newMatrix)
					differenceFound = true;
				
				aExecute+=[node,newMatrix];
				aUndo+=[node,origin];
			}
			if(differenceFound){
				var fun = fn(){	foreach(this as var a)	a[0].setRelTransformation(a[1].convertsSafelyToSRT() ? a[1]._toSRT() : a[1]); };
				static Command = Std.module('LibUtilExt/Command');
				PADrend.executeCommand({
					Command.DESCRIPTION : "Transform nodes",
					Command.EXECUTE : 	aExecute->fun,
					Command.UNDO : 		aUndo->fun
				});
			}
			_transfomredNodesOrigins.clear();			
		}
	};
	
	t.attributes.applyNodeTransformations ::= fn(){
		_doApplyTransformations();
		foreach(_transformedNodes as var node)
			_transfomredNodesOrigins[node] = node.getRelTransformationMatrix();
		return this;	
	};
	
	t.attributes.setTransformedNodes ::= fn(Array nodes){
		_doApplyTransformations();
		_transformedNodes.swap(nodes.clone());
		foreach(nodes as var node)
			_transfomredNodesOrigins[node] = node.getRelTransformationMatrix();	
		return this;	
	};
	
	t.attributes.getTransformedNodesOrigins 	::= 	fn(){	return _transfomredNodesOrigins;	};
	t.attributes.getTransformedNodes 	 		::= 	fn(){	return _transformedNodes;	};
}

// -----------------------------------------------------------------------------------

/*! Adds methods for managing a meta node in PADrend.NodeInteraction.
	Adds the following methods:
	- enableMetaNode()			Activate and register the stored node.
	- destroyMetaNode()			Deactivate, unregister and destroy the stored node.
	- disableMetaNode()			Deactivate and unregister the stored node.
	- getMetaNode()				Return the stored node.
	- setMetaNode(MinSG.Node)	Set the node.

	\see PADrend.NodeInteraction
*/
ToolHelperTraits.MetaNodeContainerTrait := new Traits.GenericTrait("ToolHelperTraits.MetaNodeContainerTrait");
{
	var t = ToolHelperTraits.MetaNodeContainerTrait;
	
	t.attributes._metaNode @(private) := void;
	
	t.attributes.enableMetaNode ::= fn(){
		if(_metaNode && !_metaNode.isActive()){
			PADrend.NodeInteraction.addMetaNode( _metaNode );
			_metaNode.activate();
		}
		return this;	
	};
	t.attributes.destroyMetaNode ::= fn(){
		if(this._metaNode){
			this.disableMetaNode();
			MinSG.destroy(this._metaNode);
			this._metaNode = void;
		}
		return this;	
	};
	t.attributes.disableMetaNode ::= fn(){
		if(_metaNode && _metaNode.isActive()){
			PADrend.NodeInteraction.removeMetaNode( _metaNode );
			_metaNode.deactivate();
		}
		return this;	
	};
	t.attributes.getMetaNode ::= fn(){	return _metaNode;	};
	t.attributes.setMetaNode ::= fn(MinSG.Node n){
		disableMetaNode(); // disable old node
		_metaNode = n;
		_metaNode.deactivate();
		return this;
	};
}

// -----------------------------------------------------------------------------------

/*! Adds and initializes a bunch of traits useful for a transformation tool.

	- general UITool enabling and disabling 		\see ToolHelperTraits.UIToolTrait
	- per frame actions								\see ToolHelperTraits.FrameListenerTrait
	- extension to the right click context menu		\see ToolHelperTraits.ContextMenuProviderTrait
	- an interactive meta node						\see ToolHelperTraits.MetaNodeContainerTrait
	- a listener for changed node selections		\see ToolHelperTraits.NodeSelectionListenerTrait
	- wrapping node transformations in commands		\see ToolHelperTraits.NodeTransformationHandlerTrait

*/
ToolHelperTraits.GenericNodeTransformToolTrait := new Traits.GenericTrait("ToolHelperTraits.GenericNodeTransformToolTrait");
{
	var t = ToolHelperTraits.GenericNodeTransformToolTrait;
	
	t.onInit += fn(obj){
		//! \see ToolHelperTraits.UIToolTrait
		Std.Traits.addTrait(obj,ToolHelperTraits.UIToolTrait);

		//! \see ToolHelperTraits.FrameListenerTrait
		Std.Traits.addTrait(obj,ToolHelperTraits.FrameListenerTrait);

		//! \see ToolHelperTraits.ContextMenuProviderTrait
		Std.Traits.addTrait(obj,ToolHelperTraits.ContextMenuProviderTrait);

		//! \see ToolHelperTraits.MetaNodeContainerTrait
		Std.Traits.addTrait(obj,ToolHelperTraits.MetaNodeContainerTrait);

		//! \see ToolHelperTraits.NodeSelectionListenerTrait
		Std.Traits.addTrait(obj,ToolHelperTraits.NodeSelectionListenerTrait);

		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		Std.Traits.addTrait(obj,ToolHelperTraits.NodeTransformationHandlerTrait);


		//! \see ToolHelperTraits.NodeSelectionListenerTrait
		obj.onNodesSelected_static += fn(Array selectedNodes){
			if(selectedNodes.empty()){
				//! \see ToolHelperTraits.FrameListenerTrait
				disableFrameListener();

				//! \see ToolHelperTraits.MetaNodeContainerTrait
				disableMetaNode();
			}else{
				//! \see ToolHelperTraits.FrameListenerTrait
				enableFrameListener();

				//! \see ToolHelperTraits.MetaNodeContainerTrait
				enableMetaNode();
			}
			//! \see ToolHelperTraits.NodeTransformationHandlerTrait
			setTransformedNodes(selectedNodes);
		};

		
		//! \see ToolHelperTraits.UIToolTrait
		obj.onToolActivation_static += fn(){
			//! \see ToolHelperTraits.NodeSelectionListenerTrait
			startNodeSelectionListener();
			
			//! \see ToolHelperTraits.ContextMenuProviderTrait
			enableContextMenu();
		};
		
		
		//! \see ToolHelperTraits.UIToolTrait
		obj.onToolDeactivation_static += fn(){
			//! \see ToolHelperTraits.ContextMenuProviderTrait
			disableContextMenu();

			//! \see ToolHelperTraits.NodeSelectionListenerTrait
			finalizeNodeSelectionListener();
		};	
	};
}

return ToolHelperTraits;

//---------------------------------------------------------------------------------

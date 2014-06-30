/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] NodeEditor/NoderEditor.escript
 **
 ** Shows and modifies the properties of nodes of he scene graph.
 ** \note Combination of old StateConfig-, GraphDisplay (by Benjamin Eikel)- and MeshTool-Plugin
 **/
 
declareNamespace($NodeEditor);

// --------------------------------------------------------------------------------------------------------------

//! @name Factories (for Nodes and States)
// @{
NodeEditor.nodeFactories := new Map;  //!<  human readable string -> factory function returning a MinSG.Node
////////NodeEditor.stateFactories := new Map();  //!<  human readable string -> factory function returning a MinSG.State
//	@}

// ----------------------------------------------------------------

//! @name String conversions
// @{
//! Get a descriptive string for the given Node or State
NodeEditor.getString := new (Std.require('LibUtilExt/TypeBasedHandler'))(false);

NodeEditor.getString += [Object,fn(obj){return obj.toString();}];
NodeEditor.getString += [MinSG.Node, fn(node){
	var t="";
	if(node.getAttribute("name"))
		t+="Name: "+node.name+" | ";

	var id=PADrend.getSceneManager().getNameOfRegisteredNode(node);
	if(id)
		t+="Id: "+id+" | ";

	if(node.isInstance()){
		var prototypeName = PADrend.getSceneManager().getNameOfRegisteredNode(node.getPrototype());
		if(!prototypeName) prototypeName = ""+node.getPrototype();
		t+="Instance:"+prototypeName+" | ";
	}
	t+=node.getTypeName();

	if(node.isTempNode())
		t+="(temp) ";

	if(node ---|> MinSG.GeometryNode) {
		t+=" (" + node.getTriangleCount() + " triangles)";
	}else if(node ---|> MinSG.GroupNode) {
		t+=" ("+node.countChildren()+" children)";
	}
	if(node.hasStates())
		t+="*";
    return t;
}];
NodeEditor.getString += [MinSG.State, fn(state){
	var t="";
	if(state.getAttribute("name"))
		t+="Name: "+state.name+" | ";

	var id=PADrend.getSceneManager().getNameOfRegisteredState(state);
	if(id)
		t+="Id: "+id+" | ";
	t+=state.toString();

    return t;	
}];

NodeEditor.getNodeString:=fn(node){
	return NodeEditor.getString(node);
};

NodeEditor.getStateString:=fn(state){
	return NodeEditor.getString(state);
};
//	@}



//--------------------------------

//! @name Node selection
// @{
{
	
static selectedNodes = [];
static selectedNodesSet = new Std.Set;

NodeEditor.addSelectedNode :=	fn(MinSG.Node node){	NodeEditor.addSelectedNodes([node]);	};

NodeEditor.addSelectedNodes := fn(Array nodesToSelect){
	foreach(nodesToSelect as var n){
		if(n && !selectedNodesSet.contains(n)){
			selectedNodesSet+=n;
			selectedNodes+=n;
			
		}
	}
	NodeEditor.onSelectionChanged(selectedNodes);
};

NodeEditor.clearNodeSelection := fn(){
	selectedNodes.clear();
	selectedNodesSet.clear();
	NodeEditor.onSelectionChanged(selectedNodes);
};

NodeEditor.getSelectedNode := 	fn(){   	return selectedNodes.front();	};
NodeEditor.getSelectedNodes := 	fn(){		return selectedNodes.clone();	};
NodeEditor.isNodeSelected := 	fn(node){	return selectedNodesSet.contains(node);	};

NodeEditor.jumpToSelection := fn(time=0.5){
	if( getSelectedNode() ){
		var box = MinSG.combineNodesWorldBBs(selectedNodes);

		var targetDir = (box.getCenter() - PADrend.getDolly().getWorldPosition()).normalize();
		var target = new Geometry.SRT( box.getCenter() - targetDir * box.getExtentMax() * 1.0, -targetDir, PADrend.getWorldUpVector());
		PADrend.Navigation.flyTo(target);
	}
};

/*! Called whenever the node selection is changed. May be called explicitly to trigger
	an update of all corresponding listeners.*/
NodeEditor.onSelectionChanged := new Std.MultiProcedure;

NodeEditor.refreshSelectedNodes := fn(){
	NodeEditor.onSelectionChanged( selectedNodes );
};

NodeEditor.selectNode := fn([MinSG.Node,void] node){
    if(node){
		selectedNodes.clear();
		selectedNodesSet.clear();
		NodeEditor.addSelectedNode(node);
    }else{
		NodeEditor.clearNodeSelection();
    }
};

NodeEditor.selectNodes := fn(Array nodesToSelect){
    selectedNodes.clear();
    selectedNodesSet.clear();
	NodeEditor.addSelectedNodes(nodesToSelect);
};

NodeEditor.unselectNode :=			fn(MinSG.Node node){	NodeEditor.unselectNodes([node]);	};

NodeEditor.unselectNodes:=fn(Array nodesToRemove){
	foreach(nodesToRemove as var n)
		selectedNodesSet -= n;
	selectedNodes.filter( [selectedNodesSet] => fn(selectedNodesSet,node){ return selectedNodesSet.contains(node);} );
	NodeEditor.onSelectionChanged(selectedNodes);
};

}

// @}

return NodeEditor;
// ----------------------------------------------------------------

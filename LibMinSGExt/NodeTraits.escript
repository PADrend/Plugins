/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[LibMinSGExt] NodeTraits.escript
 **
 **  Node extensions and traits
 **/


// -------------------------------------
// PersistentNodeTrait

MinSG.ATTR_NODE_TRAITS @(const) := 'nodeTraits';

/*! The Trait is stored persistently at a MinSG.Node. Internally, the trait's name is stored
	as node attribute, so that the trait can be re-added when the node is loaded.	*/
MinSG.PersistentNodeTrait := new Type(Traits.GenericTrait);
{
	var T = MinSG.PersistentNodeTrait;
	T._printableName @(override) ::= $PersistentNodeTrait;
	T._constructor ::= fn(String traitName)@(super(traitName)){
		this.onInit += fn(MinSG.Node node){
			if(node.isInstance()){
				var pTraitList = node.getPrototype().getNodeAttribute(MinSG.ATTR_NODE_TRAITS);
				if(pTraitList && pTraitList.contains(this.getName()))	// trait is set in prototype; don't store here
					return;
			}
			var localTraitList = node.getNodeAttribute(MinSG.ATTR_NODE_TRAITS);
			if(!localTraitList)
				localTraitList = [];
			var tName = this.getName();
			if(!localTraitList.contains(tName)){
				localTraitList += tName;
				node.setNodeAttribute(MinSG.ATTR_NODE_TRAITS,localTraitList);
			}
		};
	};
}
/*! Call to init all persistent node traits in the given subtree. If a Trait is already initialized, it is skipped.*/
MinSG.initPersistentNodeTraits := fn(MinSG.Node root){
	var nodes = MinSG.collectNodesReferencingAttribute(root,MinSG.ATTR_NODE_TRAITS);
	foreach(nodes as var node){
		foreach(MinSG.getPersistentNodeTraitNames(node) as var traitName){
			try{
				if(!Traits.queryTrait(node,traitName)){
					Traits.addTraitByName(node,traitName);
					outln("Adding trait ",traitName," to ",node);
				}
			}catch(e){
				PADrend.message(e);
			}
		}
	}
};

MinSG.getLocalPersistentNodeTraitNames := fn(MinSG.Node node){
	var traitList = node.getNodeAttribute(MinSG.ATTR_NODE_TRAITS);
	return traitList ? traitList : [];
};

MinSG.getPersistentNodeTraitNames := fn(MinSG.Node node){
	return node.isInstance() ? 
					MinSG.getLocalPersistentNodeTraitNames(node.getPrototype()).append(MinSG.getLocalPersistentNodeTraitNames(node)) : 
					MinSG.getLocalPersistentNodeTraitNames(node);
};

// -------------------------------------

/*! Each transformation of a node in the node's subtree invokes a call to node.onNodeTransformed(transformedNode).
	Parameters:
		[optional] functions that are initially added to the observer MultiProcedure.
	Adds the following attributes:
	 - onNodeTransformed  	MultiProcedure		*/
MinSG.TransformationObserverTrait := new Traits.GenericTrait('MinSG.TransformationObserverTrait');
{
	var t = MinSG.TransformationObserverTrait;
	t.attributes.onNodeTransformed @(init) := MultiProcedure;
	t.onInit += fn(MinSG.Node node,p...){
		node._enableTransformationObserver();
		foreach(p as var fun)
			node.onNodeTransformed += fun;
	};
}

/*! After a new node is added to the node's subtree, node.onNodeAdded(newNode) is called.
	Parameters:
		[optional] functions that are initially added to the observer MultiProcedure.
	Adds the following attributes:
	 - onNodeAdded  	MultiProcedure		*/
MinSG.NodeAddedObserverTrait := new Traits.GenericTrait('MinSG.NodeAddedObserverTrait');
{
	var t = MinSG.NodeAddedObserverTrait;
	t.attributes.onNodeAdded @(init) := MultiProcedure;
	t.onInit += fn(MinSG.Node node,p...){
		node._enableNodeAddedObserver();
		foreach(p as var fun)
			node.onNodeAdded += fun;
	};
}

/*! After a node is removed from the node's subtree, node.onNodeRemoved(parent, removedNode) is called.
	Parameters:
		[optional] functions that are initially added to the observer MultiProcedure.
	Adds the following attributes:
	 - onNodeRemoved  	MultiProcedure		*/
MinSG.NodeRemovedObserverTrait := new Traits.GenericTrait('MinSG.NodeRemovedObserverTrait');
{
	var t = MinSG.NodeRemovedObserverTrait;
	t.attributes.onNodeRemoved @(init) := MultiProcedure;
	t.onInit += fn(MinSG.Node node,p...){
		node._enableNodeRemovedObserver();
		foreach(p as var fun)
			node.onNodeRemoved += fun;
	};
}

/*! Before a scene is saved, the node's onSave() multiProcedure is called. 
	Adds the following attributes:
	 - onSaveScene(SceneManager)  	MultiProcedure		
	\code
		{
			Traits.addTrait(NodeEditor.getSelectedNode(),MinSG.SaveSceneListenerNodeTrait);
			NodeEditor.getSelectedNode().onSaveScene += fn(...){outln("Huhu!");};
		}
	\endcode
*/
MinSG.SaveSceneListenerNodeTrait := new MinSG.PersistentNodeTrait('MinSG.SaveSceneListenerNodeTrait');
{
	var t = MinSG.SaveSceneListenerNodeTrait;
	var MARKER_ATTRIBUTE = '$sic$containsOnSaveMethod';// privateAttribute
	var saveFn = MinSG.SceneManager.saveMinSGFile;
	
	// annotate saveMinSGFile
	MinSG.SceneManager.saveMinSGFile @(override) ::= [MARKER_ATTRIBUTE,saveFn] => fn(MARKER_ATTRIBUTE,saveFn, filename, nodes, p... ){
		foreach(nodes as var root){
			foreach(MinSG.collectNodesWithAttribute(root,MARKER_ATTRIBUTE) as var node){
				if(node.isSet($onSaveScene))
					node.onSaveScene(this);
			}
		}
		return (this->saveFn)(filename,nodes,p...);
	};

	t.onInit += [MARKER_ATTRIBUTE] => fn(MARKER_ATTRIBUTE, MinSG.Node node){
		/*
		\todo EScript.VERSION >= 607
			@(once){
				static originalSaveFun;
				// init saveMinSGFile hook only if necessary
			}
		
		*/
		
		node.setNodeAttribute(MARKER_ATTRIBUTE,true); 
		node.onSaveScene := new MultiProcedure;
	};
}


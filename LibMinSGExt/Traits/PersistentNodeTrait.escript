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

/*! PersistentNodeTrait
	Base class for node-traits that are stored when exporting a node to a minsg file (using node attributes).
*/

static ATTR_NODE_TRAITS = 'nodeTraits';

static getLocalPersistentNodeTraitNames = fn(MinSG.Node node){
	var traitList = node.getNodeAttribute(ATTR_NODE_TRAITS);
	return traitList ? traitList.split(",") : [];
};

static getPersistentNodeTraitNames = fn(MinSG.Node node){
	return node.isInstance() ? 
					getLocalPersistentNodeTraitNames(node.getPrototype()).append(getLocalPersistentNodeTraitNames(node)) : 
					getLocalPersistentNodeTraitNames(node);
};

static setPersistentTraitNames = fn(MinSG.Node node,Array traitNames){
	if(traitNames.empty())
		node.unsetNodeAttribute(ATTR_NODE_TRAITS);
	else					
		node.setNodeAttribute(ATTR_NODE_TRAITS,traitNames.implode(","));
};


/*! The Trait is stored persistently at a MinSG.Node. Internally, the trait's name is stored
	as node attribute, so that the trait can be re-added when the node is loaded.	*/
var T = new Type(Traits.GenericTrait);

T._printableName @(override) ::= $PersistentNodeTrait;
	
static originalAllowRemoval = Traits.GenericTrait.allowRemoval;

/*! Hooks into the allowRemoval method to assure that the trait's name is removed from the node's attributes when removed.
	\see Trait.allowRemoval()	*/
T.allowRemoval @(override) ::= fn(){
	if(!this.isSet($onRemove))
		this.onRemove := new Std.MultiProcedure;
	this.onRemove += fn(node){
		var tName = this.getName();

		if(node.isInstance() && getLocalPersistentNodeTraitNames(node.getPrototype()).contains(tName) ){// trait is set in prototype
			Runtime.warn("Can't remove trait defined in prototype.");
			return $BREAK;
		}
		setPersistentTraitNames( node, getLocalPersistentNodeTraitNames(node).removeValue(tName) );
	};
	(this->originalAllowRemoval)();
};

T._constructor ::= fn(String traitName)@(super(traitName)){
	this.onInit += fn(MinSG.Node node){
		var tName = this.getName();
		if(node.isInstance() && getLocalPersistentNodeTraitNames(node.getPrototype()).contains(tName) ){// trait is set in prototype; don't store here
			return;
		}
		var localTraitNames = getLocalPersistentNodeTraitNames(node);
		if(!localTraitNames.contains(tName)){
			localTraitNames += tName;
			setPersistentTraitNames(node, localTraitNames);
		}
	};
};

/*! (static) Call to init all persistent node traits in the given subtree. 
	If a Trait is already initialized, it is skipped.*/
T.initTraitsInSubtree ::= fn(MinSG.Node root){
	var nodes = MinSG.collectNodesReferencingAttribute(root,ATTR_NODE_TRAITS);
	foreach(nodes as var node){
		foreach( getPersistentNodeTraitNames(node) as var traitName ){
			try{
				if(!Std.Traits.queryTrait(node,traitName)){
					var trait = Std.module(traitName);
					
//					outln("Adding trait ",traitName," to ",node);
					Std.Traits.assureTrait(node,trait); // assureTrait instead of addTrait as the traitName may be a deprecated alias.
				}
			}catch(e){
				PADrend.message("Could not add NodeTrait '"+traitName+"' to node '"+node+"'");
				Runtime.warn(e);
			}
		}
	}
};
T.removeInvalidTraitNames ::= fn(MinSG.Node node){
	var names = getLocalPersistentNodeTraitNames(node);
	if(!names.empty()){
		var names2 = [];
		foreach(names as var traitName){
			if( Std.Traits.queryTrait(node,traitName) )
				names2 += traitName;
		}
		setPersistentTraitNames(node,names2);
	}
};


//! (static)
T.getLocalPersistentNodeTraitNames ::= getLocalPersistentNodeTraitNames;

//! (static)
T.getPersistentNodeTraitNames ::= getPersistentNodeTraitNames;



MinSG.PersistentNodeTrait := T;
return T;

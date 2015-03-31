/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static SemanticObject = Std.module('LibMinSGExt/SemanticObject');

/*! Trait for GUI.TreeViewEntries.
	When the entry is opened, for each contained semantic object a new subentry is created.
	The sub entries are filled using the registered components 'ObjectEditor_ObjectEntry'.
	This trait is also applied to all sub entries.
	\param MinSG.Node 			the node associated with the entry

	Adds the following attributes:
	 - entryRegistry 		void if closed; { node -> sub entry } if opened
	 - node					the referenced node
	 
	\see Based on the GUI.TreeViewEntry.DynamicSubentriesTrait
*/
static t = new Std.Traits.GenericTrait('SemanticObjectEntryTrait');

t.attributes.entryRegistry := void; // void if closed; { node -> sub entry } if opened
t.attributes.node := void;

t.onInit += fn(GUI.TreeViewEntry entry,MinSG.Node node){
	entry.node = node;
	entry.entryRegistry = new Map; // object->subEntry|void
	
	//! \see GUI.TreeViewEntry.DynamicSubentriesTrait
	Std.Traits.addTrait(entry,	GUI.TreeViewEntry.DynamicSubentriesTrait, [entry] => fn(entry){
		var node = entry.node;
		var entries = [];
		
		foreach(SemanticObject.collectNextSemanticObjects(node) as var object){
			var subEntry = t.createEntry(object);
			entries += subEntry;
			entry.entryRegistry[object] = subEntry;
		}

		return entries;
		
	});
	//! \todo if object has no sub objects, disable the default open marker (but still add the trait) 
	if(SemanticObject.collectNextSemanticObjects(node).empty())
		entry.clearSubentries();
};

t.createEntry := fn(MinSG.Node node){
	var entry = gui.create({
		GUI.TYPE : GUI.TYPE_TREE_GROUP,
		GUI.OPTIONS : [{	
				GUI.TYPE : GUI.TYPE_CONTAINER,
				GUI.CONTENTS : gui.createComponents({
														GUI.TYPE : GUI.TYPE_COMPONENTS,
														GUI.PROVIDER : 'ObjectEditor_ObjectEntry',
														GUI.CONTEXT  : node
													}),
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS,1,4 ]
		}],
		GUI.FLAGS : GUI.COLLAPSED_ENTRY
	});
	Std.Traits.addTrait(entry,	t, node);
	return entry;
};


return t;

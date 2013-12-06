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
 **	[Plugin:SceneEditor/ObjectEditor]
 **
 ** Graphical tools for managing semantic objects.
 **/
declareNamespace($SceneEditor,$ObjectEditor);

//! ---|> Plugin
SceneEditor.ObjectEditor.plugin := new Plugin({
    Plugin.NAME : 'SceneEditor/ObjectEditor',
    Plugin.DESCRIPTION : 'Editor for semantic objects',
    Plugin.AUTHORS : "Claudius",
    Plugin.OWNER : "All",
    Plugin.LICENSE : "Mozilla Public License, v. 2.0",
    Plugin.REQUIRES : ['NodeEditor','PADrend'],
    Plugin.EXTENSION_POINTS : []
});

var plugin = SceneEditor.ObjectEditor.plugin;

plugin.objectTraitRegistry := new Map; // displayableName -> trait
plugin.objectTraitGUIRegistry := new Map; // traitName -> guiProvider(obj)

plugin.init @(override) := fn(){
    registerExtension('PADrend_Init',this->initGUI);
    
//    //! temp

    var t = new MinSG.PersistentNodeTrait("ObjectTraits.Fader");
    declareNamespace($ObjectTraits);
    ObjectTraits.Fader := t;
    t.onInit += fn(node){
		PADrend.message("Fade...");
		node.fadeTime := DataWrapper.createFromValue(1);
		node.fadeTime := DataWrapper.createFromValue(1);
		node.onClick := fn(evt){
			this.deactivate();
			PADrend.planTask(this.fadeTime(),this->activate);
		};		
    };
    this.registerObjectTrait(t);
    
    
    this.registerObjectTraitGUI(t,fn(node){
		return [ "Fader trait",
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "Time",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.fadeTime //! \see ObjectTraits.Fader
			}
		];
	});
    
    // ----------------
    
	return true;
};

/*! Trait for GUI.TreeViewEntries.
	When the entry is opened, for each contained semantic object a new subentry is created.
	The sub entries are filled using the registered components 'ObjectEditor_ObjectEntry'.
	This trait is also applied to all sub entries.
	\param MinSG.Node 	the node associated with the entry

	Adds the following attributes:
	 - entryRegistry 		void if closed; { node -> sub entry } if opened
	 - node					the referenced node
	 
	\see Based on the GUI.TreeViewEntry.DynamicSubentriesTrait
*/
SceneEditor.ObjectEditor.SemanticObjectEntryTrait := new Traits.GenericTrait('SceneEditor.ObjectEditor.SemanticObjectEntryTrait');
{
	var t = SceneEditor.ObjectEditor.SemanticObjectEntryTrait;
	
	t.attributes.entryRegistry := void; // void if closed; { node -> sub entry } if opened
	t.attributes.node := void;
	
	t.onInit += fn(GUI.TreeViewEntry entry,MinSG.Node node){
		entry.node = node;
		entry.entryRegistry = new Map;
		
		//! \see GUI.TreeViewEntry.DynamicSubentriesTrait
		Traits.addTrait(entry,	GUI.TreeViewEntry.DynamicSubentriesTrait, [entry] => fn(entry){
			var node = entry.node;
			var entries = [];
			
			foreach(MinSG.SemanticObjects.collectNextSemanticObjects(node) as var object){
				var subEntry = gui.create({
					GUI.TYPE : GUI.TYPE_TREE_GROUP,
					GUI.OPTIONS : [{	
							GUI.TYPE : GUI.TYPE_CONTAINER,
							GUI.CONTENTS : gui.createComponents({
																	GUI.TYPE : GUI.TYPE_COMPONENTS,
																	GUI.PROVIDER : 'ObjectEditor_ObjectEntry',
																	GUI.CONTEXT  :object,
																}),
							GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS,1,4 ]
					}],
					GUI.FLAGS : GUI.COLLAPSED_ENTRY
				});
				
				//! \see SceneEditor.ObjectEditor.SemanticObjectEntryTrait
				Traits.addTrait(subEntry, SceneEditor.ObjectEditor.SemanticObjectEntryTrait, object);
				entries += subEntry;
				entry.entryRegistry[object] = subEntry;
			}

			return entries;
			
		});
		//! \todo if object has no sub objects, disable the default open marker (but still add the trait) 
		if(MinSG.SemanticObjects.collectNextSemanticObjects(node).empty())
			entry.clearSubentries();
	};
	
}


plugin.initGUI := fn(){
	
	// ----------------------------
	// content of an object entry
	gui.registerComponentProvider('ObjectEditor_ObjectEntry.00main',fn(MinSG.Node node){
		if(node.hasParent()&& node.getParent().isInstance() )
			return [NodeEditor.getString(node)];

		return {
			GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
			GUI.LABEL : NodeEditor.getString(node),
			GUI.COLLAPSED : true,
			GUI.CONTENTS : [node] => fn(node){
				return gui.createComponents({
					GUI.TYPE : GUI.TYPE_COMPONENTS,
					GUI.PROVIDER : 'ObjectEditor_ObjectConfig',
					GUI.CONTEXT : node
				});
			},
			GUI.TOOLTIP : NodeEditor.getString(node)
		};
	});
	
	gui.registerComponentProvider('ObjectEditor_ObjectConfig.0_id',fn(MinSG.Node node){
		var id =  PADrend.getSceneManager().getNameOfRegisteredNode(node);
		return [
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "id",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 2,15.0 ],
				GUI.DATA_VALUE : id ? id : "",
				GUI.ON_DATA_CHANGED : [node] => fn(node,id){
					id = id.trim();
					if(id.empty()){
						PADrend.getSceneManager().unregisterNode(node);
					}else{
						PADrend.getSceneManager().registerNode(id,node);
					}
				}
			}
		];
	});
	gui.registerComponentProvider('ObjectEditor_ObjectConfig.5_traits',this->fn(MinSG.Node node){
		var entries = [];
		foreach( MinSG.getLocalPersistentNodeTraitNames(node) as var traitName){
			var provider = objectTraitGUIRegistry[traitName] ;
			if( provider ){
				entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
				entries += '----';
				entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
				entries.append(provider(node));
			}
		}
		return entries;
	});

	gui.registerComponentProvider('ObjectEditor_ObjectConfig.9_addTraits',this->fn(MinSG.Node node){
		return [
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			'----',
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "Add object trait",
				GUI.MENU_PROVIDER : [node] => this->fn(node){
					var enabledTraitNames =  new Set(MinSG.getLocalPersistentNodeTraitNames(node));
					
					var entries = [];
					foreach( objectTraitRegistry as var name,var trait ){
						if(enabledTraitNames.contains(trait.getName())){
							entries += name + " (enabled)";
						}else{
							entries += {
								GUI.TYPE : GUI.TYPE_BUTTON,
								GUI.LABEL : name,
								GUI.ON_CLICK : [node,trait] => fn(node,trait){
									Traits.addTrait(node,trait);
								}
							};
						}
					}
					return entries;
				}
			}
		];
	});
	
	// ------------------
	
	// content of the tab in the SceneEditor window
	gui.registerComponentProvider('SceneEditor_ToolsConfigTabs.SemanticObjects',fn(){
		var panel = gui.create({
			GUI.TYPE : GUI.TYPE_PANEL
		});
		

		var tv = gui.create({
			GUI.TYPE : GUI.TYPE_TREE,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_FILL_ABS , 10,30.0 ],
			GUI.ON_DATA_CHANGED : fn(selectedComponents){
				var nodes = [];
				if(!selectedComponents.empty()){
					foreach(selectedComponents as var c){
						c = c.getParentComponent();

						//! \see SceneEditor.ObjectEditor.SemanticObjectEntryTrait
						if(Traits.queryTrait(c,SceneEditor.ObjectEditor.SemanticObjectEntryTrait))
							nodes += c.node;
					}
				}
				NodeEditor.selectNodes(nodes);
			}
		});
		panel += tv;


		var refreshTv = [tv]=>fn(tv, scene){
			if(tv.isDestroyed())
				return $REMOVE;
			tv.destroyContents();
			if(scene){
				var rootEntry = gui.create({
					GUI.TYPE : GUI.TYPE_TREE_GROUP,
					GUI.OPTIONS : ["Scene","..."],
					GUI.FLAGS : GUI.COLLAPSED_ENTRY
				});
				//! \see SceneEditor.ObjectEditor.SemanticObjectEntryTrait
				Traits.addTrait(rootEntry,	SceneEditor.ObjectEditor.SemanticObjectEntryTrait, scene);
				tv += rootEntry;
			}
		};
		registerExtension('PADrend_OnSceneSelected',refreshTv);
		
		refreshTv(PADrend.getCurrentScene());

		
		// if an object is selected, select it in the object explorer
		registerExtension('NodeEditor_OnNodesSelected',[tv]=>fn(tv,nodes){
			if(tv.isDestroyed())
				return $REMOVE;
			tv.unmarkAll();

			if(nodes.count()!=1 || !MinSG.SemanticObjects.isSemanticObject(nodes[0]) )
				return;
			
			// collect objects upwards
			var objects = [];
			for(var object = nodes[0]; object; object = MinSG.SemanticObjects.getContainingSemanticObject(object) )
				objects += object;
			
			// recursively search object's entry
			var entry = tv.getRootEntry().getFirstSubentry(); // Scene-entry
			while(!objects.empty() && entry){
				if(entry.isCollapsed())
					entry.open();
				
//				if(!entry.entryRegistry){									//! \see SceneEditor.ObjectEditor.SemanticObjectEntryTrait
//					Runtime.warn("(internal) Error in object explorer.");
//					return;
//				}
				var nextObject = objects.popBack();
				var nextEntry = entry.entryRegistry[nextObject]; 			//! \see SceneEditor.ObjectEditor.SemanticObjectEntryTrait
				if(!nextEntry){
					entry.refreshSubentries();								//! \see GUI.TreeViewEntry.DynamicSubentriesTrait
					nextEntry = entry.entryRegistry[nextObject]; // try again
				}
				entry = nextEntry;
			}
			if(entry){
				tv.markEntry(entry);
			}
		});

		return {
			GUI.TYPE : GUI.TYPE_TAB,
			GUI.TAB_CONTENT : panel,
			GUI.LABEL : "Sem.Objects"
		};

	});
};

// --------------------------------------------

plugin.registerObjectTrait := fn(MinSG.PersistentNodeTrait trait,String name=""){
	if(name.empty())
		name = trait.getName();
	objectTraitRegistry[name] = trait;
};

plugin.registerObjectTraitGUI := fn(MinSG.PersistentNodeTrait trait, provider ){
	Traits.requireTrait(provider, Traits.CallableTrait); //! \see Traits.CallableTrait
	objectTraitGUIRegistry[trait.getName()] = provider;
};


return plugin;

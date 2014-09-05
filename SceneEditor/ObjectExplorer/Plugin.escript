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
	Plugin.REQUIRES : ['NodeEditor','PADrend','ObjectTraits'],
	Plugin.EXTENSION_POINTS : []
});

var plugin = SceneEditor.ObjectEditor.plugin;

plugin.init @(override) := fn(){
	registerExtension('PADrend_Init',this->initGUI);
	
	
	// ----------------
	
	return true;
};

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
SceneEditor.ObjectEditor.SemanticObjectEntryTrait := new Traits.GenericTrait('SceneEditor.ObjectEditor.SemanticObjectEntryTrait');
{
	var t = SceneEditor.ObjectEditor.SemanticObjectEntryTrait;
	
	t.attributes.entryRegistry := void; // void if closed; { node -> sub entry } if opened
	t.attributes.node := void;
	
	t.onInit += fn(GUI.TreeViewEntry entry,MinSG.Node node){
		entry.node = node;
		entry.entryRegistry = new Map; // object->subEntry|void
		
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
																	GUI.CONTEXT  : object
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

	static entryBG = new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
												gui._createRectShape(new Util.Color4ub(240,240,240,255),new Util.Color4ub(0,0,0,255),true));
	static objectHeading_bg = new GUI.ShapeProperty(GUI.PROPERTY_BUTTON_SHAPE,
												gui._createRectShape(new Util.Color4ub(0,128,0,255),new Util.Color4ub(0,128,0,255),true));
	
	static objectHeading_textColor = new GUI.ColorProperty(GUI.PROPERTY_TEXT_COLOR,GUI.WHITE );
	
	// ----------------------------
	// content of an object entry
	gui.registerComponentProvider('ObjectEditor_ObjectEntry.00main',fn(MinSG.Node node){
		if(node.hasParent()&& node.getParent().isInstance() )
			return [NodeEditor.getString(node)];

		var refreshCallback = fn(){ thisFn.collapsibleObjectContainer.refreshContents(); }.clone();

		var collapsibleObjectContainer = gui.create({
			GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
			GUI.LABEL : {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : " "+NodeEditor.getString(node),
				GUI.FLAGS : GUI.BACKGROUND | GUI.USE_SCISSOR,
				GUI.PROPERTIES : [objectHeading_bg,objectHeading_textColor],
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS,0,16 ],
				GUI.ON_CLICK : [node] => fn(node){ NodeEditor.selectNode(node);	},
				GUI.TEXT_ALIGNMENT : GUI.TEXT_ALIGN_LEFT | GUI.TEXT_ALIGN_MIDDLE,
				GUI.TOOLTIP : "Click to select."
			},
			GUI.COLLAPSED : true,
			GUI.CONTENTS : [node,refreshCallback] => fn(node,refreshCallback){
				return gui.createComponents({
					GUI.TYPE : GUI.TYPE_COMPONENTS,
					GUI.PROVIDER : 'ObjectEditor_ObjectConfig',
					GUI.CONTEXT_ARRAY : [node,refreshCallback]
				});
			},
			GUI.HEIGHT : 20,
			GUI.FLAGS : GUI.BORDER|GUI.BACKGROUND,
			GUI.PROPERTIES : [entryBG],		
			GUI.TOOLTIP : NodeEditor.getString(node),
			// consume l-mouse buttons before the containing tree view can change its selection (which is annoying)
			GUI.ON_MOUSE_BUTTON : fn(evt){	return (evt.pressed && evt.button == Util.UI.MOUSE_BUTTON_LEFT) ?  $BREAK : $CONTINUE; } 
		});
		refreshCallback.collapsibleObjectContainer := collapsibleObjectContainer;
		
		
		return collapsibleObjectContainer;
	});
	
	gui.registerComponentProvider('ObjectEditor_ObjectConfig.0_id',fn(MinSG.Node node,refreshCallback){
		var id =  PADrend.getSceneManager().getNameOfRegisteredNode(node);
		return [
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "id",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 2,15.0 ],
				GUI.DATA_VALUE : id ? id : "",
				GUI.ON_DATA_CHANGED : [node,refreshCallback] => fn(node,refreshCallback,id){
					id = id.trim();
					if(id.empty()){
						PADrend.getSceneManager().unregisterNode(node);
					}else{
						PADrend.getSceneManager().registerNode(id,node);
					}
					refreshCallback();
				}
			}
		];
	});
	static traitRegistry = Std.require('ObjectTraits/ObjectTraitRegistry');

	static traitTitleProperties = [
				new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,gui._createRectShape(new Util.Color4ub(200,200,200,255),new Util.Color4ub(200,200,200,255),true))
	];
	
////	static objectHeading_bg = new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
//	static objectHeading_bg = new GUI.ShapeProperty(GUI.PROPERTY_BUTTON_SHAPE,
//												gui._createRectShape(new Util.Color4ub(0,128,0,255),new Util.Color4ub(0,128,0,255),true));


	gui.registerComponentProvider('ObjectEditor_ObjectConfig.5_traits',fn(MinSG.Node node,refreshCallback){
		var entries = [];
		foreach( Std.require('LibMinSGExt/Traits/PersistentNodeTrait').getLocalPersistentNodeTraitNames(node) as var traitId){
			var info = traitRegistry.getTraitInfos()[traitId];
			var provider = traitRegistry.getGUIProvider(traitId);
			if( provider ){
				entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
				entries += '----';
				entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
				entries += {
					GUI.TYPE : GUI.TYPE_LABEL,
					GUI.LABEL : " "+(info ? info.get('displayName',traitId) : traitId),
					GUI.FLAGS : GUI.BACKGROUND | GUI.USE_SCISSOR,
					GUI.PROPERTIES : traitTitleProperties,
					GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS,40,16 ],
					GUI.TOOLTIP : info ? info['description'] : void
				};
				var trait = Std.require(traitId);
				if(trait.getRemovalAllowed()){
					entries += {
						GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
						GUI.FLAGS : GUI.FLAT_BUTTON,
						GUI.TOOLTIP : "Remove trait",
						GUI.LABEL : "-",
						GUI.WIDTH : 20,
						GUI.ON_CLICK : [node,trait,refreshCallback] => fn(node,trait,refreshCallback){
							if(Traits.queryTrait(node,trait))
								Traits.removeTrait(node,trait);
							refreshCallback();
						}
					};
				}
				entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
				entries.append(provider(node,refreshCallback));
			}
		}
		return entries;
	});
	
	gui.registerComponentProvider('ObjectEditor_ObjectConfig.9_addTraits',fn(MinSG.Node node,refreshCallback){
		return [
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			'----',
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "Add object trait",
				GUI.MENU : [node,refreshCallback] => fn(node,refreshCallback){
					var enabledTraitNames =  new Set(Std.require('LibMinSGExt/Traits/PersistentNodeTrait').getLocalPersistentNodeTraitNames(node));
					
					var entries = [];
					foreach( traitRegistry.getTraitInfos() as var moduleId,var info ){
						var displayName = info.get('displayName',moduleId);
						if(enabledTraitNames.contains(moduleId)){
							entries += displayName + " (enabled)";
						}else{
							entries += {
								GUI.TYPE : GUI.TYPE_BUTTON,
								GUI.LABEL : displayName,
								GUI.WIDTH : 200,
								GUI.ON_CLICK : [node,moduleId,refreshCallback] => fn(node,moduleId,refreshCallback){
									Traits.addTrait(node,Std.require(moduleId) );
									gui.closeAllMenus();
									refreshCallback();
								},
								GUI.TOOLTIP : info['description']
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
				if(nextObject == entry.node) // special case: skip iff the nextObject is the scene and the entry is the root entry
					continue;
				
				
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
			GUI.LABEL : "Object explorer"
		};

	});
};

// --------------------------------------------



return plugin;

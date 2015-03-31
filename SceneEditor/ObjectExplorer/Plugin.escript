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
/****
 **	[Plugin:SceneEditor/ObjectEditor]
 **
 ** Graphical tools for managing semantic objects.
 **/

static SemanticObject = Std.require('LibMinSGExt/SemanticObject');
static SemanticObjectEntryTrait = module('./SemanticObjectEntryTrait');

var plugin = new Plugin({
	Plugin.NAME : 'SceneEditor/ObjectEditor',
	Plugin.DESCRIPTION : 'Editor for semantic objects',
	Plugin.AUTHORS : "Claudius",
	Plugin.OWNER : "All",
	Plugin.LICENSE : "Mozilla Public License, v. 2.0",
	Plugin.REQUIRES : ['NodeEditor','PADrend','ObjectTraits'],
	Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) := fn(){
	module.on('PADrend/gui',this->initGUI);
	return true;
};

plugin.initGUI := fn(gui){

	static entryBG = new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
												gui._createRectShape(new Util.Color4ub(240,240,240,255),new Util.Color4ub(0,0,0,255),true));
	static objectHeading_bg = new GUI.ShapeProperty(GUI.PROPERTY_BUTTON_SHAPE,
												gui._createRectShape(new Util.Color4ub(0,128,0,255),new Util.Color4ub(0,128,0,255),true));
	
	static objectHeading_textColor = new GUI.ColorProperty(GUI.PROPERTY_TEXT_COLOR,GUI.WHITE );
	
	// ----------------------------
	// content of an object entry
	gui.register('ObjectEditor_ObjectEntry.00main',fn(MinSG.Node node){
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
	
	gui.register('ObjectEditor_ObjectConfig.0_id',fn(MinSG.Node node,refreshCallback){
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


	gui.register('ObjectEditor_ObjectConfig.5_traits',fn(MinSG.Node node,refreshCallback){
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
					GUI.TOOLTIP : info ? ("["+traitId+"]\n\n"+info['description']): "["+traitId+"]"
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
							if(Std.Traits.queryTrait(node,trait))
								Std.Traits.removeTrait(node,trait);
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
	
	gui.register('ObjectEditor_ObjectConfig.9_addTraits',fn(MinSG.Node node,refreshCallback){
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
									Std.Traits.addTrait(node,Std.require(moduleId) );
									gui.closeAllMenus();
									refreshCallback();
								},
								GUI.TOOLTIP : "["+moduleId+"]\n\n"+info['description']
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
	gui.register('SceneEditor_ToolsConfigTabs.SemanticObjects',fn(){
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

						//! \see SemanticObjectEntryTrait
						if(Std.Traits.queryTrait(c,SemanticObjectEntryTrait))
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
				tv += SemanticObjectEntryTrait.createEntry(scene);
			}
		};
		Util.registerExtension('PADrend_OnSceneSelected',refreshTv);
		
		refreshTv(PADrend.getCurrentScene());

		
		// if an object is selected, select it in the object explorer
		Util.registerExtension('NodeEditor_OnNodesSelected',[tv]=>fn(tv,nodes){
			if(tv.isDestroyed())
				return $REMOVE;
			tv.unmarkAll();

			if(nodes.count()!=1 || !SemanticObject.isSemanticObject(nodes[0]) )
				return;
			
			// collect objects upwards
			var objects = [];
			for(var object = nodes[0]; object; object = SemanticObject.getContainingSemanticObject(object) )
				objects += object;
			
			// recursively search object's entry
			var entry = tv.getRootEntry().getFirstSubentry(); // Scene-entry
			while(!objects.empty() && entry){
				if(entry.isCollapsed())
					entry.open();

				var nextObject = objects.popBack();
				if(nextObject == entry.node) // special case: skip iff the nextObject is the scene and the entry is the root entry
					continue;
				
				
				var nextEntry = entry.entryRegistry[nextObject]; 			//! \see SemanticObjectEntryTrait
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

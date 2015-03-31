/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Mouns R. Husan Almarrani
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor/ObjectPlacer]
 **/

/*

\todo

	- use commands for undo/redo
	- configure parent node
	- configure object marker
	- better placing hint?
	- support metadata


*/
static ObjectPlacerUtils = Std.module('SceneEditor/ObjectPlacer/Utils');

var plugin = new Plugin({
		Plugin.NAME : 'SceneEditor/ObjectPlacer',
		Plugin.DESCRIPTION : '...',
		Plugin.VERSION : 1.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['NodeEditor'],
		Plugin.EXTENSION_POINTS : [	]
});

static registeredLibraries;

plugin.init @(override) := fn(){
	Util.registerExtension('PADrend_Init',fn(){

		registeredLibraries = DataWrapper.createFromConfig(PADrend.configCache,'ObjectPlacer.libs2',new Map); // id -> [path,Bool recursive,Bool meshes]
		// register gui components when registeredLibraries changes.
		registeredLibraries.onDataChanged += fn( libs ){
			@(once) static oldLibs = new Map;

			// delete old libraries
			foreach(oldLibs as var id,var libDescription){
				if(!libs[id])
					gui.unregisterComponentProvider('SceneEditor_ObjectProviderEntries.lib_'+id);
			}
			// insert new libraries
			foreach(libs as var id,var libDescription){
				if(!oldLibs[id]){
					//! \see SceneEditor/ObjectPlacer
					gui.register('SceneEditor_ObjectProviderEntries.lib_'+id, [id,libDescription...] => createLibEntry);
				}
			}
			oldLibs = libs.clone();
		};
		registeredLibraries.forceRefresh();
	});
	module.on('PADrend/gui',fn(gui){
		gui.register('SceneEditor_ObjectProviderEntries.lib_00UsedFiles', fn(){
			return {
				GUI.TYPE : GUI.TYPE_TREE_GROUP,
				GUI.FLAGS : GUI.COLLAPSED_ENTRY,
				GUI.LABEL :  "Used prototypes",
				GUI.OPTIONS_PROVIDER : fn(){
					var entries = [];
					
					var sm = PADrend.getSceneManager();
					foreach(sm.getNamesOfRegisteredNodes() as var name){
						var node = sm.getRegisteredNode(name);
						var file = node.getNodeAttribute('ObjFileSource');
						if(file){
							entries += createObjectEntry(file);
						}
					}
					entries += '----'; // always add at least one entry.
					return entries;
				},
				GUI.TOOLTIP : "Contains already added object\n prototypes. Re-open to refresh\n*May take some time for large scenes.*"
			};
		});
		

		//! \see ObjectPlacer/Plugin
		gui.register('SceneEditor_AddObjectProvider.addFileLibs',[{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Add file library",
			GUI.ON_CLICK : fn(){
				var recursive =  DataWrapper.createFromConfig(PADrend.configCache,'ObjectPlacer.recursive',false); // default setting for new libraries
				var meshes =  DataWrapper.createFromConfig(PADrend.configCache,'ObjectPlacer.meshes',true); // default setting for new libraries
				gui.openDialog({
					GUI.TYPE : GUI.TYPE_FOLDER_DIALOG,
					GUI.LABEL : "Select Library Folder ",
					GUI.DIR : ".",
					GUI.ENDINGS : [".mmf",".minsg"],
					GUI.ON_ACCEPT : [recursive,meshes] => fn(recursive,meshes, folder){
						var libs = registeredLibraries().clone();
						var id;
						do{ id = Rand.equilikely(0,10000); }while(libs[id]);
						libs[id] = [folder,recursive(),meshes()];
						registeredLibraries(libs); // refresh 
						PADrend.message("Library '"+folder+"' added.");
					},
					GUI.OPTIONS : [
						{
							GUI.TYPE : GUI.TYPE_BOOL,
							GUI.LABEL : "Scan folders recursively",
							GUI.DATA_WRAPPER : recursive
						},
						{
							GUI.TYPE : GUI.TYPE_BOOL,
							GUI.LABEL : "Include meshes",
							GUI.DATA_WRAPPER : meshes,
							GUI.TOOLTIP :  "If false, only .minsg files are scanned."
						}
					]
					
				});
			}
		}]);
	});
	
	return true;
};



static createLibEntry = fn(id, path,scanRecursively,includeMeshes){
	return {
		GUI.TYPE : GUI.TYPE_TREE_GROUP,
		GUI.FLAGS : GUI.COLLAPSED_ENTRY,
		GUI.CONTEXT_MENU_PROVIDER : [{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Remove library",
			GUI.ON_CLICK : [id] => fn(id){
				registeredLibraries( registeredLibraries().clone().unset(id);  );
				gui.closeAllMenus();
			}
		}],
		GUI.LABEL :  "Files ("+path+")",
		GUI.OPTIONS_PROVIDER : [id, path,scanRecursively,includeMeshes] => fn(id, path,scanRecursively,includeMeshes){
			var enries = [];
			foreach(Util.getFilesInDir(path,includeMeshes ? ['.mmf','.minsg'] : ['.minsg'],scanRecursively) as var file){
				if(file.beginsWith("file://"))
					file = file.substr(7);
				enries += createObjectEntry(file);
			}
			return enries;
		},
		GUI.TOOLTIP : "Path: "+path+"\nScanRecursively: "+scanRecursively+"\nIncludeMeshes: "+includeMeshes
	};
};

static getNodeInfoString = fn(MinSG.Node node){
	@(once) static NodeMetaInfo = module('LibMinSGExt/NodeMetaInfo');

	var tooltip = "";
	var s = NodeMetaInfo.queryMetaInfo_Title(node);
	if(s&&!s.empty())
		tooltip += "\nTitle: " + s;
	s = NodeMetaInfo.queryMetaInfo_Author(node); 
	if(s&&!s.empty())
		tooltip += "\nAuthor: " + s;
	s = NodeMetaInfo.queryMetaInfo_CreationDate(node);
	if(s&&!s.empty())
		tooltip += "\nCreationDate: " + s;
	s = NodeMetaInfo.queryMetaInfo_License(node);
	if(s&&!s.empty())
		tooltip += "\nLicense: " + s;
	s = NodeMetaInfo.queryMetaInfo_Note(node);
	if(s&&!s.empty())
		tooltip += "\nNote: " + s;
	return tooltip;
};

static createObjectEntry = fn(String file){
	
	var prototype = getPrototypeForFile(file);
	var tooltip = "[" + file + "]";
	if(prototype)
		tooltip += getNodeInfoString(prototype);
	
	
	var entry = gui.create({
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.LABEL : "[[ "+file.substr(file.rFind('/')+1)+" ]]",
		GUI.DRAGGING_ENABLED : true,
		GUI.DRAGGING_MARKER : fn(c){	_draggingMarker_relPos.setValue(-5,-5); return "X";}, // TEMP
		GUI.DRAGGING_CONNECTOR : true,
		GUI.COLOR : prototype ? GUI.BLUE : GUI.BLACK,
		GUI.TOOLTIP : tooltip,
		GUI.CONTEXT_MENU_PROVIDER : [file] => fn(file){
			var prototype = getPrototypeForFile(file);
			if(!prototype)
				return ["File not loaded."];
			return [
				"*"+file+"*",
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Select instances",
					GUI.ON_CLICK : [prototype] => fn(prototype){
						var instances = MinSG.collectInstances(PADrend.getCurrentScene(),prototype);
						NodeEditor.selectNodes(instances);
						PADrend.message("" + instances.count() + " instances selected.");
					}
				},
				{
					GUI.TYPE : prototype.isSet($_objPlacer_isOpenedForEditing) ? GUI.TYPE_CRITICAL_BUTTON : GUI.TYPE_BUTTON,
					GUI.LABEL : "Reload object file",
					GUI.ON_CLICK : [file,prototype] => fn(file,prototype){
						var instances = MinSG.collectInstances(PADrend.getCurrentScene(),prototype);
						if(prototype.isSet($_objPlacer_isOpenedForEditing))
							PADrend.unregisterScene(prototype);
						
						var newPrototype = createPrototype(file);
						if(newPrototype){
							var newNodes = [];
							foreach(instances as var node)
								newNodes += MinSG.updatePrototype(node,newPrototype);
							NodeEditor.selectNodes(newNodes);
							PADrend.message("#" + newNodes.count() + " instances updated.");
						}
						gui.closeAllMenus();
					}
				},
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Refresh instances",
					GUI.ON_CLICK : [prototype] => fn(prototype){
						var instances = MinSG.collectInstances(PADrend.getCurrentScene(),prototype);
						var newNodes = [];
						foreach(instances as var node)
							newNodes += MinSG.updatePrototype(node,prototype);
						NodeEditor.selectNodes(newNodes);
						PADrend.message("#" + newNodes.count() + " instances refreshed.");
					}
				},
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Exchange prototype file...",
					GUI.ON_CLICK : [file,prototype] => fn(file,prototype){
						gui.openDialog({
							GUI.TYPE :		GUI.TYPE_FILE_DIALOG,
							GUI.LABEL :		"Exchange prototype file...",
							GUI.ENDINGS :	[".minsg", ".dae", ".DAE", ".mmf"],
							GUI.FILENAME : 	file,
							GUI.ON_ACCEPT : [prototype] => fn(prototype, newFile){
									
								var instances = MinSG.collectInstances(PADrend.getCurrentScene(),prototype);
								
								var newPrototype = getPrototypeForFile(newFile);
								if(newPrototype){
									PADrend.message("Re-using already loaded prototype.");
								}else{
									newPrototype = createPrototype(newFile);
								}
								if(newPrototype){
									var newNodes = [];
									foreach(instances as var node)
										newNodes += MinSG.updatePrototype(node,newPrototype);
									NodeEditor.selectNodes(newNodes);
									PADrend.message("#" + newNodes.count() + " instances updated.");
								}
								gui.closeAllMenus();
							}
						});
					}
				},
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Edit prototype",
					GUI.ON_CLICK : [prototype] => fn(prototype){
						PADrend.registerScene(prototype);
						PADrend.selectScene(prototype);
						prototype._objPlacer_isOpenedForEditing := true;
					}
				},
			
			];
		
		}
	});

	//! \see DraggableObjectCreatorTrait
	Std.Traits.addTrait(entry, ObjectPlacerUtils.DraggableObjectCreatorTrait, ObjectPlacerUtils.defaultNodeInserter, new ObjectFactory(file));

	// change color when inserted.
	if(!prototype){
		Util.registerExtension('ObjectPlacer_OnObjectInserted', [entry,file] => fn(entry, myId, newNode){
			if( entry.isDestroyed() )
				return Extension.REMOVE_EXTENSION;
			if( PADrend.getSceneManager().getNameOfRegisteredNode( newNode.getOriginalNode() )== myId ){
				entry.setColor(GUI.BLUE);
				entry.setTooltip( "["+myId+"]"+ getNodeInfoString(newNode.getOriginalNode() ) );
				return Extension.REMOVE_EXTENSION;
			}
			return Extension.CONTINUE;
		});
	}

	return entry;
};



static ObjectFactory = new Type;
{
	var T = ObjectFactory;

	//! \see ObjectPlacerUtils.ObjectFactoryTrait
	Std.Traits.addTrait(T,ObjectPlacerUtils.ObjectFactoryTrait);

	T.file @(private) := void;
	T._constructor ::= fn(_filename){
		this.file = _filename;
	};

	//! \see ObjectPlacerUtils.ObjectFactoryTrait
	T.doCreateNode @(override) ::= fn(){
		if(!getPrototypeForFile(file)){
			createPrototype(file);
		}
		return PADrend.getSceneManager().createInstance(file);
	};
}

static createPrototype = fn(file){
	showWaitingScreen();
			
	var newPrototype;
	if(file.endsWith('.mmf')){
		newPrototype = new MinSG.GeometryNode(Rendering.loadMesh(file));
	}else{
		newPrototype = PADrend.getSceneManager().loadScene(file,MinSG.SceneManagement.IMPORT_OPTION_USE_TEXTURE_REGISTRY | MinSG.SceneManagement.IMPORT_OPTION_USE_MESH_REGISTRY);
		Std.module('LibMinSGExt/SemanticObject').markAsSemanticObject(newPrototype);
	}
	if(!newPrototype){
		PADrend.message("Could not load "+file);
		return void;
	}
	newPrototype.setNodeAttribute('ObjFileSource',file);
	PADrend.getSceneManager().registerNode(file,newPrototype);
	return newPrototype;
};

static getPrototypeForFile = fn(file){
	return PADrend.getSceneManager().getRegisteredNode(file);
};



//----------------------------------------------------------------------------


return plugin;

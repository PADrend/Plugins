/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

 /*! Adds the following public members:
	- subtreeFilename  		DataWrapper containing the filename from wich the subtree may be re-loaded.
	- subtreeImportOptions	DataWrapper import options.
	- reloadSubtree()		Reload the subtree.
*/
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.attributes.reloadSubtree ::= fn(){
	var subtree = PADrend.getSceneManager().loadScene(this.subtreeFilename(),this.subtreeImportOptions());
	if(subtree){
		var e;
		foreach( MinSG.getChildNodes(this) as var c)
			MinSG.destroy(c);
		this += subtree;
		Std.module('LibMinSGExt/Traits/PersistentNodeTrait').initTraitsInSubtree(subtree);
	}
};

trait.onInit += fn(MinSG.GroupNode node){
	node.subtreeFilename := node.getNodeAttributeWrapper('subtreeFilename', "" );
	node.subtreeImportOptions := node.getNodeAttributeWrapper('subtreeImportOptions', 
														MinSG.SceneManagement.IMPORT_OPTION_REUSE_EXISTING_STATES|
														MinSG.SceneManagement.IMPORT_OPTION_USE_TEXTURE_REGISTRY|
														MinSG.SceneManagement.IMPORT_OPTION_USE_MESH_REGISTRY );
};

trait.allowRemoval();
trait.onRemove += fn(node){};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait, fn(node,refreshCallback){
		var entries = [
			{
				GUI.TYPE : GUI.TYPE_FILE,
				GUI.LABEL : "Filename",
				GUI.ENDINGS : [".minsg",".dae",".DAE"],
				GUI.DATA_WRAPPER : node.subtreeFilename,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
			}
		];
		foreach({
					"Reuse exisiting states" : MinSG.SceneManagement.IMPORT_OPTION_REUSE_EXISTING_STATES,
					"Cache textures in TextureRegistry" : MinSG.SceneManagement.IMPORT_OPTION_USE_TEXTURE_REGISTRY,
					"Cache meshes in MeshRegistry (file)" : MinSG.SceneManagement.IMPORT_OPTION_USE_MESH_REGISTRY,
					"Cache meshes in MeshRegistry (hash)" : MinSG.SceneManagement.IMPORT_OPTION_USE_MESH_REGISTRY,
					"COLLADA: Invert transparency" : MinSG.SceneManagement.IMPORT_OPTION_DAE_INVERT_TRANSPARENCY
				} as var label, var bit){
			entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
			entries += {
				GUI.TYPE			:	GUI.TYPE_BOOL,
				GUI.LABEL			:	label,
				GUI.SIZE			:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_VALUE		:	(node.subtreeImportOptions()&bit)>0,
				GUI.ON_DATA_CHANGED	:	[node.subtreeImportOptions,bit] => fn(option,bit, value){ 
					option( value ? option()|bit : option()-(option()&bit) );
				},
			};
		}
		entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		entries += {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Reload",
				GUI.ON_CLICK : [node]=>fn(node){
					showWaitingScreen();
					node.reloadSubtree();
					NodeEditor.clearNodeSelection();
				}
			};
		return entries;
	});
});

return trait;


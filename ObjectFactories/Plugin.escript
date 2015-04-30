/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014-2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var plugin = new Plugin({
		Plugin.NAME : 'MachineObjects',
		Plugin.DESCRIPTION : "Collection of basic object factories for the ObjectPlacer.",
		Plugin.VERSION : 0.2,
		Plugin.AUTHORS : "Claudius Jähn",
		Plugin.OWNER : "Claudius Jähn",
		Plugin.LICENSE : "Proprietary",
		Plugin.REQUIRES : ['ObjectTraits','SceneEditor'],
		Plugin.EXTENSION_POINTS : []
});

Traits.addTrait(plugin,Util.ReloadablePluginTrait);	//!	\see Util.ReloadablePluginTrait

static scanFactoryInfos = fn(){
	var infos = new Map; 
	foreach(Util.getFilesInDir( __DIR__+"/Factories", ".info", false ) as var f){
		try{
			var info = parseJSON( Util.loadFile( f ) );
			var moduleId = info['moduleId'];
			if(!moduleId){
				Runtime.warn("ObjectFactories: No 'moduleId' in "+f);
				continue;
			}
			if(moduleId.beginsWith('.'))
				moduleId = "ObjectFactories/Factories/"+moduleId;
			info['moduleId'] = moduleId;
			infos[ info['displayName'] ? info['displayName'] : moduleId ] = info;
		}catch(e){
			Runtime.warn( e );
		}
	}
	print_r(infos);
	return infos;
};

plugin.init @(override) :=fn() {
	Util.registerExtension('PADrend_Init',fn(){
			gui.register('SceneEditor_ObjectProviderEntries.functionalObjects', fn(){
				return {
					GUI.TYPE : GUI.TYPE_TREE_GROUP,
					GUI.FLAGS : GUI.COLLAPSED_ENTRY,
					GUI.LABEL : "Basic object factories",
					GUI.OPTIONS_PROVIDER :  fn(){
						var moduleInfos = scanFactoryInfos();
						foreach(moduleInfos as var info) // allow re-loading
							Std._unregisterModule(info['moduleId']);
						Std._unregisterModule('FunctionalObjects/InternalTools');

						
						var entries = [];
						foreach(moduleInfos as var name,var info){
							var entry = gui.create({
								GUI.TYPE : GUI.TYPE_LABEL,
								GUI.LABEL : name,
								GUI.DRAGGING_ENABLED : true,
								GUI.DRAGGING_MARKER : fn(c){	_draggingMarker_relPos.setValue(-5,-5); return "X";},
								GUI.DRAGGING_CONNECTOR : true,
								GUI.TOOLTIP : info['description']
							});
							var factory = [info['moduleId']] =>fn(id,p...){
								return Std.module(id)(p...);
							};
							var ObjectPlacerUtils = Std.module('SceneEditor/ObjectPlacer/Utils');
							//! \see ObjectPlacer.DraggableObjectCreatorTrait
							Std.Traits.addTrait(entry,ObjectPlacerUtils.DraggableObjectCreatorTrait,ObjectPlacerUtils.defaultNodeInserter,factory);

							entries += entry;
						}
						return entries;
					}
				};
			});
		}
	);
	return true;
};


// -------------------
return plugin;
// ------------------------------------------------------------------------------

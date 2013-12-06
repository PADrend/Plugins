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
 **	[Plugin:SceneEditor/NodeRepeator]
 **/

declareNamespace($SceneEditor);

//! ---|> Plugin
var plugin = new Plugin({
		Plugin.NAME : 'SceneEditor/SceneMetaInfo',
		Plugin.DESCRIPTION : 'Add meta information to scenes.',
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

//plugin.

plugin.init @(override) := fn(){
	registerExtension('PADrend_Init',fn(){
		gui.registerComponentProvider('PADrend_SceneConfigMenu.05_sceneMetaData',fn(scene){
			var entries = [];
			entries += '----';
			entries += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "Name",
				GUI.DATA_WRAPPER : SceneEditor.accessSceneMetaInfo_Name(scene)
			};
			entries += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "Author",
				GUI.DATA_WRAPPER : SceneEditor.accessSceneMetaInfo_Author(scene)
			};
			var d = getDate();
			entries += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "Creation date",
				GUI.DATA_WRAPPER : SceneEditor.accessSceneMetaInfo_CreationDate(scene),
				GUI.OPTIONS :  ["" + d["year"] + "-"+ d["mon"] + "-" + d["mday"] ]
			};
			entries += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "License",
				GUI.DATA_WRAPPER : SceneEditor.accessSceneMetaInfo_License(scene),
				GUI.OPTIONS :  ["free","internal use","RESTRICTED" ]
			};
			entries += {
				GUI.TYPE : GUI.TYPE_MULTILINE_TEXT,
				GUI.LABEL : "Note",
				GUI.DATA_WRAPPER : SceneEditor.accessSceneMetaInfo_Note(scene),
				GUI.HEIGHT : 100
			};
			return entries;
		});
	});
	
//	!!!!!!!!!!! The scene.name attribute and the scene's name meta property should not be coupled. It produces unwanted side effects.
//  !!!!!!!!!!! The scene.name attribute will eventually be removed anyway.
//	//! heuristic used for backward compatibility with "scene.name"
//	registerExtension('PADrend_OnSceneRegistered',fn(scene){
//		var nameWrapper = SceneEditor.accessSceneMetaInfo_Name(scene);
//		var name = nameWrapper();
//		if(name==""){
//			if(scene.isSet($name))
//				nameWrapper(scene.name);
//		}else{
//			scene.name := name;
//		}
//		nameWrapper.onDataChanged += [scene] => fn(scene,name){	scene.name = name;	};
//	});
	return true;
};


plugin.getDataWrapper := fn(String key,MinSG.Node scene){
	if(!scene.isSet($_metaInf))
		scene._metaInf := new Map;
	
	var _metaInf = scene._metaInf;
	if(!_metaInf[key]){
		var initialValue = scene.getNodeAttribute(key);
		if(void===initialValue)
			initialValue = "";
		var d = DataWrapper.createFromValue( initialValue );
		d.onDataChanged += [scene,key] => fn(scene,key, value){	
			if(value=="" || void===value)
				scene.unsetNodeAttribute(key);
			else
				scene.setNodeAttribute(key,value);	
		};
		_metaInf[key] = d;
	}
	return _metaInf[key];

};

//! These functions return a DataWrapper for accessing various meta informations of a given @p scene
SceneEditor.accessSceneMetaInfo_Author 			:= ["META_AUTHOR"] => plugin.getDataWrapper;
SceneEditor.accessSceneMetaInfo_CreationDate 	:= ["META_CREATION_DATE"] => plugin.getDataWrapper;
SceneEditor.accessSceneMetaInfo_License 		:= ["META_LICENSE"] => plugin.getDataWrapper;
SceneEditor.accessSceneMetaInfo_Name 			:= ["META_NAME"] => plugin.getDataWrapper;
SceneEditor.accessSceneMetaInfo_Note 			:= ["META_NOTE"] => plugin.getDataWrapper;

return plugin;

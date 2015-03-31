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
 **	[Plugin:NodeEditor/ObjectPlacer/BuiltinLib]
 **/

var plugin = new Plugin({
		Plugin.NAME : 'SceneEditor/ObjectPlacer/BuildinLib',
		Plugin.DESCRIPTION : 'Add standard nodes.',
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['NodeEditor'],
		Plugin.EXTENSION_POINTS : [	]
});

plugin.init @(override) := fn(){
	module.on('PADrend/gui',fn(gui){
		//! \see SceneEditor/ObjectPlacer
		gui.register('SceneEditor_ObjectProviderEntries.builtIn',this->fn(){
			var entries = ["BuiltIn"];
			foreach( {
						"Cube" : 				fn(){	
							var mb = new Rendering.MeshBuilder;
							mb.addBox(new Geometry.Box(0.0, 0.0, 0.0, 0.1, 0.1, 0.1));
							return new MinSG.GeometryNode( mb.buildMesh() );
						},
						"DirectionalLight" : 	fn(){	return new MinSG.LightNode( MinSG.LightNode.DIRECTIONAL );	},
						"GenericMetaNode" : 	fn(){	return new MinSG.GenericMetaNode();	},
						"ListNode" : 			fn(){	return new MinSG.ListNode();	},
						"Orthographic Camera" : fn(){	return new MinSG.CameraNodeOrtho();	},
						"Perspective Camera" : 	fn(){	return new MinSG.CameraNode();	},
						"PointLight" : 			fn(){	return new MinSG.LightNode( MinSG.LightNode.POINT );	},
						"SpotLight" : 			fn(){	return new MinSG.LightNode( MinSG.LightNode.SPOT );	},
						"Tree" : 				fn(){	return tree();	}, // amc
					} as var name,var factory){

				var entry = gui.create({
					GUI.TYPE : GUI.TYPE_LABEL,
					GUI.LABEL : name,
					GUI.DRAGGING_ENABLED : true,
					GUI.DRAGGING_MARKER : fn(c){	_draggingMarker_relPos.setValue(-5,-5); return "X";},
					GUI.DRAGGING_CONNECTOR : true,
				});
				var ObjectPlacerUtils = Std.module('SceneEditor/ObjectPlacer/Utils');
				//! \see DraggableObjectCreatorTrait
				Std.Traits.addTrait(entry,ObjectPlacerUtils.DraggableObjectCreatorTrait,ObjectPlacerUtils.defaultNodeInserter,factory);

				entries += entry;
			}
			return {
				GUI.TYPE : GUI.TYPE_TREE_GROUP,
				GUI.FLAGS : GUI.COLLAPSED_ENTRY,
				GUI.OPTIONS :  entries
			};
		});
	});
	return true;
};

//----------------------------------------------------------------------------

return plugin;

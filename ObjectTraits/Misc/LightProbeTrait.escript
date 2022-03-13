/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius J�hn <claudius@uni-paderborn.de>
 * Copyright (C) 2014 Mouns Almarrani <murrani@mail.upb.de>
 * Copyright (C) 2021 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */



/*! Add the follwong public attributes to a MinSG.Node:

	- lightProbe_update()				Method for creating/updating the env map; the created map is returned.
	- lightProbe_targetStateId			(DataWrapper,String) Registered name of a TextureState for holding the envMap
	- lightProbe_renderingLayers		(DataWrapper,Number) Rendering layers used to create the environment map.
	- lightProbe_resolution				(DataWrapper,Number) Resolution of the created environment map.
	- lightProbe_updateOnTranslation	(DataWrapper,Bool) If true, the texture is refreshed when the node is moved.

*/
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.attributes.lightProbe_update ::= fn(){
	outln("update probe");
	var id = ""+this.lightProbe_targetStateId();
	var state;
	if(!id.empty()){
		state = PADrend.getSceneManager().getRegisteredState( id );
	}

	if(!state){
		return;
	}
	state.deactivate();

	var resolution = this.lightProbe_resolution();
	var envMap =  Rendering.createHDRCubeTexture(resolution, resolution);
	{
		var rootNode = this;
		while(rootNode.hasParent()) rootNode = rootNode.getParent();
		var position = this.getWorldBB().getCenter();
		var fbo = new Rendering.FBO;
		fbo.attachDepthTexture( renderingContext,Rendering.createDepthTexture(resolution, resolution) );
		var camera = new MinSG.CameraNode;
		camera.setViewport(new Geometry.Rect(0, 0, resolution, resolution));
		camera.applyVerticalAngle(90);

		foreach([
					[ new Geometry.Vec3(-1,  0,  0), new Geometry.Vec3(0, -1, 0) ],
					[ new Geometry.Vec3( 1,  0,  0), new Geometry.Vec3(0, -1, 0) ],
					[ new Geometry.Vec3( 0, -1,  0), new Geometry.Vec3(0,  0, 1) ],
					[ new Geometry.Vec3( 0,  1,  0), new Geometry.Vec3(0,  0, -1) ],
					[ new Geometry.Vec3( 0,  0, -1), new Geometry.Vec3(0, -1, 0) ],
					[ new Geometry.Vec3( 0,  0,  1), new Geometry.Vec3(0, -1, 0) ],
				] as var layer,var dirArray){
			camera.setRelTransformation(new Geometry.SRT(position, dirArray[0], dirArray[1]));
			
			fbo.attachColorTexture( renderingContext, envMap, 0, 0, layer );
			renderingContext.pushAndSetFBO( fbo	);
			PADrend.renderScene(rootNode, camera, PADrend.getRenderingFlags(), PADrend.getBGColor(), this.lightProbe_renderingLayers());
			renderingContext.popFBO();
		}
	}

	state.setEnvironmentMap(envMap);
	state.activate();
	return envMap;
};

trait.onInit += fn(MinSG.Node node){

	node.lightProbe_targetStateId := node.getNodeAttributeWrapper('lightProbe_stateId', "" );
	node.lightProbe_renderingLayers := node.getNodeAttributeWrapper('lightProbe_rendLayers', 1 );
	node.lightProbe_resolution := node.getNodeAttributeWrapper('lightProbe_resolution', 256 );
	node.lightProbe_updateOnTranslation := node.getNodeAttributeWrapper('lightProbe_updateOnTranslation', true );
	
	node.lightProbe_updateOnTranslation.onDataChanged += [node]=>fn(node,b){
		if(b){
			var TransformationObserverTrait = module('LibMinSGExt/Traits/TransformationObserverTrait');
			Traits.assureTrait( node, TransformationObserverTrait );
			node.onNodeTransformed += fn(...){
				if( this.lightProbe_updateOnTranslation() )
					this.lightProbe_update();
			};
			return $REMOVE;
		}
	};
	node.lightProbe_updateOnTranslation.forceRefresh();

	var active = new Std.DataWrapper;
	node.lightProbe_autoUpdate := node.getNodeAttributeWrapper('lightProbe_autoUpdate', 0 );
	node.lightProbe_autoUpdate.onDataChanged += [node,active]=>fn(node,active, value){
		
		if(value && value>0){
			if(!active()){
				active(true);
				PADrend.planTask( value, [node,active] => fn(node,active){ 	if(active()){node.lightProbe_update();	return node.lightProbe_autoUpdate();	} });
			}
		}else{
			active(false);
		}
	};
	node.lightProbe_autoUpdate.forceRefresh();
	
	PADrend.planTask(1, node->node.lightProbe_update); // plan initial map creation
};

trait.allowRemoval();

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
				GUI.LABEL : "StateId",
				GUI.OPTIONS_PROVIDER : fn(){
						var availableStateNames = PADrend.getSceneManager().getNamesOfRegisteredStates();
						availableStateNames.filter( fn(stateName){	return PADrend.getSceneManager().getRegisteredState(stateName).isA(MinSG.IBLEnvironmentState);} );
						availableStateNames.sort();
						return availableStateNames;
					},
				GUI.DATA_WRAPPER : node.lightProbe_targetStateId
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
				GUI.LABEL : "Resoultion",
				GUI.DATA_WRAPPER : node.lightProbe_resolution,
				GUI.OPTIONS : [16,32,64,128,256,512,1024]
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
				GUI.LABEL : "lightProbe_autoUpdate",
				GUI.DATA_WRAPPER : node.lightProbe_autoUpdate,
				GUI.OPTIONS : [0,1,10,30],
				GUI.TOOLTIP : "If value!=0, the map is re-created each value seconds."
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
				GUI.LABEL : "Rendering layers",
				GUI.DATA_WRAPPER : node.lightProbe_renderingLayers
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "create texture",
				GUI.ON_CLICK: node -> node.lightProbe_update
			}
		];
	});
});

return trait;

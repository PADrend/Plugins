/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014 Mouns Almarrani <murrani@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */



/*! Add the follwong public attributes to a MinSG.Node:

	- envMap_update()				Method for creating/updating the env map; the created map is returned.
	- envMap_targetStateId			(DataWrapper,String) Registered name of a TextureState for holding the envMap
	- envMap_renderingLayers		(DataWrapper,Number) Rendering layers used to create the environment map.
	- envMap_resolution				(DataWrapper,Number) Resolution of the created environment map.
	- envMap_updateOnTranslation	(DataWrapper,Bool) If true, the texture is refreshed when the node is moved.

*/
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.attributes.envMap_update ::= fn(){
	var resolution = this.envMap_resolution();
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
			PADrend.renderScene(rootNode, camera, PADrend.getRenderingFlags(), PADrend.getBGColor(), this.envMap_renderingLayers());
			renderingContext.popFBO();
		}
	}
	envMap = Rendering.createSmoothedCubeMap(envMap);

	var id = ""+this.envMap_targetStateId();
	if(!id.empty()){
		var state =  PADrend.getSceneManager().getRegisteredState( id );
		if(!state){
			state = new MinSG.TextureState;
			state.setTextureUnit(4);
			PADrend.getSceneManager().registerState( id,state);
		}
		state.setTexture(envMap);
	}
	return envMap;
};

trait.onInit += fn(MinSG.Node node){

	node.envMap_targetStateId := node.getNodeAttributeWrapper('envMap_stateId', "" );
	node.envMap_renderingLayers := node.getNodeAttributeWrapper('envMap_rendLayers', 1 );
	node.envMap_resolution := node.getNodeAttributeWrapper('envMap_resolution', 256 );
	node.envMap_updateOnTranslation := node.getNodeAttributeWrapper('envMap_updateOnTranslation', true );
	
	node.envMap_updateOnTranslation.onDataChanged += [node]=>fn(node,b){
		if(b){
			var TransformationObserverTrait = module('LibMinSGExt/Traits/TransformationObserverTrait');
			Traits.assureTrait( node, TransformationObserverTrait );
			node.onNodeTransformed += fn(...){
				if( this.envMap_updateOnTranslation() )
					this.envMap_update();
			};
			return $REMOVE;
		}
	};
	node.envMap_updateOnTranslation.forceRefresh();

	var active = new Std.DataWrapper;
	node.envMap_autoUpdate := node.getNodeAttributeWrapper('envMap_autoUpdate', 0 );
	node.envMap_autoUpdate.onDataChanged += [node,active]=>fn(node,active, value){
		
		if(value && value>0){
			if(!active()){
				active(true);
				PADrend.planTask( value, [node,active] => fn(node,active){ 	if(active()){node.envMap_update();	return node.envMap_autoUpdate();	} });
			}
		}else{
			active(false);
		}
	};
	node.envMap_autoUpdate.forceRefresh();
	
	PADrend.planTask(0.1, node->node.envMap_update); // plan initial map creation
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
						availableStateNames.filter( fn(stateName){	return PADrend.getSceneManager().getRegisteredState(stateName).isA(MinSG.TextureState);} );
						availableStateNames.sort();
						return availableStateNames;
					},
				GUI.DATA_WRAPPER : node.envMap_targetStateId
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
				GUI.LABEL : "Resoultion",
				GUI.DATA_WRAPPER : node.envMap_resolution,
				GUI.OPTIONS : [16,32,64,128,256,512,1024]
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
				GUI.LABEL : "envMap_autoUpdate",
				GUI.DATA_WRAPPER : node.envMap_autoUpdate,
				GUI.OPTIONS : [0,1,10,30],
				GUI.TOOLTIP : "If value!=0, the map is re-created each value seconds."
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
				GUI.LABEL : "Rendering layers",
				GUI.DATA_WRAPPER : node.envMap_renderingLayers
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "create texture",
				GUI.ON_CLICK: node -> node.envMap_update
			}
		];
	});
});

return trait;

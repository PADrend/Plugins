/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
 
/*! Uses the node's xy-plane as a projection screen to calculate the ambient occlusion by accumulating several depth buffers.
	The calculated occlusion values are assigned to a textureState. 
	The rendered scene parts are defined by the linked nodes 'aOccRenderNode'.
	
	Adds the following attributes:
		- updateAmbientOcclusionTexture()		update the texture
		- _aOccData								collection of data wrappers for configuring the effect.
		
	\see MinSG.PersistentNodeTrait
*/
 
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');

static trait = new PersistentNodeTrait(module.getId());

static LINK_ROLE = 'aOccRenderNode';



static getShader = fn(){
/*
	- Flip X-coordinate.
	- normalize values (with custom grading)
*/
	@(once)	static shader = Rendering.Shader.createShader( 
			"	void main( void ){  gl_TexCoord[0] = gl_MultiTexCoord0;  gl_Position = ftransform(); } ",

			"#version 130\n"
			"uniform ivec2 resolution; \n"
			"uniform sampler2D t_accum; \n"
			"uniform float scale; \n"
			"uniform float intensityExponent; \n"
			"void main(){	\n"
			"	ivec2 pos_Frag = ivec2(resolution.x-gl_FragCoord.x,gl_FragCoord.y);\n"
			"	vec4 color = texelFetch(t_accum, pos_Frag, 0);\n"
			"	float sum = 1.0;	\n"
			"	for(int x=-2;x<3;++x){	\n"
			"	for(int y=-2;y<3;++y){	\n"
			"		ivec2 pos = pos_Frag+ivec2(x,y); \n"
			"		if(pos.x>=0&& pos.x<resolution.x&&pos.y>=0&&pos.y<resolution.y){	\n"
			"			color += texelFetch(t_accum, pos, 0);	\n"
			"			sum += 1.0;"
			"		}	\n"
			"	}	\n"
			"	}	\n"
			"	gl_FragColor = pow( (color/sum) *scale,vec4(intensityExponent)); \n"
			"}\n"
		);
	return shader;
};

static createTexture = fn(MinSG.Node projectionNode, Array sceneNodes,Geometry.Vec2 resolution,Number numSamples, Number renderingLayers=1, Number intensityExponent=0.0){

	var cleanup = new Std.MultiProcedure;

	// set up camera
	var dolly = new MinSG.ListNode;
	//! \see CameraFrameAdjustmentTrait
	Std.Traits.addTrait( dolly, Std.require('LibMinSGExt/Traits/CameraFrameAdjustmentTrait') );

	var bb =  projectionNode.getBoundingBox();
	//! \see CameraFrameAdjustmentTrait
	dolly.setFrame( [ 	projectionNode.localPosToWorldPos(bb.getRelPosition(1,1,1)),
						projectionNode.localPosToWorldPos(bb.getRelPosition(1,0,1)),
						projectionNode.localPosToWorldPos(bb.getRelPosition(0,0,1)) ] );

	
	var localCameraOffset = new Geometry.Vec3(  0, 0, -bb.getDiameter()*1.5 );
	var localCameraOrigin = bb.getRelPosition(0.5,0.5,0.5) + localCameraOffset ;

	var camera = new MinSG.CameraNode;
	camera.setRelOrigin( projectionNode.localPosToWorldPos(localCameraOrigin) );
	camera.setViewport( new Geometry.Rect(0,0,resolution.x(),resolution.y()) );
	camera.setNearPlane( localCameraOffset.length() );
	camera.setFarPlane( camera.getNearPlane()+2 );

	dolly += camera;

	cleanup += [dolly]=>MinSG.destroy;

	static TextureProcessor = Std.require('LibRenderingExt/TextureProcessor');
	var t_depth = Rendering.createDepthTexture(resolution.x(),resolution.y());
	var t_color = Rendering.createStdTexture(resolution.x(),resolution.y(),true);
	var t_accum = Rendering.createHDRTexture(resolution.x(),resolution.y(),true);

	var tpAccum = (new TextureProcessor);
	tpAccum.setOutputTextures( [t_accum] );
	tpAccum.setInputTextures( [t_depth] );
	tpAccum.begin();
	renderingContext.clearScreen(new Util.Color4f(0.0,0.0,0.0,1.0));
	tpAccum.end();
	

	var blending = new Rendering.BlendingParameters;
	blending.enable();
	blending.setBlendFunc(Rendering.BlendFunc.ONE,Rendering.BlendFunc.ONE);
	blending.setBlendEquation(Rendering.BlendEquation.FUNC_ADD);

	static ProgressiveBlueNoiseCreator = Std.require('LibGeometryExt/ProgressiveBlueNoiseCreator');

	foreach((new ProgressiveBlueNoiseCreator(  [bb]=>fn(bb){
					var p;
					do{
						p= new Geometry.Vec2(Rand.uniform(0,1),Rand.uniform(0,1));
					}while(p.distance([0.5,0.5])>1.0);
					return bb.getRelPosition(p.x(),p.y(),0.5);
				})).createPositions( numSamples ) as var localPos){
//		outln("#",localPos + localCameraOffset);
		camera.setRelOrigin( projectionNode.localPosToWorldPos(localPos + localCameraOffset ) );

		var tp = (new TextureProcessor)
			.setOutputDepthTexture( t_depth )
			.setOutputTextures( [t_color] )
			.begin();
		
		renderingContext.clearScreen(new Util.Color4f(0.0,0.0,0.0,1.0));
		foreach(sceneNodes as var node)
			PADrend.renderScene(node,camera,MinSG.FRUSTUM_CULLING|MinSG.USE_WORLD_MATRIX,false, renderingLayers); 
		renderingContext.finish();
		tp.end();

		renderingContext.pushAndSetBlending(blending);
		tpAccum.execute();
		renderingContext.popBlending();

		
		out(".");
	//Rendering.showDebugTexture(t_accum,0.01);
		
	}
	
	// t_accum --> t_color
	{
		getShader()
			.setUniform(renderingContext, 't_accum', Rendering.Uniform.INT, [0])
			.setUniform(renderingContext, 'scale', Rendering.Uniform.FLOAT, [1/numSamples])
			.setUniform(renderingContext, 'intensityExponent', Rendering.Uniform.FLOAT, [intensityExponent])
			.setUniform(renderingContext, 'resolution', Rendering.Uniform.VEC2I, [resolution]);
		
		(new TextureProcessor)
			.setInputTextures( [t_accum] )
			.setOutputTextures( [t_color] )
			.setShader( getShader() )
			.execute();
	}
	
	t_color.download(renderingContext); // allow saving to file
//NodeEditor.selectNode( camera );
	cleanup();
	return t_color;
};





trait.onInit += fn( MinSG.Node node){
	
	//! \see ObjectTraits/NodeLinkTrait
	Std.Traits.assureTrait(node,module('../Basic/NodeLinkTrait'));

	var data = new ExtObject({
		$resolution : node.getNodeAttributeWrapper('aOccText_res', 512 ),
		$textureStateId : node.getNodeAttributeWrapper('aOccText_stateId', "" ),
		$numSamples : node.getNodeAttributeWrapper('aOccText_samples', 20 ),
		$renderingLayers : node.getNodeAttributeWrapper('aOccText_rLayer', 1 ),
		$intensityExponent : node.getNodeAttributeWrapper('aOccText_exp', 1.0 ),
	});

	//! \see ObjectTraits/Helper/NodeLinkTrait
	node.availableLinkRoleNames += LINK_ROLE;
	
	node._aOccData := data;
	node.updateAmbientOcclusionTexture := [data]=>fn(data){
		
		var textureState;
		if(!data.textureStateId().empty()){
			var sm = PADrend.getSceneManager();
			textureState = sm.getRegisteredState(  data.textureStateId() );
			if(!textureState){
				Runtime.warn("Invalid TextureState: "+ data.textureStateId() );
				return;
			}
		}else{
			foreach( this.getStates() as var state){
				if(state.isA(MinSG.TextureState)){
					textureState = state;
					break;
				}
			}else{
				textureState = new MinSG.TextureState;
				this += textureState;
			}
		}

		var aOccTexture = createTexture( this,
						this.getLinkedNodes(LINK_ROLE),			//! \see ObjectTraits/NodeLinkTrait 
						new Geometry.Vec2(data.resolution(),data.resolution()),
						data.numSamples(), data.renderingLayers(), data.intensityExponent() );
		
		textureState.setTexture(aOccTexture);

		
	};
};

trait.allowRemoval();

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		var data = node._aOccData;
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
				GUI.DATA_WRAPPER : data.textureStateId,
				GUI.TOOLTIP : "Id of a registered TextureState that is used as target.\nIf empty, the first texture state of this node is updated or a new \ntemporary state is created."
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
				GUI.LABEL : "Resolution",
				GUI.DATA_WRAPPER : data.resolution,
				GUI.OPTIONS : [16,32,64,128,256,512,1024],
				GUI.TOOLTIP : "Resolution of the created squared texture."
			},			
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
				GUI.LABEL : "numSamples",
				GUI.DATA_WRAPPER : data.numSamples,
				GUI.OPTIONS : [10,20,50,100],
				GUI.TOOLTIP : "Number of times the scene is rendered."
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
				GUI.LABEL : "Rendering layers",
				GUI.DATA_WRAPPER : data.renderingLayers
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
				GUI.RANGE : [0,2.0],
				GUI.RANGE_STEP_SIZE : 0.02,
				GUI.LABEL : "intensityExponent",
				GUI.DATA_WRAPPER : data.intensityExponent
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "update",
				GUI.ON_CLICK: node -> node.updateAmbientOcclusionTexture
			}
		
		];
	});
});

return trait;

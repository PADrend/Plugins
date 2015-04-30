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

return fn() {	
	var tools = module('../InternalTools');

	var node = new MinSG.GeometryNode;

	module('LibMinSGExt/SemanticObject').markAsSemanticObject(node);
	tools.registerNodeWithUniqueId(node,"AOccPlate");
	
	//! \see DynamicRectTrait
	Std.Traits.assureTrait( node, module('ObjectTraits/Geometry/DynamicRectTrait') );
	node.rectDimX(10);
	node.rectDimY(10);
	node.rotateLocal_deg(-90,1,0,0);

	var material = new MinSG.MaterialState;
	material.setAmbient(  new Util.Color4f(2,2,2,1) );
	material.setDiffuse(  new Util.Color4f(0.0,0.0,0.0,1) );
	material.setSpecular( new Util.Color4f(0.0,0.0,0.0,1) );
	node+=material;

	var blendingState = new MinSG.BlendingState;
	blendingState.setBlendEquation(Rendering.BlendEquation.FUNC_REVERSE_SUBTRACT);
	blendingState.setBlendFuncSrc(Rendering.BlendFunc.ONE_MINUS_SRC_COLOR);
	blendingState.setBlendFuncDst(Rendering.BlendFunc.SRC_COLOR);
	node += blendingState;

	//! \see AmbientOcclusionTextureGenerator
	Std.Traits.assureTrait( node, module('ObjectTraits/Misc/AmbientOcclusionTextureGeneratorTrait') );
	
	// add link after node has been properly added to the scene.
	PADrend.planTask(0,[node]=>fn(node){
		node.addLinkedNodes( 'aOccRenderNode', "/" );
		node.updateAmbientOcclusionTexture(); //! \see AmbientOcclusionTextureGenerator
	});
	
	
//	
//	
//
//	var shaderState = new MinSG.ShaderState;
//	var shaderStateId = tools.registerStateWithUniqueId(shaderState,"S:EnvMapShading");
//
//	shaderState.getStateAttributeWrapper(MinSG.ShaderState.STATE_ATTR_SHADER_NAME)('universal3_complexMaterialsEnv.shader');
//	shaderState.recreateShader( PADrend.getSceneManager() );
//	node+=shaderState;
//	
//	
//	var envMapState = new MinSG.TextureState;
//	envMapState.setTextureUnit(4);
//	var stateId = tools.registerStateWithUniqueId(envMapState,"T:EnvMap");
//	node += envMapState;
//	
//	
//	//! \see ObjectTraits/EnvironmentTextureTrait
//	Std.Traits.addTrait( node, Std.module('ObjectTraits/EnvironmentTextureTrait'));
//	node.envMap_resolution( 32 );
//	node.envMap_targetStateId( stateId );
//	node.envMap_updateOnTranslation( true );
//
//		
	
	return node;
};


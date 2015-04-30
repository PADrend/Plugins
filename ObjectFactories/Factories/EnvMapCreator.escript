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

return fn() {	
	var tools = module('../InternalTools');

	var node = new MinSG.GeometryNode;

	module('LibMinSGExt/SemanticObject').markAsSemanticObject(node);
	tools.registerNodeWithUniqueId(node,"EnvMapCreator");
	
	node.setMesh(  Rendering.MeshBuilder.createSphere(64, 64) );
	node.setRenderingLayers(2);
		

	var shaderState = new MinSG.ShaderState;
	var shaderStateId = tools.registerStateWithUniqueId(shaderState,"S:EnvMapShading");

	shaderState.getStateAttributeWrapper(MinSG.ShaderState.STATE_ATTR_SHADER_NAME)('universal3_complexMaterialsEnv.shader');
	shaderState.recreateShader( PADrend.getSceneManager() );
	node+=shaderState;
	
	var material = new MinSG.MaterialState;
	material.setAmbient(  new Util.Color4f(0.2,0.2,0.2,1) );
	material.setDiffuse(  new Util.Color4f(0.2,0.2,0.2,1) );
	material.setSpecular( new Util.Color4f(1.0,1.0,1.0,1) );
	node+=material;
	
	var envMapState = new MinSG.TextureState;
	envMapState.setTextureUnit(4);
	var stateId = tools.registerStateWithUniqueId(envMapState,"T:EnvMap");
	node += envMapState;
	
	
	//! \see ObjectTraits/EnvironmentTextureTrait
	Std.Traits.addTrait( node, Std.module('ObjectTraits/EnvironmentTextureTrait'));
	node.envMap_resolution( 32 );
	node.envMap_targetStateId( stateId );
	node.envMap_updateOnTranslation( true );

		
	
	return node;
};


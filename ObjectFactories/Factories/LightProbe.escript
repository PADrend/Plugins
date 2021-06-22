/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2021 Sascha Brandt <sascha@brandt.graphics>
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
	tools.registerNodeWithUniqueId(node,"LightProbe");
	
	var vd = new Rendering.VertexDescription;
	vd.appendPosition3D();
	vd.appendNormalFloat();
	vd.appendColorRGBAByte();
	vd.appendTexCoord();
	node.setMesh(  Rendering.createSphere(vd, new Geometry.Sphere, 64, 64) );
	node.setRenderingLayers(2);
		
	var material = new MinSG.PbrMaterialState;
	material.setSearchPaths(PADrend.getSceneManager().getFileLocator());
	material.setRoughnessFactor(0.0);
	material.setMetallicFactor(1.0);
	node+=material;
	
	var envState;
	foreach(PADrend.getCurrentScene().getStates() as var state) {
		if(state ---|> MinSG.IBLEnvironmentState) {
			envState = state;
			break;
		}
	}
	if(!envState) {
		envState = new MinSG.IBLEnvironmentState;
		envState.setDrawEnvironment(false);
		PADrend.getCurrentScene() += envState;
		PADrend.getSceneManager().registerState("Env:IBLEnvironment", envState);
	}

	//! \see ObjectTraits/LightProbeTrait
	Std.Traits.addTrait( node, Std.module('ObjectTraits/LightProbeTrait'));
	node.lightProbe_resolution( 512 );
	node.lightProbe_targetStateId( "Env:IBLEnvironment" );
	node.lightProbe_updateOnTranslation( true );
	
	return node;
};


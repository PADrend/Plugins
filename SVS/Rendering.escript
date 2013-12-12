/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
declareNamespace($SVS);

//!	[static]
SVS.getSphereNode := fn(Geometry.Sphere sphere) {
	var sphereMesh = Rendering.MeshBuilder.createSphere(64, 64);
	var sphereNode = new MinSG.GeometryNode(sphereMesh);
	sphereNode.setWorldPosition(sphere.getCenter());
	sphereNode.setScale(sphere.getRadius());
	
	var shaderState = new MinSG.ShaderState();
	var path = "resources/Shader/universal2/";
	var vs = [path+"universal.vs",path+"sgHelpers.sfn"];
	var fs = [path+"universal.fs",path+"sgHelpers.sfn"];
	foreach(["shading_phong","color_standard","texture","shadow_disabled","effect_normalToAlpha"] as var f){
		vs+=path+f+".sfn";
		fs+=path+f+".sfn";
	}
	MinSG.initShaderState(shaderState, vs, [], fs, Rendering.Shader.USE_UNIFORMS);
	sphereNode.addState(shaderState);
	
	var materialState = new MinSG.MaterialState;
	materialState.setAmbient(new Util.Color4f(0.0, 1.0, 0.0, 1.0));
	materialState.setDiffuse(new Util.Color4f(0.0, 1.0, 0.0, 1.0));
	materialState.setSpecular(new Util.Color4f(1.0, 1.0, 1.0, 1.0));
	materialState.setShininess(32.0);
	sphereNode.addState(materialState);
	
	var blendingState = new MinSG.BlendingState;
	var blendingParams = blendingState.getParameters();
	blendingParams.setBlendFuncSrcRGB(Rendering.BlendFunc.SRC_ALPHA);
	blendingParams.setBlendFuncDstRGB(Rendering.BlendFunc.ONE_MINUS_SRC_ALPHA);
	blendingParams.setBlendFuncSrcAlpha(Rendering.BlendFunc.ONE);
	blendingParams.setBlendFuncDstAlpha(Rendering.BlendFunc.ONE);
	blendingState.setBlendDepthMask(false);
	blendingState.setParameters(blendingParams);
	sphereNode.addState(blendingState);
	
	var cullFaceState = new MinSG.CullFaceState;
	cullFaceState.setCullingEnabled(false);
	sphereNode.addState(cullFaceState);
	
	sphereNode.addState(new MinSG.LightingState(PADrend.getDefaultLight()));
	
	return sphereNode;
};

//!	[static]
SVS.getCrossNode := fn() {
	var crossMesh = Rendering.loadMesh(__DIR__ + "/resources/Meshes/Cross.ply");
	var crossNode = new MinSG.GeometryNode(crossMesh);
	
	var shaderState = new MinSG.ShaderState();
	var path = "resources/Shader/universal2/";
	var vs = [path+"universal.vs",path+"sgHelpers.sfn"];
	var fs = [path+"universal.fs",path+"sgHelpers.sfn"];
	foreach(["shading_phong","color_standard","texture_disabled","shadow_disabled","effect_disabled"] as var f){
		vs+=path+f+".sfn";
		fs+=path+f+".sfn";
	}
	MinSG.initShaderState(shaderState, vs, [], fs, Rendering.Shader.USE_UNIFORMS);
	crossNode.addState(shaderState);
	
	crossNode.addState(new MinSG.LightingState(PADrend.getDefaultLight()));
	
	return crossNode;
};

//!	[static]
SVS.setUpRendering := fn(plugin) {
	var worldSphere = MinSG.SVS.transformSphere(plugin.sphere, plugin.node.getWorldMatrix());
	
	// Calculate the distance in a way that the bounding sphere fits into the viewing frustum.
	var radius = worldSphere.getRadius();
	var angles = PADrend.getActiveCamera().getAngles();
	var distances = [
		// X direction of bounding box will be horizontal
		radius / -angles[0].degToRad().tan(), // left
		radius / angles[1].degToRad().tan(), // right
		// Y direction of bounding box will be vertical
		radius / -angles[2].degToRad().tan(), // bottom
		radius / angles[3].degToRad().tan() // top
	];
	
	var viewDir = new Geometry.Vec3(0, 0, 1);
	var targetSRT = new Geometry.SRT(
		worldSphere.getCenter() + viewDir * (distances.max() + radius), // position
		viewDir, // direction
		new Geometry.Vec3(0, 1, 0) // up
	);
	PADrend.Navigation.flyTo(targetSRT, 1.0);
	
	var sphereNode = SVS.getSphereNode(worldSphere);
	plugin.sphereTextureState = new MinSG.TextureState();
	sphereNode.addState(plugin.sphereTextureState);
	
	var crossNode = SVS.getCrossNode();
	crossNode.setScale(0.05 * radius);
	
	var sampleMaterialState = new MinSG.MaterialState();
	sampleMaterialState.setAmbient(new Util.Color4f(0.3, 0.0, 0.0, 1.0));
	sampleMaterialState.setDiffuse(new Util.Color4f(0.7, 0.0, 0.0, 1.0));
	sampleMaterialState.setSpecular(new Util.Color4f(1.0, 1.0, 1.0, 1.0));
	sampleMaterialState.setShininess(128.0);
	
	var selectedSampleMaterialState = new MinSG.MaterialState();
	selectedSampleMaterialState.setAmbient(new Util.Color4f(0.3, 0.3, 0.0, 1.0));
	selectedSampleMaterialState.setDiffuse(new Util.Color4f(0.7, 0.7, 0.0, 1.0));
	selectedSampleMaterialState.setSpecular(new Util.Color4f(1.0, 1.0, 1.0, 1.0));
	selectedSampleMaterialState.setShininess(128.0);
	
	registerExtension('PADrend_AfterRendering', (fn(dummy, MinSG.Node sphereNode, Geometry.Sphere sphere, Array samples, MinSG.Node cross, MinSG.MaterialState normalMat, MinSG.MaterialState selectedMat) {
												var center = sphere.getCenter();
												var radius = sphere.getRadius();
												foreach(samples as var sample) {
													cross.setWorldPosition(center + sample.getPosition() * radius);
													if(sample.selected) {
														selectedMat.enableState(GLOBALS.frameContext);
													} else {
														normalMat.enableState(GLOBALS.frameContext);
													}
													cross.display(GLOBALS.frameContext);
													if(sample.selected) {
														selectedMat.disableState(GLOBALS.frameContext);
													} else {
														normalMat.disableState(GLOBALS.frameContext);
													}
												}
												
												sphereNode.display(GLOBALS.frameContext);
												
												return Extension.CONTINUE;
											}).bindLastParams(sphereNode, worldSphere, plugin.samples, crossNode, sampleMaterialState, selectedSampleMaterialState));
};

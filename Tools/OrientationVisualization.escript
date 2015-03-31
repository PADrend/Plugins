/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var plugin = new Plugin({
			Plugin.NAME			:	"OrientationVisualization",
			Plugin.VERSION		:	"1.0",
			Plugin.DESCRIPTION	:	"Visualize the camera's orientation",
			Plugin.AUTHORS		:	"Benjamin Eikel",
			Plugin.OWNER		:	"Benjamin Eikel",
			Plugin.LICENSE		:	"Mozilla Public License, v. 2.0",
			Plugin.REQUIRES		:	['AutoMeshCreation', 'PADrend']
});

static getArrowMeshPosX = fn() {
	if(!thisFn.isSet($mesh)) {
		var extruder = new MeshCreation.Extruder;
		extruder.closeExtrusion = true;
		extruder.addProfileVertex(0.0,	0.1,	0.0);
		extruder.addProfileVertex(0.8,	0.1,	0.0);
		extruder.addProfileVertex(1.0,	0.0,	0.0);

		for(var i = 0; i < 360; i += 20) {
			var r = new Geometry.SRT;
			r.rotateLocal_deg(i, new Geometry.Vec3(1, 0, 0));
			extruder.addControlSRT(r);
		}
		thisFn.mesh := extruder.buildMesh();
	}
	return thisFn.mesh;
};
static getArrowMeshNegX = fn() {
	if(!thisFn.isSet($mesh)) {
		var extruder = new MeshCreation.Extruder;
		extruder.closeExtrusion = true;
		extruder.addProfileVertex(-0.8,	0.0,	0.0);
		extruder.addProfileVertex(-1.0,	0.1,	0.0);
		extruder.addProfileVertex(0.0,	0.1,	0.0);

		for(var i = 0; i < 360; i += 20) {
			var r = new Geometry.SRT;
			r.rotateLocal_deg(i, new Geometry.Vec3(1, 0, 0));
			extruder.addControlSRT(r);
		}
		thisFn.mesh := extruder.buildMesh();
	}
	return thisFn.mesh;
};

static getArrowPosX = fn() {
	if(!thisFn.isSet($node)) {
		var arrowMesh = getArrowMeshPosX();
		thisFn.node := new MinSG.GeometryNode(arrowMesh);

		var materialState = new MinSG.MaterialState;
		materialState.setAmbient(new Util.Color4f(1.0, 0.0, 0.0, 1.0));
		materialState.setDiffuse(new Util.Color4f(1.0, 0.0, 0.0, 1.0));
		materialState.setSpecular(new Util.Color4f(1.0, 1.0, 1.0, 1.0));
		materialState.setShininess(32.0);
		thisFn.node.addState(materialState);
	}
	return thisFn.node;
};
static getArrowNegX = fn() {
	if(!thisFn.isSet($node)) {
		var arrowMesh = getArrowMeshNegX();
		thisFn.node := new MinSG.GeometryNode(arrowMesh);

		var materialState = new MinSG.MaterialState;
		materialState.setAmbient(new Util.Color4f(0.5, 0.0, 0.0, 1.0));
		materialState.setDiffuse(new Util.Color4f(0.5, 0.0, 0.0, 1.0));
		materialState.setSpecular(new Util.Color4f(1.0, 1.0, 1.0, 1.0));
		materialState.setShininess(32.0);
		thisFn.node.addState(materialState);
	}
	return thisFn.node;
};
static getArrowPosY = fn() {
	if(!thisFn.isSet($node)) {
		var arrowMesh = getArrowMeshPosX().clone();
		var rotation = new Geometry.Matrix4x4;
		rotation.rotate_deg(90, 0, 0, 1);
		Rendering.transformMesh(arrowMesh, rotation); 
		thisFn.node := new MinSG.GeometryNode(arrowMesh);

		var materialState = new MinSG.MaterialState;
		materialState.setAmbient(new Util.Color4f(0.0, 1.0, 0.0, 1.0));
		materialState.setDiffuse(new Util.Color4f(0.0, 1.0, 0.0, 1.0));
		materialState.setSpecular(new Util.Color4f(1.0, 1.0, 1.0, 1.0));
		materialState.setShininess(32.0);
		thisFn.node.addState(materialState);
	}
	return thisFn.node;
};
static getArrowNegY = fn() {
	if(!thisFn.isSet($node)) {
		var arrowMesh = getArrowMeshNegX().clone();
		var rotation = new Geometry.Matrix4x4;
		rotation.rotate_deg(90, 0, 0, 1);
		Rendering.transformMesh(arrowMesh, rotation); 
		thisFn.node := new MinSG.GeometryNode(arrowMesh);

		var materialState = new MinSG.MaterialState;
		materialState.setAmbient(new Util.Color4f(0.0, 0.5, 0.0, 1.0));
		materialState.setDiffuse(new Util.Color4f(0.0, 0.5, 0.0, 1.0));
		materialState.setSpecular(new Util.Color4f(1.0, 1.0, 1.0, 1.0));
		materialState.setShininess(32.0);
		thisFn.node.addState(materialState);
	}
	return thisFn.node;
};
static getArrowPosZ = fn() {
	if(!thisFn.isSet($node)) {
		var arrowMesh = getArrowMeshPosX().clone();
		var rotation = new Geometry.Matrix4x4;
		rotation.rotate_deg(-90, 0, 1, 0);
		Rendering.transformMesh(arrowMesh, rotation); 
		thisFn.node := new MinSG.GeometryNode(arrowMesh);

		var materialState = new MinSG.MaterialState;
		materialState.setAmbient(new Util.Color4f(0.0, 0.0, 1.0, 1.0));
		materialState.setDiffuse(new Util.Color4f(0.0, 0.0, 1.0, 1.0));
		materialState.setSpecular(new Util.Color4f(1.0, 1.0, 1.0, 1.0));
		materialState.setShininess(32.0);
		thisFn.node.addState(materialState);
	}
	return thisFn.node;
};
static getArrowNegZ = fn() {
	if(!thisFn.isSet($node)) {
		var arrowMesh = getArrowMeshNegX().clone();
		var rotation = new Geometry.Matrix4x4;
		rotation.rotate_deg(-90, 0, 1, 0);
		Rendering.transformMesh(arrowMesh, rotation); 
		thisFn.node := new MinSG.GeometryNode(arrowMesh);

		var materialState = new MinSG.MaterialState;
		materialState.setAmbient(new Util.Color4f(0.0, 0.0, 0.5, 1.0));
		materialState.setDiffuse(new Util.Color4f(0.0, 0.0, 0.5, 1.0));
		materialState.setSpecular(new Util.Color4f(1.0, 1.0, 1.0, 1.0));
		materialState.setShininess(32.0);
		thisFn.node.addState(materialState);
	}
	return thisFn.node;
};
static getArrowsScene = fn() {
	if(!thisFn.isSet($node)) {
		thisFn.node := new MinSG.ListNode;
		thisFn.node.addChild(getArrowPosX());
		thisFn.node.addChild(getArrowNegX());
		thisFn.node.addChild(getArrowPosY());
		thisFn.node.addChild(getArrowNegY());
		thisFn.node.addChild(getArrowPosZ());
		thisFn.node.addChild(getArrowNegZ());
	}
	return thisFn.node;
};

static showWindow = fn() {
	var resolution = 192;

	var window = gui.create({
		GUI.TYPE 			:	GUI.TYPE_WINDOW,
		GUI.LABEL			:	"Camera Orientation",
		GUI.SIZE			:	[resolution, resolution],
		GUI.POSITION		:	[renderingContext.getWindowWidth() - resolution, 0],
		GUI.FLAGS 			:	GUI.ONE_TIME_WINDOW | GUI.HIDDEN_WINDOW
	});
	var icon = gui.create({
		GUI.TYPE	:	GUI.TYPE_ICON,
		GUI.ICON	:	gui.createIcon(gui.createImage(1, 1), new Geometry.Rect(0, 0, 1, 1)),
		GUI.SIZE	:	[GUI.WIDTH_FILL_ABS, 10, 0]
	});
	window += icon;

	registerExtension('PADrend_AfterRendering', [icon, resolution] => fn(icon, resolution, ...) {
		var arrowsScenes = getArrowsScene();
		var arrowsSRT = new Geometry.SRT;
		arrowsSRT.setRotation(PADrend.getDolly().getRelTransformationSRT().getRotation().getInverse());
		arrowsScenes.setRelTransformation(arrowsSRT);

		var fbo = new Rendering.FBO;
		var colorTexture = Rendering.createStdTexture(resolution, resolution, true);
		var depthTexture = Rendering.createDepthTexture(resolution, resolution);
		renderingContext.pushAndSetFBO(fbo);
		fbo.attachColorTexture(renderingContext, colorTexture);
		fbo.attachDepthTexture(renderingContext, depthTexture);

		var camera = new MinSG.CameraNodeOrtho;
		camera.setWorldOrigin(new Geometry.Vec3(0, 0, 2));
		camera.setClippingPlanes(-1, 1, -1, 1);
		camera.setNearFar(1, 3);
		camera.setViewport(new Geometry.Rect(0, 0, resolution, resolution));

		frameContext.pushAndSetCamera(camera);

		renderingContext.clearScreen(PADrend.getBGColor());

		PADrend.getDefaultLight().switchOn(frameContext);
		frameContext.displayNode(arrowsScenes);
		PADrend.getDefaultLight().switchOff(frameContext);

		frameContext.popCamera();

		renderingContext.popFBO();

		colorTexture.download(renderingContext);
		var bitmap = Rendering.createBitmapFromTexture(renderingContext, colorTexture);
		icon.setImageData(new GUI.ImageData(bitmap));
		icon.setImageRect(new Geometry.Rect(0, 0, colorTexture.getWidth(), colorTexture.getHeight()));
		// Keep aspect ratio.
		icon.setHeight(icon.getWidth() * colorTexture.getHeight() / colorTexture.getWidth());
	});
};

plugin.init  @(override) := fn() {
	module.on('PADrend/gui',this->fn(gui) {
		gui.register('Tools_ToolsMenu.orientationVisualization', {
			GUI.TYPE 		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Orientation Visualization",
			GUI.ON_CLICK	:	showWindow
		});
	});
	return true;
};

return plugin;

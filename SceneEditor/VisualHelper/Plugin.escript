/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Mouns R. Husan Almarrani
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
declareNamespace($SceneEditor);

var plugin = new Plugin({
	Plugin.NAME				:	'SceneEditor/VisualHelper',
	Plugin.DESCRIPTION		:	'Visualize helper objects',
	Plugin.AUTHORS			:	"Benjamin Eikel",
	Plugin.OWNER			:	"All",
	Plugin.LICENSE			:	"Mozilla Public License, v. 2.0",
	Plugin.REQUIRES			:	['NodeEditor','PADrend'],
	Plugin.EXTENSION_POINTS	:	[]
});

plugin.coordSystemEnabled := DataWrapper.createFromValue(false);
plugin.gridEnabled := DataWrapper.createFromValue(false);

//! Register functions at extension points.
plugin.init @(override) := fn() {
	registerExtension('PADrend_Init', this -> createMenuEntries);
	registerExtension('PADrend_AfterRendering', this -> drawHelperObjects);
	return true;
};

//! Create and register menu entries.
plugin.createMenuEntries := fn() {
	gui.register('SceneEditor_ConfigMenu.drawCoordSystem', {
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.LABEL			:	"Draw coordinate system",
		GUI.TOOLTIP			:	"If checked, draw a world coordinate system.",
		GUI.DATA_WRAPPER	:	this.coordSystemEnabled
	});
	gui.register('SceneEditor_ConfigMenu.drawGrid', {
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.LABEL			:	"Draw grid",
		GUI.TOOLTIP			:	"If checked, draw a grid in the x-z plane.",
		GUI.DATA_WRAPPER	:	this.gridEnabled
	});
};

//! Draw the helper objects that are enabled.
plugin.drawHelperObjects := fn(camera) {
	if(this.coordSystemEnabled()) {
		var scale = [
			1.0,
			PADrend.getRootNode().getWorldBB().getMaxX(),
			PADrend.getRootNode().getWorldBB().getMaxY(),
			PADrend.getRootNode().getWorldBB().getMaxZ()
		].max() / 10.0;
		var scaleMatrix = new Geometry.Matrix4x4;
		scaleMatrix.scale(scale, scale, scale);
		renderingContext.pushAndSetLighting(false);
		renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );
		renderingContext.multMatrix_modelToCamera(scaleMatrix);
		Rendering.drawCoordSys(renderingContext, 10.0);
		renderingContext.popMatrix_modelToCamera();
		renderingContext.popLighting();
	}
	if(this.gridEnabled()) {
		var color = new Util.Color4f(0.0, 0.0, 0.0, 1.0);
		var bgColor = new Util.Color4f(PADrend.getBGColor());
		if(bgColor.r() + bgColor.g() + bgColor.b() < 1.5) {
			color = new Util.Color4f(1.0, 1.0, 1.0, 1.0);
		}
		renderingContext.pushAndSetLighting(false);
		renderingContext.pushAndSetColorMaterial(color);
		Rendering.drawGrid(renderingContext, 100.0);
		renderingContext.popMaterial();
		renderingContext.popLighting();
	}
};

return plugin;

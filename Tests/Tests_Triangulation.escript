/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2015 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var plugin = new Plugin({
	Plugin.NAME				:	'Tests/Tests_Triangulation',
	Plugin.DESCRIPTION		:	'Tests for MinSG.Triangulation',
	Plugin.VERSION			:	0.1,
	Plugin.AUTHORS			:	"Benjamin Eikel",
	Plugin.OWNER			:	"All",
	Plugin.REQUIRES			:	['Tests'],
	Plugin.EXTENSION_POINTS	:	[]
});

plugin.init @(override) := fn() {
	if (queryPlugin('PADrend/GUI')) {
		registerExtension('PADrend_Init', this->fn(){
			gui.registerComponentProvider('Tests_TestsMenu.triangulation',{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Triangulation Tests",
				GUI.ON_CLICK : this->execute
			});
		});
	}

	return true;
};

plugin.execute := fn() {
	var scene = new MinSG.ListNode();
	{
		var triangulation = new MinSG.Triangulation.Delaunay2d();
		for(var i = 0; i < 1000; ++i) {
			triangulation.addPoint(new Geometry.Vec2(Rand.uniform(-5, 5), Rand.uniform(-5, 5)), i.toString());
		}
		var nodeTriangles = triangulation.createMinSGNodes();
		nodeTriangles.rotateRel_deg(90.0, [1.0, 0.0, 0.0]);
		scene.addChild(nodeTriangles);
		{
			var nodeLines = nodeTriangles.clone();
			nodeLines.moveRel(0.0, 0.001, 0.0);
			nodeLines.removeStates();
			var state = new MinSG.PolygonModeState();
			state.setParameters(state.getParameters().setMode(Rendering.PolygonModeParameters.LINE));
			nodeLines.addState(state);
			nodeLines.addState((new MinSG.MaterialState())
									.setAmbient(new Util.Color4f(0.0, 0.0, 0.0, 1.0))
									.setDiffuse(new Util.Color4f(0.0, 0.0, 0.0, 1.0))
									.setSpecular(new Util.Color4f(0.0, 0.0, 0.0, 1.0)));
			scene.addChild(nodeLines);
		}
		{
			var nodePoints = nodeTriangles.clone();
			nodePoints.moveRel(0.0, 0.002, 0.0);
			nodePoints.removeStates();
			var state = new MinSG.PolygonModeState();
			state.setParameters(state.getParameters().setMode(Rendering.PolygonModeParameters.POINT));
			nodePoints.addState(state);
			nodePoints.addState((new MinSG.MaterialState())
									.setAmbient(new Util.Color4f(1.0, 0.0, 0.0, 1.0))
									.setDiffuse(new Util.Color4f(1.0, 0.0, 0.0, 1.0))
									.setSpecular(new Util.Color4f(0.0, 0.0, 0.0, 1.0)));
			scene.addChild(nodePoints);
		}
	}
	{
		var triangulation = new MinSG.Triangulation.Delaunay3d();
		for(var i = 0; i < 1000; ++i) {
			triangulation.addPoint(
				(new Geometry.Vec3(Rand.uniform(-5, 5), Rand.uniform(-5, 5), Rand.uniform(-5, 5))).normalize(),
				i.toString()
			);
		}
		var node = triangulation.createMinSGNodes(false);
		scene.addChild(node);
	}
	PADrend.registerScene(scene);
	PADrend.selectScene(scene);
};

return plugin;

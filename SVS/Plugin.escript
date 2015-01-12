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

var plugin = new Plugin({
			Plugin.NAME			:	"SVS",
			Plugin.VERSION		:	"1.0",
			Plugin.DESCRIPTION	:	"Spherical Visibility Sampling (SVS)\nSee http://dx.doi.org/10.1111/cgf.12150",
			Plugin.AUTHORS		:	"Benjamin Eikel",
			Plugin.OWNER		:	"Benjamin Eikel",
			Plugin.LICENSE		:	"Mozilla Public License, v. 2.0",
			Plugin.REQUIRES		:	['Evaluator', 'LibRenderingExt', 'NodeEditor', 'Tools', 'PADrend', 'PADrend/GUI', 'PADrend/Serialization']
});

plugin.init @(override) := fn() {
	if(!MinSG.isSet($SVS)) {
		Runtime.warn("Plug-in initialization failed: MinSG lacks the SVS extension.");
		return false;
	}
	{
		if(systemConfig.getValue('SVS.presetsEnabled', true)) {
			registerExtension('Tools_SpeedDial_QueryFolders', fn(Array paths) { paths += __DIR__ + "/presets/"; });
		}
		registerExtension('PADrend_Init', this -> fn() {
			loadOnce(__DIR__ + "/EvaluationOutput.escript");
			loadOnce(__DIR__ + "/Preprocessing.escript");
			loadOnce(__DIR__ + "/PreprocessingWindow.escript");
			loadOnce(__DIR__ + "/ProjectionEvaluation.escript");
			loadOnce(__DIR__ + "/VisibleSetEvaluation.escript");
			gui.registerComponentProvider('PADrend_PluginsMenu.sphericalSampling', {
				GUI.TYPE		:	GUI.TYPE_MENU,
				GUI.LABEL		:	"SVS",
				GUI.MENU		:	'SVS',
				GUI.MENU_WIDTH	:	150
			});
			gui.registerComponentProvider('SVS.PreprocessingWindow', {
				GUI.TYPE 		:	GUI.TYPE_BUTTON,
				GUI.LABEL		:	"Preprocessing Window",
				GUI.ON_CLICK	:	SVS.setUpPreprocessingWindow
			});
			gui.registerComponentProvider('SVS.ProjectionEvaluation', {
				GUI.TYPE 		:	GUI.TYPE_BUTTON,
				GUI.LABEL		:	"Projection Evaluation",
				GUI.ON_CLICK	:	SVS.setUpProjectionEvaluationWindow
			});
			gui.registerComponentProvider('SVS.SingleVisibilitySphere', {
				GUI.TYPE 		:	GUI.TYPE_BUTTON,
				GUI.LABEL		:	"Single Visibility Sphere",
				GUI.ON_CLICK	:	this -> this.setUp
			});
			gui.registerComponentProvider('SVS.VisibleSetEvaluation', {
				GUI.TYPE 		:	GUI.TYPE_BUTTON,
				GUI.LABEL		:	"Visible Set Evaluation",
				GUI.ON_CLICK	:	SVS.setUpVisibleSetEvaluationWindow
			});
		});
		loadOnce(__DIR__ + "/States.escript");
		SVS.registerStates();
		loadOnce(__DIR__ + "/RenderingStatsEvaluator.escript");
		loadOnce(__DIR__ + "/VisibleSetEvaluator.escript");
		registerExtension(	'Evaluator_QueryEvaluators',
							fn(evaluatorList) {
								evaluatorList += new SVS.RenderingStatsEvaluator;
								evaluatorList += new SVS.VisibleSetEvaluator;
							});
	}
	SVS.setUp := this -> this.setUp;
	return true;
};

//! The MinSG.Node that was selected when the plugin was initialized.
plugin.node := void;

//! The Geometry.Sphere that is generated around the selected node.
plugin.sphere := void;

//! The array holding the spherical sample points.
plugin.samples := void;

//! The MinSG.TextureState that is used to visualize data on the sphere.
plugin.sphereTextureState := void;

//!	[static]
plugin.setUp := fn() {
	loadOnce(__DIR__ + "/Camera.escript");
	loadOnce(__DIR__ + "/Rendering.escript");
	loadOnce(__DIR__ + "/SampleCreationGUI.escript");
	loadOnce(__DIR__ + "/VisibilitySphereEvaluation.escript");
	loadOnce(__DIR__ + "/SphericalSamplePointEvaluation.escript");

	this.node = NodeEditor.getSelectedNode();
	var nodeBB = this.node.getBB();
	this.sphere = new Geometry.Sphere(nodeBB.getCenter(), nodeBB.getBoundingSphereRadius());

	this.samples = [];
	SVS.setUpCameraWindow(this);
	SVS.setUpSampleCreationGUI(this);
	SVS.setUpRendering(this);
	SVS.setUpVisibilitySphereEvaluation(this);
	SVS.setUpSphericalSamplePointEvaluation(this);
};

return plugin;

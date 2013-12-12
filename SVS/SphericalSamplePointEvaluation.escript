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

loadOnce(__DIR__ + "/Camera.escript");

//!	[static]
SVS.setUpSphericalSamplePointEvaluation := fn(plugin) {
	var window = gui.createWindow(300, 150, "SVS Sample Point Evaluation", GUI.ONE_TIME_WINDOW);
	window.setPosition(0, 360);
	
	var windowPanel = gui.create({
		GUI.TYPE				:	GUI.TYPE_PANEL,
		GUI.SIZE				:	GUI.SIZE_MAXIMIZE
	});
	window += windowPanel;
	
	var resultLabel = gui.create({
		GUI.TYPE				:	GUI.TYPE_LABEL,
		GUI.LABEL				:	"",
		GUI.TOOLTIP				:	"Result of the last measurement of an evaluator.",
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	});
	
	var data = new ExtObject({
		$results			:	[],
		$highlightedNodes	:	[]
	});
	
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Evaluate",
		GUI.TOOLTIP				:	"Use the evaluator from the 'Evaluator' plugin to generate a result for the selected sample.",
		GUI.ON_CLICK			:	(fn(Geometry.Sphere sphere, Array samples, MinSG.Node node, GUI.Label label, data) {
										var evaluator = EvaluatorManager.getSelectedEvaluator();
										if(!evaluator) {
											Runtime.exception("Invalid evaluator.");
										}
										
										var resolution = 4096;
										
										var fbo = new Rendering.FBO();
										var color = Rendering.createStdTexture(resolution, resolution, true);
										var depth = Rendering.createDepthTexture(resolution, resolution);
										renderingContext.pushAndSetFBO(fbo);
										fbo.attachColorTexture(renderingContext, color);
										fbo.attachDepthTexture(renderingContext, depth);
										
										var camera = MinSG.SVS.createSamplingCamera(sphere, node.getWorldMatrix(), resolution);
										SVS.configureCameraUsingSamples(camera, sphere, node.getWorldMatrix(), samples);
										
										frameContext.pushAndSetCamera(camera);
										
										evaluator.beginMeasure();
										evaluator.measure(frameContext, node, camera.getViewport());
										evaluator.endMeasure(frameContext);
										
										frameContext.popCamera();
										
										renderingContext.popFBO();
										
										data.results = evaluator.getResults();
										var resultsString = evaluator.toString() + ":\n";
										foreach(data.results as var key, var result) {
											resultsString += "[" + key + "]:" + result + "\n";
										}
										label.setText(resultsString);
									}).bindLastParams(plugin.sphere, plugin.samples, plugin.node, resultLabel, data),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Highlight",
		GUI.TOOLTIP				:	"If the current result contains VisibilityVectors, highlight the nodes that are visibile.",
		GUI.ON_CLICK			:	(fn(data) {
										foreach(data.results as var result) {
											if(MinSG.isSet($VisibilityVector) && result ---|> MinSG.VisibilityVector) {
												var nodes = result.getNodes();
												foreach(nodes as var node) {
													var state = new MinSG.ShaderUniformState();
													state.setUniform(new Rendering.Uniform("color", Rendering.Uniform.VEC4F, [[0, 0, 1, 0.5]]));
													node.addState(state);
												}
												data.highlightedNodes.append(nodes);
											}
										}
									}).bindLastParams(data),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Remove Highlight",
		GUI.TOOLTIP				:	"If there are currently highlighted nodes, remove the highlighting.",
		GUI.ON_CLICK			:	(fn(data) {
										foreach(data.highlightedNodes as var node) {
											var states = node.getStates();
											foreach(states as var state) {
												if(state ---|> MinSG.ShaderUniformState && state.hasUniform("color")) {
													node.removeState(state);
												}
											}
										}
										data.highlightedNodes.clear();
									}).bindLastParams(data),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += resultLabel;
};

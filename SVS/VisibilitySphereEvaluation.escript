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

loadOnce(__DIR__ + "/SampleCreation.escript");
loadOnce(__DIR__ + "/VisibilitySphere.escript");

//!	[static]
SVS.compareVisibilitySpheres := fn(MinSG.SVS.VisibilitySphere visibilitySphere, MinSG.SVS.VisibilitySphere referenceVisibilitySphere, interpolationMethod) {
	var diffSamples = [];
	foreach(referenceVisibilitySphere.getSamples() as var refSample) {
		var value = visibilitySphere.queryValue(refSample.getPosition(), interpolationMethod);
		var referenceValue = refSample.getValue();
		var diffValue = void;
		if(value ---|> MinSG.VisibilityVector) {
			diffValue = referenceValue.makeDifference(value);
		} else {
			diffValue = referenceValue - value;
		}
		var samplePoint = new MinSG.SVS.SamplePoint(refSample.getPosition());
		samplePoint.setValue(diffValue);
		samplePoint.description = refSample.description;
		diffSamples += samplePoint;
	}
	return new MinSG.SVS.VisibilitySphere(
		visibilitySphere.getSphere().clone(), 
		diffSamples
	);
};

//!	[static]
SVS.saveVisibilitySphereValues := fn(MinSG.SVS.VisibilitySphere visibilitySphere, String fileName) {
	var values = "PositionX\tPositionY\tPositionZ\tValue\n";
	foreach(visibilitySphere.getSamples() as var sample) {
		var value = sample.getValue();
		
		if(value ---|> MinSG.VisibilityVector) {
			value = value.getVisibleNodeCount();
		}
		
		values +=	""
					+ sample.getPosition().getX() + "\t"
					+ sample.getPosition().getY() + "\t"
					+ sample.getPosition().getZ() + "\t"
					+ value + "\n";
	}
	
	Util.saveFile(fileName, values);
};

//!	[static]
SVS.outputVisibilitySphereComparison := fn(MinSG.SVS.VisibilitySphere visibilitySphere, 
													   MinSG.SVS.VisibilitySphere referenceVisibilitySphere,
													   String fileName) {
	var output = "Interpolation\t";
	output += "EVSCardinality\tEVSBenefits\tEVSCosts\t";
	output += "PVSCardinality\tPVSBenefits\tPVSCosts\t";
	output += "OverestimationCardinality\tOverestimationBenefits\tOverestimationCosts\t";
	output += "UnderestimationCardinality\tUnderestimationBenefits\tUnderestimationCosts\n";
	foreach(referenceVisibilitySphere.getSamples() as var refSample) {
		var exactVisibleSet = refSample.getValue();
		foreach({	"Nearest"	: MinSG.SVS.INTERPOLATION_NEAREST, 
					"Max3"	 	: MinSG.SVS.INTERPOLATION_MAX3, 
					"Weighted3"	: MinSG.SVS.INTERPOLATION_WEIGHTED3} as var interpolationString, var interpolationMethod) {
			var potentiallyVisibleSet = visibilitySphere.queryValue(refSample.getPosition(), interpolationMethod);
			var overestimation = potentiallyVisibleSet.makeDifference(exactVisibleSet);
			var underestimation = exactVisibleSet.makeDifference(potentiallyVisibleSet);

			output +=	interpolationString + "\t" +
						SVS.getVisibleSetStrings(exactVisibleSet) + "\t" +
						SVS.getVisibleSetStrings(potentiallyVisibleSet) + "\t" +
						SVS.getVisibleSetStrings(overestimation) + "\t" +
						SVS.getVisibleSetStrings(underestimation) + "\n";
		}
	}

	Util.saveFile(fileName, output);
};

//!	[static]
SVS.setUpVisibilitySphereEvaluation := fn(plugin) {
	var window = gui.createWindow(350, 350, "Visibility Sphere Evaluation", GUI.ONE_TIME_WINDOW);
	window.setPosition(GLOBALS.renderingContext.getWindowWidth() - 350, 280);
	
	var windowPanel = gui.create({
		GUI.TYPE				:	GUI.TYPE_PANEL,
		GUI.SIZE				:	GUI.SIZE_MAXIMIZE
	});
	window += windowPanel;
	
	var config = new ExtObject ({
		$visibilitySphere				:	void,
		$referenceVisibilitySphere	:	void,
		$differenceVisibilitySphere	:	void,
		$interpolationMethod		:	MinSG.SVS.INTERPOLATION_NEAREST
	});
	var refreshGroup = new GUI.RefreshGroup();
	
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_TEXT,
		GUI.LABEL				:	"Current",
		GUI.TOOLTIP				:	"Current visibility sphere",
		GUI.DATA_PROVIDER		:	[config]=>fn(ExtObject config) {
										return config.visibilitySphere.toString();
									},
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
		GUI.FLAGS				:	GUI.LOCKED
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_TEXT,
		GUI.LABEL				:	"Reference",
		GUI.TOOLTIP				:	"Reference visibility sphere",
		GUI.DATA_PROVIDER		:	[config]=>fn(ExtObject config) {
										return config.referenceVisibilitySphere.toString();
									},
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
		GUI.FLAGS				:	GUI.LOCKED
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_TEXT,
		GUI.LABEL				:	"Difference",
		GUI.TOOLTIP				:	"Difference visibility sphere",
		GUI.DATA_PROVIDER		:	[config]=>fn(ExtObject config) {
										return config.differenceVisibilitySphere.toString();
									},
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
		GUI.FLAGS				:	GUI.LOCKED
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE			:	GUI.TYPE_SELECT,
		GUI.LABEL			:	"Interpolation",
		GUI.TOOLTIP			:	"The interpolation method that is used to generate results for queries between spherical sample points.",
		GUI.OPTIONS			:	[
									[MinSG.SVS.INTERPOLATION_NEAREST, "Nearest"],
									[MinSG.SVS.INTERPOLATION_MAX3, "Max3"],
									[MinSG.SVS.INTERPOLATION_MAXALL, "MaxAll"],
									[MinSG.SVS.INTERPOLATION_WEIGHTED3, "Weighted3"]
								],
		GUI.DATA_OBJECT		:	config,
		GUI.DATA_ATTRIBUTE	:	$interpolationMethod,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	var resolution = new Std.DataWrapper(4096);
	windowPanel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.LABEL			:	"Resolution",
		GUI.RANGE			:	[6, 13],
		GUI.RANGE_STEPS		:	7,
		GUI.RANGE_FN_BASE	:	2,
		GUI.TOOLTIP			:	"Horizontal and vertical resolution in pixels that will be used for rendering during the evaluation.",
		GUI.DATA_WRAPPER	:	resolution,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"New",
		GUI.TOOLTIP				:	"Create a new visibility sphere with the current set of spherical sampling points.",
		GUI.ON_CLICK			:	(fn(Geometry.Sphere sphere, Array samples, ExtObject config, GUI.RefreshGroup refreshGroup) {
										config.visibilitySphere = new MinSG.SVS.VisibilitySphere(sphere.clone(), samples.clone());
										config.visibilitySphere.description = "VisibilitySphere";
										refreshGroup.refresh();
									}).bindLastParams(plugin.sphere, plugin.samples, config, refreshGroup),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Evaluate",
		GUI.TOOLTIP				:	"Evaluate all sample positions on the sphere.",
		GUI.ON_CLICK			:	(fn(config, MinSG.Node node, DataWrapper resolution) {
										if(!config.visibilitySphere) {
											Runtime.warn("Cannot evaluate visibility sphere. Current visibility sphere not available.");
											return;
										}
										var evaluator = Std.module('Evaluator/EvaluatorManager').getSelectedEvaluator();
										if(!evaluator) {
											Runtime.exception("Invalid evaluator.");
										}
										GLOBALS.showWaitingScreen();
										
										var fbo = new Rendering.FBO();
										var color = Rendering.createStdTexture(resolution(), resolution(), true);
										var depth = Rendering.createDepthTexture(resolution(), resolution());
										renderingContext.pushAndSetFBO(fbo);
										fbo.attachColorTexture(renderingContext, color);
										fbo.attachDepthTexture(renderingContext, depth);
										
										var camera = MinSG.SVS.createSamplingCamera(config.visibilitySphere.getSphere(), node.getWorldTransformationMatrix(), resolution());
										frameContext.pushCamera();
										config.visibilitySphere.evaluateAllSamples(frameContext, evaluator, camera, node);
										frameContext.popCamera();
										
										renderingContext.popFBO();
									}).bindLastParams(config, plugin.node, resolution),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Add Color",
		GUI.TOOLTIP				:	"Add a texture to the rendered sphere.",
		GUI.ON_CLICK			:	(fn(config, MinSG.TextureState textureState) {
										var visibilitySphere = void;
										if(config.differenceVisibilitySphere) {
											visibilitySphere = config.differenceVisibilitySphere;
											out("Using difference visibility sphere.\n");
										} else if(config.visibilitySphere) {
											visibilitySphere = config.visibilitySphere;
											out("Using current visibility sphere.\n");
										} else if(config.referenceVisibilitySphere) {
											visibilitySphere = config.referenceVisibilitySphere;
											out("Using reference visibility sphere.\n");
										}
										if(!visibilitySphere) {
											Runtime.warn("Cannot add color to visibility sphere. No visibility sphere available.");
											return;
										}
										if(!visibilitySphere.getSamples() || visibilitySphere.getSamples().empty()) {
											Runtime.warn("Cannot add color to visibility sphere. No spherical sample points available.");
											return;
										}
										if(!visibilitySphere.getSamples().front().getValue()) {
											Runtime.warn("Cannot add color to visibility sphere. No values stored in spherical sample points.");
											return;
										}
										
										GLOBALS.showWaitingScreen();
										
										textureState.setTexture(MinSG.SVS.createColorTexture(512, 256, visibilitySphere, config.interpolationMethod));
										textureState.activate();
									}).bindLastParams(config, plugin.sphereTextureState),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Remove Color",
		GUI.TOOLTIP				:	"Remove the texture from the rendered sphere.",
		GUI.ON_CLICK			:	(fn(MinSG.TextureState textureState) {
										textureState.deactivate();
									}).bindLastParams(plugin.sphereTextureState),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Save Color",
		GUI.TOOLTIP				:	"Save the texture to a file.",
		GUI.ON_CLICK			:	(fn(MinSG.TextureState textureState) {
										GUI._openFileDialog("Save Texture", ".", [".png"],
											(fn(fileName, Rendering.Texture texture) {
												Rendering.saveTexture(GLOBALS.renderingContext, texture, fileName);
											}).bindLastParams(textureState.getTexture())
										);
									}).bindLastParams(plugin.sphereTextureState),
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.5, 0]
	};
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Load Color",
		GUI.TOOLTIP				:	"Load the texture from a file.",
		GUI.ON_CLICK			:	(fn(MinSG.TextureState textureState) {
										GUI._openFileDialog("Load Texture", ".", [".png"],
											(fn(fileName, MinSG.TextureState textureState) {
												textureState.setTexture(Rendering.createTextureFromFile(fileName, false, true));
												textureState.activate();
											}).bindLastParams(textureState)
										);
									}).bindLastParams(plugin.sphereTextureState),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Save",
		GUI.TOOLTIP				:	"Save the current visibility sphere to a file.",
		GUI.ON_CLICK			:	[config]=>fn(ExtObject config) {
										if(!config.visibilitySphere) {
											Runtime.warn("Cannot save visibility sphere. Current visibility sphere not available.");
											return;
										}
										GUI._openFileDialog("Save Visibility Sphere", ".", [".visibilitysphere"],
											(fn(fileName, ExtObject config) {
												Util.saveFile(fileName, PADrend.serialize(config.visibilitySphere));
											}).bindLastParams(config)
										);

									},
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.5, 0]
	};
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Load",
		GUI.TOOLTIP				:	"Load the current visibility sphere from a file.",
		GUI.ON_CLICK			:	(fn(ExtObject config, GUI.RefreshGroup refreshGroup) {
										GUI._openFileDialog("Load Visibility Sphere", ".", [".visibilitysphere"],
											(fn(fileName, ExtObject config, GUI.RefreshGroup refreshGroup) {
												config.visibilitySphere = PADrend.deserialize(Util.loadFile(fileName));
												refreshGroup.refresh();
											}).bindLastParams(config, refreshGroup)
										);
									}).bindLastParams(config, refreshGroup),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Load Reference",
		GUI.TOOLTIP				:	"Load the reference visibility sphere from a file.",
		GUI.ON_CLICK			:	(fn(ExtObject config, GUI.RefreshGroup refreshGroup) {
										GUI._openFileDialog("Load Visibility Sphere", ".", [".visibilitysphere"],
											(fn(fileName, ExtObject config, GUI.RefreshGroup refreshGroup) {
												config.referenceVisibilitySphere = PADrend.deserialize(Util.loadFile(fileName));
												refreshGroup.refresh();
											}).bindLastParams(config, refreshGroup)
										);
									}).bindLastParams(config, refreshGroup),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Compare",
		GUI.TOOLTIP				:	"Compare the current visibility sphere to the reference visibility sphere,\nand store the result in the difference visibility sphere.",
		GUI.ON_CLICK			:	(fn(ExtObject config, GUI.RefreshGroup refreshGroup) {
										if(!config.visibilitySphere) {
											Runtime.warn("Cannot compare visibility spheres. Current visibility sphere not available.");
											return;
										}
										if(!config.referenceVisibilitySphere) {
											Runtime.warn("Cannot compare visibility spheres. Reference visibility sphere not available.");
											return;
										}
										config.differenceVisibilitySphere = SVS.compareVisibilitySpheres(config.visibilitySphere, 
																												   config.referenceVisibilitySphere, 
																												   config.interpolationMethod);
										refreshGroup.refresh();
									}).bindLastParams(config, refreshGroup),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Save Values",
		GUI.TOOLTIP				:	"Save the values of a visibility sphere to a file.",
		GUI.ON_CLICK			:	(fn(config) {
										var visibilitySphere = void;
										if(config.differenceVisibilitySphere) {
											visibilitySphere = config.differenceVisibilitySphere;
											out("Using difference visibility sphere.\n");
										} else if(config.visibilitySphere) {
											visibilitySphere = config.visibilitySphere;
											out("Using current visibility sphere.\n");
										} else if(config.referenceVisibilitySphere) {
											visibilitySphere = config.referenceVisibilitySphere;
											out("Using reference visibility sphere.\n");
										}
										if(!visibilitySphere) {
											Runtime.warn("Cannot save values of a visibility sphere. No visibility sphere available.");
											return;
										}
										if(!visibilitySphere.getSamples() || visibilitySphere.getSamples().empty()) {
											Runtime.warn("Cannot save values of a visibility sphere. No spherical sample points available.");
											return;
										}
										if(!visibilitySphere.getSamples().front().getValue()) {
											Runtime.warn("Cannot save values of a visibility sphere. No values stored in spherical sample points.");
											return;
										}
										GUI._openFileDialog("Save Visibility Sphere Values", ".", [".tsv"],
											(fn(fileName, MinSG.SVS.VisibilitySphere visibilitySphere) {
												SVS.saveVisibilitySphereValues(visibilitySphere, fileName);
											}).bindLastParams(visibilitySphere)
										);										
									}).bindLastParams(config),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Evaluation Run",
		GUI.TOOLTIP				:	"Start an evaluation run comparing different sample distributions to the reference visibility sphere.",
		GUI.ON_CLICK			:	(fn(ExtObject config, plugin, GUI.RefreshGroup refreshGroup, DataWrapper resolution) {
										if(!config.referenceVisibilitySphere) {
											Runtime.warn("Cannot start evaluation run. Reference visibility sphere not available.");
											return;
										}
										
										GLOBALS.showWaitingScreen();
										
										var runs = [
											["Tetrahedron", [Rendering.createTetrahedron(), "Tetrahedron"]=>SVS.createSamplesFromMesh],
											["Octahedron", [Rendering.createOctahedron(), "Octahedron"]=>SVS.createSamplesFromMesh],
											["Cube", [Rendering.createCube(), "Cube"]=>SVS.createSamplesFromMesh],
											["Icosahedron", [Rendering.createIcosahedron(), "Icosahedron"]=>SVS.createSamplesFromMesh],
											["Dodecahedron", [Rendering.createDodecahedron(), "Dodecahedron"]=>SVS.createSamplesFromMesh],
										
											["TetrahedronSphere1", [Rendering.createEdgeSubdivisionSphere(Rendering.createTetrahedron(), 1), "TetrahedronSphere1"]=>SVS.createSamplesFromMesh],
											["TetrahedronSphere2", [Rendering.createEdgeSubdivisionSphere(Rendering.createTetrahedron(), 2), "TetrahedronSphere2"]=>SVS.createSamplesFromMesh],
											["TetrahedronSphere3", [Rendering.createEdgeSubdivisionSphere(Rendering.createTetrahedron(), 3), "TetrahedronSphere3"]=>SVS.createSamplesFromMesh],
											["TetrahedronSphere4", [Rendering.createEdgeSubdivisionSphere(Rendering.createTetrahedron(), 4), "TetrahedronSphere4"]=>SVS.createSamplesFromMesh],
											["TetrahedronSphere5", [Rendering.createEdgeSubdivisionSphere(Rendering.createTetrahedron(), 5), "TetrahedronSphere5"]=>SVS.createSamplesFromMesh],
											["OctahedronSphere1", [Rendering.createEdgeSubdivisionSphere(Rendering.createOctahedron(), 1), "OctahedronSphere1"]=>SVS.createSamplesFromMesh],
											["OctahedronSphere2", [Rendering.createEdgeSubdivisionSphere(Rendering.createOctahedron(), 2), "OctahedronSphere2"]=>SVS.createSamplesFromMesh],
											["OctahedronSphere3", [Rendering.createEdgeSubdivisionSphere(Rendering.createOctahedron(), 3), "OctahedronSphere3"]=>SVS.createSamplesFromMesh],
											["OctahedronSphere4", [Rendering.createEdgeSubdivisionSphere(Rendering.createOctahedron(), 4), "OctahedronSphere4"]=>SVS.createSamplesFromMesh],
											["OctahedronSphere5", [Rendering.createEdgeSubdivisionSphere(Rendering.createOctahedron(), 5), "OctahedronSphere5"]=>SVS.createSamplesFromMesh],
											["IcosahedronSphere1", [Rendering.createEdgeSubdivisionSphere(Rendering.createIcosahedron(), 1), "IcosahedronSphere1"]=>SVS.createSamplesFromMesh],
											["IcosahedronSphere2", [Rendering.createEdgeSubdivisionSphere(Rendering.createIcosahedron(), 2), "IcosahedronSphere2"]=>SVS.createSamplesFromMesh],
											["IcosahedronSphere3", [Rendering.createEdgeSubdivisionSphere(Rendering.createIcosahedron(), 3), "IcosahedronSphere3"]=>SVS.createSamplesFromMesh],
											["IcosahedronSphere4", [Rendering.createEdgeSubdivisionSphere(Rendering.createIcosahedron(), 4), "IcosahedronSphere4"]=>SVS.createSamplesFromMesh],
											["IcosahedronSphere5", [Rendering.createEdgeSubdivisionSphere(Rendering.createIcosahedron(), 5), "IcosahedronSphere5"]=>SVS.createSamplesFromMesh]
										];
										
										var outputDir = "data/SVS/";

										var evaluator = Std.module('Evaluator/EvaluatorManager').getSelectedEvaluator();
										if(!evaluator) {
											Runtime.exception("Invalid evaluator.");
										}

										var fbo = new Rendering.FBO();
										var color = Rendering.createStdTexture(resolution(), resolution(), true);
										var depth = Rendering.createDepthTexture(resolution(), resolution());
										renderingContext.pushAndSetFBO(fbo);
										fbo.attachColorTexture(renderingContext, color);
										fbo.attachDepthTexture(renderingContext, depth);

										var camera = MinSG.SVS.createSamplingCamera(config.referenceVisibilitySphere.getSphere(), plugin.node.getWorldTransformationMatrix(), resolution());
										frameContext.pushCamera();

										foreach(runs as var run) {
											out("Evaluating \"" + run[0] + "\" ... ");
											
											var samples = run[1]();
											var visibilitySphere = new MinSG.SVS.VisibilitySphere(plugin.sphere.clone(), samples);
											visibilitySphere.evaluateAllSamples(frameContext, evaluator, camera, plugin.node);
											//Util.saveFile(outputDir + run[0] + ".visibilitysphere", PADrend.serialize(visibilitySphere));
											//SVS.saveVisibilitySphereValues(visibilitySphere, outputDir + run[0] + ".tsv");
											//Rendering.saveTexture(GLOBALS.renderingContext, MinSG.SVS.createColorTexture(512, 256, visibilitySphere, config.interpolationMethod), outputDir + run[0] + ".png");
											
											//var differenceVisibilitySphere = SVS.compareVisibilitySpheres(visibilitySphere, config.referenceVisibilitySphere, config.interpolationMethod);
											//Util.saveFile(outputDir + run[0] + "Diff.visibilitysphere", PADrend.serialize(differenceVisibilitySphere));
											//SVS.saveVisibilitySphereValues(differenceVisibilitySphere, outputDir + run[0] + "Diff.tsv");
											//Rendering.saveTexture(GLOBALS.renderingContext, MinSG.SVS.createColorTexture(512, 256, differenceVisibilitySphere, config.interpolationMethod), outputDir + run[0] + "Diff.png");
											
											SVS.outputVisibilitySphereComparison(visibilitySphere, config.referenceVisibilitySphere, outputDir + run[0] + ".tsv");
											out("done.\n");
										}

										frameContext.popCamera();

										renderingContext.popFBO();

										refreshGroup.refresh();
									}).bindLastParams(config, plugin, refreshGroup, resolution),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Triangulation",
		GUI.TOOLTIP				:	"Build a 3D Delaunay triangulation of the sample points.",
		GUI.ON_CLICK			:	(fn(config, Geometry.Matrix4x4 worldMatrix) {
										var visibilitySphere = void;
										if(config.differenceVisibilitySphere) {
											visibilitySphere = config.differenceVisibilitySphere;
											out("Using difference visibility sphere.\n");
										} else if(config.visibilitySphere) {
											visibilitySphere = config.visibilitySphere;
											out("Using current visibility sphere.\n");
										} else if(config.referenceVisibilitySphere) {
											visibilitySphere = config.referenceVisibilitySphere;
											out("Using reference visibility sphere.\n");
										}
										if(!visibilitySphere) {
											Runtime.warn("Cannot build triangulation. No visibility sphere available.");
											return;
										}
										if(!visibilitySphere.getSamples() || visibilitySphere.getSamples().empty()) {
											Runtime.warn("Cannot build triangulation. No spherical sample points available.");
											return;
										}
										
										GLOBALS.showWaitingScreen();
										
										var worldSphere = MinSG.SVS.transformSphere(visibilitySphere.getSphere(), worldMatrix);
										
										var listNode = visibilitySphere.getTriangulationMinSGNodes();
										listNode.setWorldOrigin(worldSphere.getCenter());
										listNode.setRelScaling(worldSphere.getRadius());
										
										// Dye triangulation blue
										var materialState = new MinSG.MaterialState;
										materialState.setAmbient(new Util.Color4f(0.0, 0.0, 1.0, 1.0));
										materialState.setDiffuse(new Util.Color4f(0.0, 0.0, 1.0, 1.0));
										materialState.setSpecular(new Util.Color4f(1.0, 1.0, 1.0, 1.0));
										materialState.setShininess(32.0);
										listNode.addState(materialState);
										
										PADrend.getCurrentScene().addChild(listNode);
									}).bindLastParams(config, plugin.node.getWorldTransformationMatrix()),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
};

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
loadOnce(__DIR__ + "/SamplingSphere.escript");

//!	[static]
SVS.compareSamplingSpheres := fn(MinSG.SphericalSampling.SamplingSphere samplingSphere, MinSG.SphericalSampling.SamplingSphere referenceSamplingSphere, interpolationMethod) {
	var diffSamples = [];
	foreach(referenceSamplingSphere.getSamples() as var refSample) {
		var value = samplingSphere.queryValue(refSample.getPosition(), interpolationMethod);
		var referenceValue = refSample.getValue();
		var diffValue = void;
		if(value ---|> MinSG.VisibilityVector) {
			diffValue = referenceValue.makeDifference(value);
		} else {
			diffValue = referenceValue - value;
		}
		var samplePoint = new MinSG.SphericalSampling.SamplePoint(refSample.getPosition());
		samplePoint.setValue(diffValue);
		samplePoint.description = refSample.description;
		diffSamples += samplePoint;
	}
	return new MinSG.SphericalSampling.SamplingSphere(
		samplingSphere.getSphere().clone(), 
		diffSamples
	);
};

//!	[static]
SVS.saveSamplingSphereValues := fn(MinSG.SphericalSampling.SamplingSphere samplingSphere, String fileName) {
	var values = "PositionX\tPositionY\tPositionZ\tValue\n";
	foreach(samplingSphere.getSamples() as var sample) {
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
SVS.outputSamplingSphereComparison := fn(MinSG.SphericalSampling.SamplingSphere samplingSphere, 
													   MinSG.SVS.SamplingSphere referenceSamplingSphere,
													   String fileName) {
	var output = "Interpolation\t";
	output += "EVSCardinality\tEVSBenefits\tEVSCosts\t";
	output += "PVSCardinality\tPVSBenefits\tPVSCosts\t";
	output += "OverestimationCardinality\tOverestimationBenefits\tOverestimationCosts\t";
	output += "UnderestimationCardinality\tUnderestimationBenefits\tUnderestimationCosts\n";
	foreach(referenceSamplingSphere.getSamples() as var refSample) {
		var exactVisibleSet = refSample.getValue();
		foreach({	"Nearest"	: MinSG.SphericalSampling.INTERPOLATION_NEAREST, 
					"Max3"	 	: MinSG.SphericalSampling.INTERPOLATION_MAX3, 
					"Weighted3"	: MinSG.SphericalSampling.INTERPOLATION_WEIGHTED3} as var interpolationString, var interpolationMethod) {
			var potentiallyVisibleSet = samplingSphere.queryValue(refSample.getPosition(), interpolationMethod);
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
SVS.setUpSamplingSphereEvaluation := fn(plugin) {
	var window = gui.createWindow(350, 350, "Sampling Sphere Evaluation", GUI.ONE_TIME_WINDOW);
	window.setPosition(GLOBALS.renderingContext.getWindowWidth() - 350, 280);
	
	var windowPanel = gui.create({
		GUI.TYPE				:	GUI.TYPE_PANEL,
		GUI.SIZE				:	GUI.SIZE_MAXIMIZE
	});
	window += windowPanel;
	
	var config = new ExtObject ({
		$samplingSphere				:	void,
		$referenceSamplingSphere	:	void,
		$differenceSamplingSphere	:	void,
		$interpolationMethod		:	MinSG.SphericalSampling.INTERPOLATION_NEAREST
	});
	var refreshGroup = new GUI.RefreshGroup();
	
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_TEXT,
		GUI.LABEL				:	"Current",
		GUI.TOOLTIP				:	"Current sampling sphere",
		GUI.DATA_PROVIDER		:	(fn(ExtObject config) {
										return config.samplingSphere.toString();
									}).bindLastParams(config),
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
		GUI.FLAGS				:	GUI.LOCKED
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_TEXT,
		GUI.LABEL				:	"Reference",
		GUI.TOOLTIP				:	"Reference sampling sphere",
		GUI.DATA_PROVIDER		:	(fn(ExtObject config) {
										return config.referenceSamplingSphere.toString();
									}).bindLastParams(config),
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
		GUI.FLAGS				:	GUI.LOCKED
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_TEXT,
		GUI.LABEL				:	"Difference",
		GUI.TOOLTIP				:	"Difference sampling sphere",
		GUI.DATA_PROVIDER		:	(fn(ExtObject config) {
										return config.differenceSamplingSphere.toString();
									}).bindLastParams(config),
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
									[MinSG.SphericalSampling.INTERPOLATION_NEAREST, "Nearest"],
									[MinSG.SphericalSampling.INTERPOLATION_MAX3, "Max3"],
									[MinSG.SphericalSampling.INTERPOLATION_MAXALL, "MaxAll"],
									[MinSG.SphericalSampling.INTERPOLATION_WEIGHTED3, "Weighted3"]
								],
		GUI.DATA_OBJECT		:	config,
		GUI.DATA_ATTRIBUTE	:	$interpolationMethod,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	var resolution = DataWrapper.createFromValue(4096);
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
		GUI.TOOLTIP				:	"Create a new sampling sphere with the current set of spherical sampling points.",
		GUI.ON_CLICK			:	(fn(Geometry.Sphere sphere, Array samples, ExtObject config, GUI.RefreshGroup refreshGroup) {
										config.samplingSphere = new MinSG.SphericalSampling.SamplingSphere(sphere.clone(), samples.clone());
										config.samplingSphere.description = "SamplingSphere";
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
										if(!config.samplingSphere) {
											Runtime.warn("Cannot evaluate sampling sphere. Current sampling sphere not available.");
											return;
										}
										var evaluator = EvaluatorManager.getSelectedEvaluator();
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
										
										var camera = MinSG.SphericalSampling.createSamplingCamera(config.samplingSphere.getSphere(), node.getWorldMatrix(), resolution());
										frameContext.pushCamera();
										config.samplingSphere.evaluateAllSamples(frameContext, evaluator, camera, node);
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
										var samplingSphere = void;
										if(config.differenceSamplingSphere) {
											samplingSphere = config.differenceSamplingSphere;
											out("Using difference sampling sphere.\n");
										} else if(config.samplingSphere) {
											samplingSphere = config.samplingSphere;
											out("Using current sampling sphere.\n");
										} else if(config.referenceSamplingSphere) {
											samplingSphere = config.referenceSamplingSphere;
											out("Using reference sampling sphere.\n");
										}
										if(!samplingSphere) {
											Runtime.warn("Cannot add color to sampling sphere. No sampling sphere available.");
											return;
										}
										if(!samplingSphere.getSamples() || samplingSphere.getSamples().empty()) {
											Runtime.warn("Cannot add color to sampling sphere. No spherical sample points available.");
											return;
										}
										if(!samplingSphere.getSamples().front().getValue()) {
											Runtime.warn("Cannot add color to sampling sphere. No values stored in spherical sample points.");
											return;
										}
										
										GLOBALS.showWaitingScreen();
										
										textureState.setTexture(MinSG.SphericalSampling.createColorTexture(512, 256, samplingSphere, config.interpolationMethod));
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
										var dialog = new GUI.FileDialog("Save Texture", ".", [".png"],
											(fn(fileName, Rendering.Texture texture) {
												Rendering.saveTexture(GLOBALS.renderingContext, texture, fileName);
											}).bindLastParams(textureState.getTexture())
										);
										dialog.init();
									}).bindLastParams(plugin.sphereTextureState),
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.5, 0]
	};
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Load Color",
		GUI.TOOLTIP				:	"Load the texture from a file.",
		GUI.ON_CLICK			:	(fn(MinSG.TextureState textureState) {
										var dialog = new GUI.FileDialog("Load Texture", ".", [".png"],
											(fn(fileName, MinSG.TextureState textureState) {
												textureState.setTexture(Rendering.createTextureFromFile(fileName, false, true));
												textureState.activate();
											}).bindLastParams(textureState)
										);
										dialog.init();
									}).bindLastParams(plugin.sphereTextureState),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Save",
		GUI.TOOLTIP				:	"Save the current sampling sphere to a file.",
		GUI.ON_CLICK			:	(fn(ExtObject config) {
										if(!config.samplingSphere) {
											Runtime.warn("Cannot save sampling sphere. Current sampling sphere not available.");
											return;
										}
										var dialog = new GUI.FileDialog("Save Sampling Sphere", ".", [".samplingsphere"],
											(fn(fileName, ExtObject config) {
												Util.saveFile(fileName, PADrend.serialize(config.samplingSphere));
											}).bindLastParams(config)
										);
										dialog.init();
									}).bindLastParams(config),
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.5, 0]
	};
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Load",
		GUI.TOOLTIP				:	"Load the current sampling sphere from a file.",
		GUI.ON_CLICK			:	(fn(ExtObject config, GUI.RefreshGroup refreshGroup) {
										var dialog = new GUI.FileDialog("Load Sampling Sphere", ".", [".samplingsphere"],
											(fn(fileName, ExtObject config, GUI.RefreshGroup refreshGroup) {
												config.samplingSphere = PADrend.deserialize(Util.loadFile(fileName));
												refreshGroup.refresh();
											}).bindLastParams(config, refreshGroup)
										);
										dialog.init();
									}).bindLastParams(config, refreshGroup),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Load Reference",
		GUI.TOOLTIP				:	"Load the reference sampling sphere from a file.",
		GUI.ON_CLICK			:	(fn(ExtObject config, GUI.RefreshGroup refreshGroup) {
										var dialog = new GUI.FileDialog("Load Sampling Sphere", ".", [".samplingsphere"],
											(fn(fileName, ExtObject config, GUI.RefreshGroup refreshGroup) {
												config.referenceSamplingSphere = PADrend.deserialize(Util.loadFile(fileName));
												refreshGroup.refresh();
											}).bindLastParams(config, refreshGroup)
										);
										dialog.init();
									}).bindLastParams(config, refreshGroup),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Compare",
		GUI.TOOLTIP				:	"Compare the current sampling sphere to the reference sampling sphere,\nand store the result in the difference sampling sphere.",
		GUI.ON_CLICK			:	(fn(ExtObject config, GUI.RefreshGroup refreshGroup) {
										if(!config.samplingSphere) {
											Runtime.warn("Cannot compare sampling spheres. Current sampling sphere not available.");
											return;
										}
										if(!config.referenceSamplingSphere) {
											Runtime.warn("Cannot compare sampling spheres. Reference sampling sphere not available.");
											return;
										}
										config.differenceSamplingSphere = SVS.compareSamplingSpheres(config.samplingSphere, 
																												   config.referenceSamplingSphere, 
																												   config.interpolationMethod);
										refreshGroup.refresh();
									}).bindLastParams(config, refreshGroup),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Save Values",
		GUI.TOOLTIP				:	"Save the values of a sampling sphere to a file.",
		GUI.ON_CLICK			:	(fn(config) {
										var samplingSphere = void;
										if(config.differenceSamplingSphere) {
											samplingSphere = config.differenceSamplingSphere;
											out("Using difference sampling sphere.\n");
										} else if(config.samplingSphere) {
											samplingSphere = config.samplingSphere;
											out("Using current sampling sphere.\n");
										} else if(config.referenceSamplingSphere) {
											samplingSphere = config.referenceSamplingSphere;
											out("Using reference sampling sphere.\n");
										}
										if(!samplingSphere) {
											Runtime.warn("Cannot save values of a sampling sphere. No sampling sphere available.");
											return;
										}
										if(!samplingSphere.getSamples() || samplingSphere.getSamples().empty()) {
											Runtime.warn("Cannot save values of a sampling sphere. No spherical sample points available.");
											return;
										}
										if(!samplingSphere.getSamples().front().getValue()) {
											Runtime.warn("Cannot save values of a sampling sphere. No values stored in spherical sample points.");
											return;
										}
										var dialog = new GUI.FileDialog("Save Sampling Sphere Values", ".", [".tsv"],
											(fn(fileName, MinSG.SphericalSampling.SamplingSphere samplingSphere) {
												SVS.saveSamplingSphereValues(samplingSphere, fileName);
											}).bindLastParams(samplingSphere)
										);
										dialog.init();
										
									}).bindLastParams(config),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	windowPanel++;
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Evaluation Run",
		GUI.TOOLTIP				:	"Start an evaluation run comparing different sample distributions to the reference sampling sphere.",
		GUI.ON_CLICK			:	(fn(ExtObject config, plugin, GUI.RefreshGroup refreshGroup, DataWrapper resolution) {
										if(!config.referenceSamplingSphere) {
											Runtime.warn("Cannot start evaluation run. Reference sampling sphere not available.");
											return;
										}
										
										GLOBALS.showWaitingScreen();
										
										var runs = [
											["Tetrahedron", SVS.createSamplesFromMesh.bindLastParams(Rendering.createTetrahedron(), "Tetrahedron")],
											["Octahedron", SVS.createSamplesFromMesh.bindLastParams(Rendering.createOctahedron(), "Octahedron")],
											["Cube", SVS.createSamplesFromMesh.bindLastParams(Rendering.createCube(), "Cube")],
											["Icosahedron", SVS.createSamplesFromMesh.bindLastParams(Rendering.createIcosahedron(), "Icosahedron")],
											["Dodecahedron", SVS.createSamplesFromMesh.bindLastParams(Rendering.createDodecahedron(), "Dodecahedron")],
										
											["TetrahedronSphere1", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createTetrahedron(), 1), "TetrahedronSphere1")],
											["TetrahedronSphere2", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createTetrahedron(), 2), "TetrahedronSphere2")],
											["TetrahedronSphere3", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createTetrahedron(), 3), "TetrahedronSphere3")],
											["TetrahedronSphere4", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createTetrahedron(), 4), "TetrahedronSphere4")],
											["TetrahedronSphere5", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createTetrahedron(), 5), "TetrahedronSphere5")],
											["OctahedronSphere1", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createOctahedron(), 1), "OctahedronSphere1")],
											["OctahedronSphere2", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createOctahedron(), 2), "OctahedronSphere2")],
											["OctahedronSphere3", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createOctahedron(), 3), "OctahedronSphere3")],
											["OctahedronSphere4", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createOctahedron(), 4), "OctahedronSphere4")],
											["OctahedronSphere5", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createOctahedron(), 5), "OctahedronSphere5")],
											["IcosahedronSphere1", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createIcosahedron(), 1), "IcosahedronSphere1")],
											["IcosahedronSphere2", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createIcosahedron(), 2), "IcosahedronSphere2")],
											["IcosahedronSphere3", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createIcosahedron(), 3), "IcosahedronSphere3")],
											["IcosahedronSphere4", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createIcosahedron(), 4), "IcosahedronSphere4")],
											["IcosahedronSphere5", SVS.createSamplesFromMesh.bindLastParams(Rendering.createEdgeSubdivisionSphere(Rendering.createIcosahedron(), 5), "IcosahedronSphere5")]
										];
										
										var outputDir = "data/SVS/";

										var evaluator = EvaluatorManager.getSelectedEvaluator();
										if(!evaluator) {
											Runtime.exception("Invalid evaluator.");
										}

										var fbo = new Rendering.FBO();
										var color = Rendering.createStdTexture(resolution(), resolution(), true);
										var depth = Rendering.createDepthTexture(resolution(), resolution());
										renderingContext.pushAndSetFBO(fbo);
										fbo.attachColorTexture(renderingContext, color);
										fbo.attachDepthTexture(renderingContext, depth);

										var camera = MinSG.SphericalSampling.createSamplingCamera(config.referenceSamplingSphere.getSphere(), plugin.node.getWorldMatrix(), resolution());
										frameContext.pushCamera();

										foreach(runs as var run) {
											out("Evaluating \"" + run[0] + "\" ... ");
											
											var samples = run[1]();
											var samplingSphere = new MinSG.SphericalSampling.SamplingSphere(plugin.sphere.clone(), samples);
											samplingSphere.evaluateAllSamples(frameContext, evaluator, camera, plugin.node);
											//Util.saveFile(outputDir + run[0] + ".samplingsphere", PADrend.serialize(samplingSphere));
											//SVS.saveSamplingSphereValues(samplingSphere, outputDir + run[0] + ".tsv");
											//Rendering.saveTexture(GLOBALS.renderingContext, MinSG.SphericalSampling.createColorTexture(512, 256, samplingSphere, config.interpolationMethod), outputDir + run[0] + ".png");
											
											//var differenceSamplingSphere = SVS.compareSamplingSpheres(samplingSphere, config.referenceSamplingSphere, config.interpolationMethod);
											//Util.saveFile(outputDir + run[0] + "Diff.samplingsphere", PADrend.serialize(differenceSamplingSphere));
											//SVS.saveSamplingSphereValues(differenceSamplingSphere, outputDir + run[0] + "Diff.tsv");
											//Rendering.saveTexture(GLOBALS.renderingContext, MinSG.SphericalSampling.createColorTexture(512, 256, differenceSamplingSphere, config.interpolationMethod), outputDir + run[0] + "Diff.png");
											
											SVS.outputSamplingSphereComparison(samplingSphere, config.referenceSamplingSphere, outputDir + run[0] + ".tsv");
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
										var samplingSphere = void;
										if(config.differenceSamplingSphere) {
											samplingSphere = config.differenceSamplingSphere;
											out("Using difference sampling sphere.\n");
										} else if(config.samplingSphere) {
											samplingSphere = config.samplingSphere;
											out("Using current sampling sphere.\n");
										} else if(config.referenceSamplingSphere) {
											samplingSphere = config.referenceSamplingSphere;
											out("Using reference sampling sphere.\n");
										}
										if(!samplingSphere) {
											Runtime.warn("Cannot build triangulation. No sampling sphere available.");
											return;
										}
										if(!samplingSphere.getSamples() || samplingSphere.getSamples().empty()) {
											Runtime.warn("Cannot build triangulation. No spherical sample points available.");
											return;
										}
										
										GLOBALS.showWaitingScreen();
										
										var worldSphere = MinSG.SphericalSampling.transformSphere(samplingSphere.getSphere(), worldMatrix);
										
										var listNode = samplingSphere.getTriangulationMinSGNodes();
										listNode.setWorldPosition(worldSphere.getCenter());
										listNode.setScale(worldSphere.getRadius());
										
										// Dye triangulation blue
										var materialState = new MinSG.MaterialState;
										materialState.setAmbient(new Util.Color4f(0.0, 0.0, 1.0, 1.0));
										materialState.setDiffuse(new Util.Color4f(0.0, 0.0, 1.0, 1.0));
										materialState.setSpecular(new Util.Color4f(1.0, 1.0, 1.0, 1.0));
										materialState.setShininess(32.0);
										listNode.addState(materialState);
										
										PADrend.getCurrentScene().addChild(listNode);
									}).bindLastParams(config, plugin.node.getWorldMatrix()),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
};

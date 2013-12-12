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
loadOnce(__DIR__ + "/SphericalSamplePoint.escript");

//!	[static]
SVS.setUpSampleCreationGUI := fn(plugin) {
	var width = 350;
	var height = 270;
	var posX = GLOBALS.renderingContext.getWindowWidth() - width;
	var posY = 10;
	var window = gui.createWindow(width, height, "SVS Sample Creation", GUI.ONE_TIME_WINDOW);
	window.setPosition(posX, posY);
	
	var windowPanel = gui.create({
		GUI.TYPE				:	GUI.TYPE_PANEL,
		GUI.SIZE				:	GUI.SIZE_MAXIMIZE
	});
	window += windowPanel;
	
	var samplesRefreshGroup = new GUI.RefreshGroup();
	
	var sampleList = gui.create({
		GUI.TYPE				:	GUI.TYPE_LIST,
		GUI.OPTIONS				:	[],
		GUI.ON_DATA_CHANGED		:	(fn(data, Array samples) {
										foreach(samples as var sample) {
											sample.selected = false;
										}
										foreach(data as var sample) {
											sample.selected = true;
										}
									}).bindLastParams(plugin.samples),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS, 10, 200]
	});
	// When there is a real list view, this function can be changed into a GUI.DATA_PROVIDER function.
	samplesRefreshGroup += 	(fn(listView, Array samples) {
								listView.clear();
								
								foreach(samples as var sample) {
									listView += [sample, sample.description + " (" + sample.getPosition().toString() + ")"];
								}
							}).bindLastParams(sampleList, plugin.samples);
	windowPanel += sampleList;
	windowPanel++;
	
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_MENU,
		GUI.LABEL				:	"Add",
		GUI.TOOLTIP				:	"Create new sample points and add them to the list of existing sample points.",
		GUI.MENU				:	[
										{
											GUI.TYPE		:	GUI.TYPE_MENU,
											GUI.LABEL		:	"Platonic Solids",
											GUI.TOOLTIP		:	"Add a sample point for each vertex of a platonic solid.",
											GUI.MENU		:	[
																	{
																		GUI.TYPE		:	GUI.TYPE_BUTTON,
																		GUI.LABEL		:	"Tetrahedron (4 vertices)",
																		GUI.TOOLTIP		:	"Add a sample point for each vertex of a tetrahedron.",
																		GUI.ON_CLICK	:	(fn(Array samples, GUI.RefreshGroup samplesRefreshGroup) {
																								var mesh = Rendering.createTetrahedron();
																								samples.append(SVS.createSamplesFromMesh(mesh, "Tetrahedron"));
																								samplesRefreshGroup.refresh();
																							}).bindLastParams(plugin.samples, samplesRefreshGroup)
																	},
																	{
																		GUI.TYPE		:	GUI.TYPE_BUTTON,
																		GUI.LABEL		:	"Octahedron (6 vertices)",
																		GUI.TOOLTIP		:	"Add a sample point for each vertex of an octahedron.",
																		GUI.ON_CLICK	:	(fn(Array samples, GUI.RefreshGroup samplesRefreshGroup) {
																								var mesh = Rendering.createOctahedron();
																								samples.append(SVS.createSamplesFromMesh(mesh, "Octahedron"));
																								samplesRefreshGroup.refresh();
																							}).bindLastParams(plugin.samples, samplesRefreshGroup)
																	},
																	{
																		GUI.TYPE		:	GUI.TYPE_BUTTON,
																		GUI.LABEL		:	"Cube (8 vertices)",
																		GUI.TOOLTIP		:	"Add a sample point for each vertex of a cube.",
																		GUI.ON_CLICK	:	(fn(Array samples, GUI.RefreshGroup samplesRefreshGroup) {
																								var mesh = Rendering.createCube();
																								samples.append(SVS.createSamplesFromMesh(mesh, "Cube"));
																								samplesRefreshGroup.refresh();
																							}).bindLastParams(plugin.samples, samplesRefreshGroup)
																	},
																	{
																		GUI.TYPE		:	GUI.TYPE_BUTTON,
																		GUI.LABEL		:	"Icosahedron (12 vertices)",
																		GUI.TOOLTIP		:	"Add a sample point for each vertex of an icosahedron.",
																		GUI.ON_CLICK	:	(fn(Array samples, GUI.RefreshGroup samplesRefreshGroup) {
																								var mesh = Rendering.createIcosahedron();
																								samples.append(SVS.createSamplesFromMesh(mesh, "Icosahedron"));
																								samplesRefreshGroup.refresh();
																							}).bindLastParams(plugin.samples, samplesRefreshGroup)
																	},
																	{
																		GUI.TYPE		:	GUI.TYPE_BUTTON,
																		GUI.LABEL		:	"Dodecahedron (20 vertices)",
																		GUI.TOOLTIP		:	"Add a sample point for each vertex of a dodecahedron.",
																		GUI.ON_CLICK	:	(fn(Array samples, GUI.RefreshGroup samplesRefreshGroup) {
																								var mesh = Rendering.createDodecahedron();
																								samples.append(SVS.createSamplesFromMesh(mesh, "Dodecahedron"));
																								samplesRefreshGroup.refresh();
																							}).bindLastParams(plugin.samples, samplesRefreshGroup)
																	}
																],
											GUI.MENU_WIDTH	:	150
										},
										{
											GUI.TYPE		:	GUI.TYPE_BUTTON,
											GUI.LABEL		:	"Subdivision Sphere",
											GUI.TOOLTIP		:	"Add a sample point for each vertex of a subdivision sphere.",
											GUI.ON_CLICK	:	(fn(Array samples, GUI.RefreshGroup samplesRefreshGroup) {
																	var config = new ExtObject({
																		$samples				:	samples,
																		$samplesRefreshGroup	:	samplesRefreshGroup,
																		$platonicSolid			:	Rendering.createIcosahedron,
																		$subdivisions			:	1
																	});
																	
																	var dialog = gui.createPopupWindow(300, 100);
																	dialog.addOption({
																		GUI.TYPE			:	GUI.TYPE_SELECT,
																		GUI.LABEL			:	"Platonic Solid",
																		GUI.TOOLTIP			:	"The platonic solid that is used a origin of the subdivision process.",
																		GUI.OPTIONS			:	[
																									[Rendering.createTetrahedron, "Tetrahedron"],
																									[Rendering.createOctahedron, "Octahedron"],
																									[Rendering.createIcosahedron, "Icosahedron"]
																								],
																		GUI.DATA_OBJECT		:	config,
																		GUI.DATA_ATTRIBUTE	:	$platonicSolid
																	});
																	dialog.addOption({
																		GUI.TYPE			:	GUI.TYPE_RANGE,
																		GUI.LABEL			:	"Number of Subdivisions",
																		GUI.TOOLTIP			:	"The number of samples increases exponentially in the number of subdivisions.",
																		GUI.RANGE			:	[1, 10],
																		GUI.RANGE_STEPS		:	9,
																		GUI.DATA_OBJECT		:	config,
																		GUI.DATA_ATTRIBUTE	:	$subdivisions
																	});
																	dialog.addAction("Generate Samples", (fn(config) {
																		var mesh = Rendering.createEdgeSubdivisionSphere(config.platonicSolid(), config.subdivisions);
																		config.samples.append(SVS.createSamplesFromMesh(mesh, "SubdivisonSphere"));
																		config.samplesRefreshGroup.refresh();
																	}).bindLastParams(config));
																	dialog.addAction("Cancel");
																	dialog.init();
																}).bindLastParams(plugin.samples, samplesRefreshGroup)
										},
										{
											GUI.TYPE		:	GUI.TYPE_BUTTON,
											GUI.LABEL		:	"Spherical Coordinates",
											GUI.TOOLTIP		:	"Add a sample point for different increments of inclination and azimuth angles.",
											GUI.ON_CLICK	:	(fn(Array samples, GUI.RefreshGroup samplesRefreshGroup) {
																	var config = new ExtObject({
																		$samples				:	samples,
																		$samplesRefreshGroup	:	samplesRefreshGroup,
																		$inclinationSegments	:	16,
																		$azimuthSegments		:	16
																	});
																	
																	var dialog = gui.createPopupWindow(300, 100);
																	dialog.addOption({
																		GUI.TYPE			:	GUI.TYPE_RANGE,
																		GUI.LABEL			:	"Inclination Segments",
																		GUI.TOOLTIP			:	"The segmentation of the inclination angle used to generate the sample points.",
																		GUI.RANGE			:	[1, 180],
																		GUI.RANGE_STEPS		:	179,
																		GUI.DATA_OBJECT		:	config,
																		GUI.DATA_ATTRIBUTE	:	$inclinationSegments
																	});
																	dialog.addOption({
																		GUI.TYPE			:	GUI.TYPE_RANGE,
																		GUI.LABEL			:	"Azimuth Segments",
																		GUI.TOOLTIP			:	"The segmentation of the azimuth angle used to generate the sample points.",
																		GUI.RANGE			:	[1, 360],
																		GUI.RANGE_STEPS		:	359,
																		GUI.DATA_OBJECT		:	config,
																		GUI.DATA_ATTRIBUTE	:	$azimuthSegments
																	});
																	dialog.addAction("Generate Samples", (fn(config) {
																		var newSamples = SVS.createSphericalCoordinateSamples(
																								config.inclinationSegments, 
																								config.azimuthSegments);
																		config.samples.append(newSamples);
																		config.samplesRefreshGroup.refresh();
																	}).bindLastParams(config));
																	dialog.addAction("Cancel");
																	dialog.init();
																}).bindLastParams(plugin.samples, samplesRefreshGroup)
										},
										{
											GUI.TYPE		:	GUI.TYPE_BUTTON,
											GUI.LABEL		:	"Random Spherical Coordinates",
											GUI.TOOLTIP		:	"Add a given number of random sample points.",
											GUI.ON_CLICK	:	(fn(Array samples, GUI.RefreshGroup samplesRefreshGroup) {
																	
																	var dialog = gui.createPopupWindow(300, 100);
																	var numSamples = DataWrapper.createFromValue(100);
																	dialog.addOption({
																		GUI.TYPE			:	GUI.TYPE_RANGE,
																		GUI.LABEL			:	"Number",
																		GUI.TOOLTIP			:	"Number of sample points that will be generated.",
																		GUI.RANGE			:	[0, 1.0e+4],
																		GUI.RANGE_STEP_SIZE	:	100,
																		GUI.DATA_WRAPPER	:	numSamples
																	});
																	dialog.addAction("Generate Samples", fn(numSamples, samples, samplesRefreshGroup) {
																		var newSamples = SVS.createRandomSphericalCoordinateSamples(numSamples());
																		samples.append(newSamples);
																		samplesRefreshGroup.refresh();
																	}.bindLastParams(numSamples, samples, samplesRefreshGroup));
																	dialog.addAction("Cancel");
																	dialog.init();
																}).bindLastParams(plugin.samples, samplesRefreshGroup)
										}
									],
		GUI.MENU_WIDTH			:	150,
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.5, 0]
	};
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Clear",
		GUI.TOOLTIP				:	"Delete existing sample points.",
		GUI.ON_CLICK			:	(fn(Array samples, GUI.RefreshGroup samplesRefreshGroup) {
										samples.clear();
										samplesRefreshGroup.refresh();
									}).bindLastParams(plugin.samples, samplesRefreshGroup),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	
	window.setEnabled(true);
};

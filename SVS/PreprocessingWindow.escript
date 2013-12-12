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

SVS.setUpPreprocessingWindow := fn() {
	var width = 300;
	var height = 270;
	var posX = GLOBALS.renderingContext.getWindowWidth() - width;
	var posY = 0;
	var window = gui.createWindow(width, height, "SVS Preprocessing", GUI.ONE_TIME_WINDOW);
	window.setPosition(posX, posY);

	var panel = gui.create({
		GUI.TYPE			:	GUI.TYPE_CONTAINER,
		GUI.SIZE			:	GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT			:	GUI.LAYOUT_FLOW
	});
	window += panel;

	panel += "*Information*";
	panel++;

	var selectedNode = DataWrapper.createFromFunctions(NodeEditor -> NodeEditor.getSelectedNode, void, true);
	panel += {
		GUI.TYPE			:	GUI.TYPE_TEXT,
		GUI.LABEL			:	"Selected Node:",
		GUI.DATA_WRAPPER	:	selectedNode,
		GUI.FLAGS			:	GUI.LOCKED,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var numGroupNodes = DataWrapper.createFromValue(0);
	panel += {
		GUI.TYPE			:	GUI.TYPE_NUMBER,
		GUI.LABEL			:	"#GroupNodes:",
		GUI.TOOLTIP			:	"Nominal value, because a sampling sphere\nis created for every group node.",
		GUI.DATA_WRAPPER	:	numGroupNodes,
		GUI.FLAGS			:	GUI.LOCKED,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var numSamplingSpheres = DataWrapper.createFromValue(0);
	panel += {
		GUI.TYPE			:	GUI.TYPE_NUMBER,
		GUI.LABEL			:	"#SamplingSpheres:",
		GUI.TOOLTIP			:	"Actual value. Should be equal to the number\nof group nodes after preprocessing.",
		GUI.DATA_WRAPPER	:	numSamplingSpheres,
		GUI.FLAGS			:	GUI.LOCKED,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Refresh",
		GUI.ON_CLICK		:	selectedNode -> selectedNode.forceRefresh,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	selectedNode.onDataChanged += [numGroupNodes, numSamplingSpheres] => fn(numGroupNodes, numSamplingSpheres, node) {
		if(node) {
			var groupNodes = MinSG.collectNodes(node, MinSG.GroupNode);
			numGroupNodes(groupNodes.count());
			var count = 0;
			foreach(groupNodes as var groupNode) {
				if(MinSG.SVS.hasSamplingSphere(groupNode)) {
					++count;
				}
			}
			numSamplingSpheres(count);
		} else {
			numGroupNodes(0);
			numSamplingSpheres(0);
		}
	};
	registerExtension('NodeEditor_OnNodesSelected', [panel, selectedNode] => fn(guiElement, dataWrapper, nodes) {
		if(guiElement.isDestroyed()) {
			return Extension.REMOVE_EXTENSION;
		}
		dataWrapper.refresh();
	});

	panel += "*Actions*";
	panel++;

	var resolution = DataWrapper.createFromValue(512);
	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.LABEL			:	"Resolution",
		GUI.RANGE			:	[6, 13],
		GUI.RANGE_STEPS		:	7,
		GUI.RANGE_FN_BASE	:	2,
		GUI.TOOLTIP			:	"Horizontal and vertical resolution in pixels that will be used for rendering during the preprocessing.",
		GUI.DATA_WRAPPER	:	resolution,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var useExistingVisibilityResults = DataWrapper.createFromValue(false);
	panel += {
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.LABEL			:	"Use Existing Visibility Results",
		GUI.TOOLTIP			:	"If checked, visibility results from child nodes\nthat have been computed earlier will be used for\nvisibility tests in inner nodes",
		GUI.DATA_WRAPPER	:	useExistingVisibilityResults,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var computeTightInnerBoundingSpheres = DataWrapper.createFromValue(false);
	panel += {
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.LABEL			:	"Compute Tight Inner Bounding Spheres",
		GUI.TOOLTIP			:	"If checked, bounding spheres for inner nodes will\nbe computed based on the vertices in the subtree.",
		GUI.DATA_WRAPPER	:	computeTightInnerBoundingSpheres,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Preprocess",
		GUI.TOOLTIP			:	"Start the preprocessing for the subtree\nstarting at the selected node.",
		GUI.ON_CLICK		:	[
									selectedNode, 
									resolution, 
									useExistingVisibilityResults, 
									computeTightInnerBoundingSpheres
								] => fn(selectedNode, 
										DataWrapper resolution, 
										DataWrapper useExistingVisibilityResults,
										DataWrapper computeTightInnerBoundingSpheres) {
									if(!selectedNode() || !(selectedNode() ---|> MinSG.GroupNode)) {
										outln("Preprocessing can be started for group nodes only.");
										return;
									}

									var memoryBefore = Util.getAllocatedMemorySize();

									var timer = new Util.Timer();
									timer.reset();
									SVS.preprocessSubtree(PADrend.getSceneManager(),
																		frameContext,
																		selectedNode(),
																		SVS.getDefaultSamplePositions(),
																		resolution(),
																		useExistingVisibilityResults(),
																		computeTightInnerBoundingSpheres());
									timer.stop();

									var memoryAfter = Util.getAllocatedMemorySize();

									outln("Spherical Visibility Sampling (SVS):");
									outln("- Preprocessing time: " + timer.getSeconds() + " s");
									outln("- Memory: " + (memoryAfter - memoryBefore) / 1024 / 1024 + " MiB");

									PADrend.getSceneManager().registerGeometryNodes(selectedNode());

									selectedNode.forceRefresh();
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Enable Renderer",
		GUI.TOOLTIP			:	"Create a new intermediate node below the\nselected node and attach the renderer.",
		GUI.ON_CLICK		:	[selectedNode] => fn(selectedNode) {
									if(!selectedNode()) {
										outln("Invalid node given.");
										return;
									}
									var children = MinSG.getChildNodes(selectedNode());

									// Introduce new intermediate node, because renderer does not display the node it is attached to.
									var newNode = new MinSG.ListNode;

									// Move children to new parent
									foreach(children as var child) {
										newNode.addChild(child);
									}

									selectedNode().addChild(newNode);
									newNode.setNodeAttribute('SamplingSphere', selectedNode().getNodeAttribute('SamplingSphere'));
									selectedNode().unsetNodeAttribute('SamplingSphere');

									selectedNode().addState(new MinSG.SVS.Renderer);
									var projSizeFilterState = new MinSG.ProjSizeFilterState;
									projSizeFilterState.setTargetChannel("NO_CHANNEL");
									selectedNode().addState(projSizeFilterState);
									var budgetAnnotationState = new MinSG.BudgetAnnotationState;
									budgetAnnotationState.setAnnotationAttribute("TriangleBudget");
									budgetAnnotationState.setBudget(1.0e+7);
									budgetAnnotationState.setDistributionType(MinSG.BudgetAnnotationState.DISTRIBUTE_PROJECTED_SIZE);
									selectedNode().addState(budgetAnnotationState);

									if(PADrend.getCurrentScene() == selectedNode()) {
										PADrend.selectScene(selectedNode());
									}
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Remove",
		GUI.TOOLTIP			:	"Remove all sampling spheres from the\nsubtree starting at the selected node.",
		GUI.ON_CLICK		:	[selectedNode] => fn(selectedNode) {
									if(!selectedNode() || !(selectedNode() ---|> MinSG.GroupNode)) {
										outln("A group node is expected as parameter.");
										return;
									}
									var nodesToProcess = MinSG.collectNodesWithAttribute(selectedNode(), "SamplingSphere");
									foreach(nodesToProcess as var node) {
										node.unsetNodeAttribute("SamplingSphere");
									}
									outln("Removed ", nodesToProcess.count(), " visibility spheres.");

									selectedNode.forceRefresh();
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Transform spheres",
		GUI.TOOLTIP			:	"Transform all spheres from world coordinates to local coordinates.",
		GUI.ON_CLICK		:	[selectedNode] => fn(selectedNode) {
									MinSG.SVS.transformSpheresFromWorldToLocal(selectedNode());
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Output information",
		GUI.TOOLTIP			:	"Write a file containing information about\nthe MinSG tree, preprocessing settings,\nand rendering settings.",
		GUI.ON_CLICK		:	[
									selectedNode, 
									resolution, 
									useExistingVisibilityResults, 
									computeTightInnerBoundingSpheres
								] => fn(DataWrapper selectedNode, 
										DataWrapper resolution, 
										DataWrapper useExistingVisibilityResults, 
										DataWrapper computeTightInnerBoundingSpheres) {
									SVS.writePreprocessingInfoFile(selectedNode(),
																				 resolution(),
																				 useExistingVisibilityResults(),
																				 computeTightInnerBoundingSpheres());
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Preprocessing run",
		GUI.TOOLTIP			:	"Run the preprocessing multiple times with\ndifferent parameters.",
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0],
		GUI.ON_CLICK		:	[selectedNode] => fn(DataWrapper selectedNode) {
			var minResolution = DataWrapper.createFromValue(64);
			var maxResolution = DataWrapper.createFromValue(4096);
			gui.openDialog({
				GUI.TYPE	:	GUI.TYPE_POPUP_DIALOG,
				GUI.LABEL	:	"Preprocessing settings",
				GUI.SIZE	:	[300,240],
				GUI.OPTIONS	:	[
					{
						GUI.TYPE			:	GUI.TYPE_RANGE,
						GUI.LABEL			:	"Min. resolution",
						GUI.RANGE			:	[6, 13],
						GUI.RANGE_STEPS		:	7,
						GUI.RANGE_FN_BASE	:	2,
						GUI.DATA_WRAPPER	:	minResolution,
						GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
					},
					{
						GUI.TYPE			:	GUI.TYPE_RANGE,
						GUI.LABEL			:	"Max. resolution",
						GUI.RANGE			:	[6, 13],
						GUI.RANGE_STEPS		:	7,
						GUI.RANGE_FN_BASE	:	2,
						GUI.DATA_WRAPPER	:	maxResolution,
						GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
					}
				],
				GUI.ACTIONS	:	[
					[	"Start", 
						[
							selectedNode, 
							minResolution, 
							maxResolution
						] => fn(DataWrapper selectedNode, 
								DataWrapper minResolution,
								DataWrapper maxResolution) {
							if(!selectedNode() || !(selectedNode() ---|> MinSG.GroupNode)) {
								outln("Preprocessing can be started for group nodes only.");
								return;
							}
							SVS.multiplePreprocessingRuns(PADrend.getSceneManager(),
																		frameContext,
																		selectedNode(),
																		SVS.getDefaultSamplePositions(),
																		minResolution(),
																		maxResolution());
							selectedNode.forceRefresh();
						}
					],
					"Cancel"
				]
			});
		}
	};
};

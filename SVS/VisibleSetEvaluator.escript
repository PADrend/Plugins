/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
declareNamespace($SVS);

SVS.VisibleSetEvaluator := new Type(MinSG.ScriptedEvaluator);

SVS.VisibleSetEvaluator._constructor ::= fn() {
	this.fbo := new Rendering.FBO;
	this.pvsSource := DataWrapper.createFromValue(void);

	this.potentiallyVisibleSet := void;
	this.exactVisibleSet := void;
	this.overestimation := void;
	this.underestimation := void;
};

SVS.VisibleSetEvaluator.measureExactVisibleSet := fn(	MinSG.FrameContext frameContext,
																	MinSG.GroupNode node,
																	Geometry.Rect rect) {
	var evaluator = new MinSG.CostEvaluator(MinSG.Evaluator.SINGLE_VALUE);
	evaluator.beginMeasure();
	evaluator.measure(frameContext, node, rect);
	evaluator.endMeasure(frameContext);

	return evaluator.getResults().front();
};

SVS.VisibleSetEvaluator.beginMeasure @(override)::= fn() {
	potentiallyVisibleSet = void;
	exactVisibleSet = void;
	overestimation = void;
	underestimation = void;
	return this;
};

SVS.VisibleSetEvaluator.endMeasure @(override) ::= fn(MinSG.FrameContext frameContext) {
	return this;
};

SVS.VisibleSetEvaluator.measure @(override) ::= fn(	MinSG.FrameContext frameContext, 
																	MinSG.Node node,
																	Geometry.Rect rect) {
	if(!pvsSource()) {
		Runtime.warn("Cannot measure because PVS source is missing.");
		return this;
	}
	var width = rect.getWidth();
	var height = rect.getHeight();

	var color = Rendering.createStdTexture(width, height, true);
	var depth = Rendering.createDepthTexture(width, height);
	var renderingContext = frameContext.getRenderingContext();
	renderingContext.pushAndSetFBO(fbo);
	fbo.attachColorTexture(renderingContext, color);
	fbo.attachDepthTexture(renderingContext, depth);

	renderingContext.pushViewport();
	renderingContext.setViewport(rect.getX(), rect.getY(), rect.getWidth(), rect.getHeight());

	PADrend.renderScene(node, void, PADrend.getRenderingFlags(), PADrend.getBGColor(), PADrend.getRenderingLayers());

	var collectedNodes = pvsSource().getCollectedNodes();
	potentiallyVisibleSet = new MinSG.VisibilityVector;
	foreach(collectedNodes as var geoNode) {
		potentiallyVisibleSet.setNode(geoNode, 1);
	}

	exactVisibleSet = measureExactVisibleSet(frameContext, node, rect);

	overestimation = potentiallyVisibleSet.makeDifference(exactVisibleSet);
	underestimation = exactVisibleSet.makeDifference(potentiallyVisibleSet);

	renderingContext.popViewport();
	renderingContext.popFBO();

	return this;
};

SVS.VisibleSetEvaluator.getResults @(override) ::= fn() {
	return getExtendedResult();
};

SVS.VisibleSetEvaluator.getExtendedResultDescription ::= fn() {
	return [
		"EVSCardinality",
		"EVSBenefits",
		"EVSCosts",
		"PVSCardinality",
		"PVSBenefits",
		"PVSCosts",
		"OverestimationCardinality",
		"OverestimationBenefits",
		"OverestimationCosts",
		"UnderestimationCardinality",
		"UnderestimationBenefits",
		"UnderestimationCosts"
	];
};

SVS.VisibleSetEvaluator.getExtendedResult ::= fn() {
	if(!exactVisibleSet) {
		return [
			void, void, void,
			void, void, void,
			void, void, void,
			void, void, void
		];
	}
	return [
		exactVisibleSet.getVisibleNodeCount(),
		exactVisibleSet.getTotalBenefits(),
		exactVisibleSet.getTotalCosts(),
		potentiallyVisibleSet.getVisibleNodeCount(),
		potentiallyVisibleSet.getTotalBenefits(),
		potentiallyVisibleSet.getTotalCosts(),
		overestimation.getVisibleNodeCount(),
		overestimation.getTotalBenefits(),
		overestimation.getTotalCosts(),
		underestimation.getVisibleNodeCount(),
		underestimation.getTotalBenefits(),
		underestimation.getTotalCosts()
	];
};

SVS.VisibleSetEvaluator.getMaxValue ::= fn() {
	return getExtendedResult()[0];
};

SVS.VisibleSetEvaluator.getMode ::= fn() {
	return MinSG.Evaluator.SINGLE_VALUE;
};

SVS.VisibleSetEvaluator.setMode ::= fn(dummy) {
};

SVS.VisibleSetEvaluator.getEvaluatorTypeName ::= fn() {
	return "VisibleSetEvaluator";
};

SVS.VisibleSetEvaluator.createConfigPanel ::= fn() {
	// parent::createConfigPanel()
	var panel = (this -> MinSG.Evaluator.createConfigPanel)();

	panel += {
		GUI.TYPE				:	GUI.TYPE_SELECT,
		GUI.LABEL				:	"PVS Source",
		GUI.TOOLTIP				:	"Select a collector that provides the potentially visible set (PVS).",
		GUI.DATA_WRAPPER		:	pvsSource,
		GUI.OPTIONS_PROVIDER	:	fn() {
										var states = MinSG.collectStates(PADrend.getCurrentScene(), 
																		 MinSG.SVS.GeometryNodeCollector);
										var options = [];
										foreach(states as var state) {
											options += [state, state.toString()];
										}
										return options;
									},
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	return panel;
};

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

SVS.RenderingStatsEvaluator := new Type(MinSG.ScriptedEvaluator);

SVS.RenderingStatsEvaluator._constructor ::= fn() {
	this.idFrameDurationCounter := PADrend.frameStatistics.getFrameDurationCounter();
	this.idTrianglesCounter := PADrend.frameStatistics.getTrianglesCounter();
	this.idLinesCounter := PADrend.frameStatistics.getLinesCounter();
	this.idPointsCounter := PADrend.frameStatistics.getPointsCounter();
	this.idNodeCounter := PADrend.frameStatistics.getNodeCounter();

	this.measuredFrameDuration := 0;
	this.measuredNumTriangles := 0;
	this.measuredNumLines := 0;
	this.measuredNumPoints := 0;
	this.measuredNumNodes := 0;
};

SVS.RenderingStatsEvaluator.beginMeasure @(override)::= fn() {
	measuredFrameDuration = 0;
	measuredNumTriangles = 0;
	measuredNumLines = 0;
	measuredNumPoints = 0;
	measuredNumNodes = 0;
	return this;
};

SVS.RenderingStatsEvaluator.endMeasure @(override) ::= fn(MinSG.FrameContext frameContext) {
	return this;
};

SVS.RenderingStatsEvaluator.measure @(override) ::= fn(	MinSG.FrameContext frameContext, 
																		MinSG.Node node,
																		Geometry.Rect rect) {
	frameContext.getRenderingContext().clearScreen(PADrend.getBGColor());

	frameContext.getRenderingContext().finish();
	frameContext.beginFrame();
	node.display(frameContext, PADrend.getRenderingFlags());
	frameContext.endFrame(true);

	measuredFrameDuration = PADrend.frameStatistics.getValue(idFrameDurationCounter);
	measuredNumTriangles = PADrend.frameStatistics.getValue(idTrianglesCounter);
	measuredNumLines = PADrend.frameStatistics.getValue(idLinesCounter);
	measuredNumPoints = PADrend.frameStatistics.getValue(idPointsCounter);
	measuredNumNodes = PADrend.frameStatistics.getValue(idNodeCounter);

	return this;
};

SVS.RenderingStatsEvaluator.getResults @(override) ::= fn() {
	return getExtendedResult();
};

SVS.RenderingStatsEvaluator.getExtendedResultDescription ::= fn() {
	return [
		"FrameDuration",
		"NumTriangles",
		"NumLines",
		"NumPoints",
		"NumNodes"
	];
};

SVS.RenderingStatsEvaluator.getExtendedResult ::= fn() {
	return [
		measuredFrameDuration,
		measuredNumTriangles,
		measuredNumLines,
		measuredNumPoints,
		measuredNumNodes
	];
};

SVS.RenderingStatsEvaluator.getMaxValue ::= fn() {
	return getExtendedResult()[0];
};

SVS.RenderingStatsEvaluator.getMode ::= fn() {
	return MinSG.Evaluator.SINGLE_VALUE;
};

SVS.RenderingStatsEvaluator.setMode ::= fn(dummy) {
};

SVS.RenderingStatsEvaluator.getEvaluatorTypeName ::= fn() {
	return "RenderingStatsEvaluator";
};

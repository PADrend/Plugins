/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */

// --------------------------------------------------------------------------------

static T = new Type;

T.statistics @(private,init) := Map;
T.getStatistics @(public) ::= fn() { 
	return statistics; 
};

T.targetCount @(private) := 10000;
T.setTargetCount @(public) ::= fn(Number v) { targetCount = v; return this; };
T.getTargetCount @(public) ::= fn() { return targetCount; };

T.seed @(private) := 0;
T.setSeed @(public) ::= fn(Number v) { seed = v; return this; };
T.getSeed @(public) ::= fn() { return seed; };

T.debug @(private) := false;
T.setDebug @(public) ::= fn(Bool v) {	debug = v; return this; };
T.getDebug @(public) ::= fn() { return debug; };

T.sample @(override) ::= fn(MinSG.Node node) {
  return void;
};



T.getCommonGUI := fn(config) {
	return [
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Target Surfels",
			GUI.RANGE : [0,100000],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : config.targetCount,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Seed",
			GUI.RANGE : [0,10000],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : config.seed,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
	];
};

return T;

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2019 Sascha Brandt <sascha@brandt.graphics>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

// --------------------------------------------------------------------------------

static T = new Type;

T.statistics @(private,init) := Map;
T.getStatistics @(public) ::= fn() { 
	return statistics; 
};

T.sampler @(private) := void;
T.targetCount @(private) := 10000;
T.setTargetCount @(public) ::= fn(Number v) { targetCount = v; if(sampler) sampler.setTargetCount(v); return this; };
T.getTargetCount @(public) ::= fn() { return targetCount; };

T.seed @(private) := 0;
T.setSeed @(public) ::= fn(Number v) { seed = v; if(sampler) sampler.setSeed(v); return this; };
T.getSeed @(public) ::= fn() { return seed; };

T.debug @(private) := false;
T.setDebug @(public) ::= fn(Bool v) {	debug = v; return this; };
T.getDebug @(public) ::= fn() { return debug; };

T.sample ::= fn(MinSG.Node node) {
	return void;
};

// -----------------------------------------------------------------------
// GUI

static SurfelGUI = Std.module("BlueSurfels/GUI/SurfelGUI");
T.getCommonGUI := fn(sampler) {
	return [
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Debug",
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('debug', false, sampler->sampler.setDebug),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Target Count",
			GUI.RANGE : [0,100000],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.RANGE : [1,6],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.RANGE_FN_BASE : 10,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('targetCount', 10000, sampler->sampler.setTargetCount),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Seed",
			GUI.RANGE : [0,10000],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('seed', 0, sampler->sampler.setSeed),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		"----",
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
	];
};

return T;

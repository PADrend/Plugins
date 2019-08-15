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
static SamplerBase = Std.module("BlueSurfels/Sampler/SamplerBase");
static Rasterizer = Std.module("BlueSurfels/Tools/Rasterizer");
static Utils = Std.module("BlueSurfels/Utils");

// --------------------------------------------------------------------------------

static T = new Type(SamplerBase);
T._printableName := $GreedyCluster;

T.setResolution @(public) ::= fn(Number v) { rasterizer.setResolution(v); return this; };
T.getResolution @(public) ::= fn() { return rasterizer.getResolution(); };

T.setDirections @(public) ::= fn(Array dir) { rasterizer.setDirections(dir); return this; };
T.getDirections @(public) ::= fn() { return rasterizer.getDirections(); };

T.getSampleTimes ::= fn() { return sampler.getSampleTimes(); };

// ----------------------------

T._constructor ::= fn() {
	this.sampler = new MinSG.BlueSurfels.GreedyCluster;
	this.rasterizer := new Rasterizer;
};

/**
 * Render node from multiple directions and stores resulting pixels in a mesh
 */
T.sample @(override) ::= fn(MinSG.Node node) {
	var totalTimer = new Util.Timer;
	var timer = new Util.Timer;
	statistics.clear();
	
	[var t_depth, var t_color, var t_position, var t_normal] = rasterizer.rasterize(node);
	var layers = getDirections().count();
	
	statistics["t_renderScene"] = timer.getSeconds();
	
	if(debug)
		rasterizer.showDebugTextures();
	
	timer.reset();
	var initialSamples = Utils.packMesh(t_color, t_position, t_normal, getResolution(), layers);
	statistics["t_downloadMesh"] = timer.getSeconds();
	if(!initialSamples)
		return void;
	
	var samples = sampler.sampleSurfels(initialSamples);
	
	statistics.merge(sampler.getStatistics());
	statistics["t_total"] = totalTimer.getSeconds();
	return samples;
};

// --------------------------------------------------------------
// GUI

static SurfelGUI = Std.module("BlueSurfels/GUI/SurfelGUI");
SurfelGUI.registerSampler(T);
SurfelGUI.registerSamplerGUI(T, fn(sampler) {
	var elements = SamplerBase.getCommonGUI(sampler);
	return elements.append([
		{
			GUI.TYPE :	GUI.TYPE_SELECT,
			GUI.LABEL :	"Directions",
			GUI.OPTIONS :	{
				var dirOptions = [];
				foreach(Utils.getDirectionPresets() as var name, var dirs)
					dirOptions += [name, name + " ("+dirs.count()+")"];
				dirOptions;
			},	
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('directions', 'cube', [sampler] => fn(sampler, name) {
				sampler.setDirections(Utils.getDirectionPresets()[name]);
			}),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Resolution",
			GUI.RANGE : [0,10],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.RANGE_FN_BASE : 2,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('resolution', 512, sampler->sampler.setResolution),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
	]);
});

return T;
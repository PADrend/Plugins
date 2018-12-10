/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
static SamplerBase = Std.module("BlueSurfels/Sampler/SamplerBase");
static ScannerRegistry = Std.module("BlueSurfels/Config/SurfaceScannerConfig");
static SamplerRegistry = Std.module("BlueSurfels/GUI/SamplerRegistry");
static Utils = Std.module("BlueSurfels/Utils");

// --------------------------------------------------------------------------------

static T = new Type(SamplerBase);
T._printableName := $GreedyCluster;

T.resolution @(private) := 512;
T.setResolution @(public) ::= fn(Number v) { resolution = v; return this; };
T.getResolution @(public) ::= fn() { return resolution; };

T.directions @(private,init) := fn() {
	return [
		new Geometry.Vec3( 1, 1, 1), new Geometry.Vec3(-1,-1,-1), new Geometry.Vec3( 1, 1,-1), new Geometry.Vec3(-1,-1, 1),
		new Geometry.Vec3( 1,-1, 1), new Geometry.Vec3(-1, 1,-1), new Geometry.Vec3( 1,-1,-1), new Geometry.Vec3(-1, 1, 1)
	]; 
};
T.setDirections @(public) ::= fn(Array dir) { directions = dir; return this; };
T.getDirections @(public) ::= fn() { return directions; };

// ----------------------------

T._constructor ::= fn() {
  this.sampler := new MinSG.BlueSurfels.GreedyCluster;
};

/**
 * Render node from multiple directions and stores resulting pixels in a mesh
 */
T.sample @(override) ::= fn(MinSG.Node node) {
	statistics.clear();
  
};

// --------------------------------------------------------------
// GUI

static SamplerRegistry = Std.module("BlueSurfels/GUI/SamplerRegistry");
SamplerRegistry.registerSampler(T);
SamplerRegistry.registerSamplerConfig(T, fn(scanner, config) {
	scanner.setDebug(config.debug());
	scanner.setDirections(Utils.getDirectionPresets()[config.directionPresetName()]);
	scanner.setResolution(config.resolution());
	scanner.setTargetCount(config.targetCount());
	scanner.setLocalSort(config.sortLocal());
	scanner.setGlobalSort(config.sortGlobal());
	scanner.setSamplesPerRound(config.samplesPerRound());
	scanner.setProfiling(config.profiling());
	scanner.setAutodetect(config.autodetect());
	scanner.setAdaptiveResolution(config.adaptiveRes());
	scanner.setUsePacking(config.usePacking());
	scanner.setUseMultilayer(config.multilayer());
});
ScannerRegistry.registerScannerConfigGUI(T, fn(config) {
	SamplerRegistry.getCachedConfig().samplerName($PassThroughSampler);
	return [
		{
	    GUI.TYPE :	GUI.TYPE_SELECT,
	    GUI.LABEL :	"Directions",
	    GUI.OPTIONS :	{
	      var dirOptions = [];
	      foreach(Utils.getDirectionPresets() as var name, var dirs)
	        dirOptions += [name, name + " ("+dirs.count()+")"];
	      dirOptions;
	    },	
	    GUI.DATA_WRAPPER : config.directionPresetName,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
	  },
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Resolution",
			GUI.RANGE : [0,10],
			GUI.RANGE_STEP_SIZE : 1,
      GUI.RANGE_FN_BASE : 2,
			GUI.DATA_WRAPPER : config.resolution,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Debug",
			GUI.DATA_WRAPPER : config.debug,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Profiling",
			GUI.DATA_WRAPPER : config.profiling,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Autodetect",
			GUI.DATA_WRAPPER : config.autodetect,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Target Surfels",
			GUI.RANGE : [1,6],
			GUI.RANGE_STEP_SIZE : 1,
      GUI.RANGE_FN_BASE : 10,
			GUI.DATA_WRAPPER : config.targetCount,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Intermediate Sort",
			GUI.DATA_WRAPPER : config.sortLocal,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Samples per round",
			GUI.TOOLTIP : "Only used when 'Intermediate Sort' is enabled.",
			GUI.RANGE : [0,1],
			GUI.RANGE_STEP_SIZE : 0.1,
			GUI.DATA_WRAPPER : config.samplesPerRound,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Final Sort",
			GUI.DATA_WRAPPER : config.sortGlobal,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Adaptive Resolution",
			GUI.DATA_WRAPPER : config.adaptiveRes,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Compute Packing Value",
			GUI.DATA_WRAPPER : config.usePacking,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Use Multilayer Rendering",
			GUI.DATA_WRAPPER : config.multilayer,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
	];
});

return T;
/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
static Utils = Std.module("BlueSurfels/Utils");

static scannerRegistry = new Map;  // displayableName -> scanner
static scannerGUIRegistry = new Map; // scannerName -> guiProvider(obj)
static scannerConfigRegistry = new Map; // scannerName -> applyConfig(obj)

var registry = new Namespace;

registry.registerScanner := fn(scanner, String displayableName=""){
	if(displayableName.empty())
		displayableName = scanner._printableName;
	scannerRegistry[displayableName] = scanner;
};

registry.registerScannerConfigGUI := fn(scanner, provider) {
	Std.Traits.requireTrait(provider, Std.Traits.CallableTrait);
	scannerGUIRegistry[scanner._printableName] = provider;
};

registry.registerScannerConfig := fn(scanner, applyConfig) {
	Std.Traits.requireTrait(applyConfig, Std.Traits.CallableTrait);
	scannerConfigRegistry[scanner._printableName] = applyConfig;
};

registry.getScanners := fn() { return scannerRegistry.clone(); };
registry.getScanner := fn(scannerName){ return scannerRegistry[scannerName]; };
registry.getGUIProvider := fn(scannerName){ return scannerGUIRegistry[scannerName]; };
registry.applyConfig := fn(scanner, config) {
	scannerConfigRegistry[scanner._printableName](scanner, config);
};

// -----------------------------------------------------------------------
// RasterScanner

var RasterScanner = Std.module('BlueSurfels/Scanners/RasterScanner');
registry.registerScanner(RasterScanner);
registry.registerScannerConfig(RasterScanner, fn(scanner, config) {
	scanner.setDebug(config.debug());
	scanner.setDirections(Utils.getDirectionPresets()[config.directionPresetName()]);
	scanner.setResolution(config.resolution());
});
registry.registerScannerConfigGUI(RasterScanner, fn(config) {
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
	];
});

return registry;

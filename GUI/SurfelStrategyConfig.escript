/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
static surfelStrategyRegistry = new Map;  // displayableName -> strategy
static surfelStrategyGUIRegistry = new Map; // strategyName -> guiProvider(obj)

var registry = new Namespace;

registry.registerStrategy := fn(strategy, String displayableName=""){
	if(displayableName.empty())
		displayableName = strategy._printableName;
	surfelStrategyRegistry[displayableName] = strategy;
};

registry.registerStrategyConfigGUI := fn(strategy, provider) {
	Std.Traits.requireTrait(provider, Std.Traits.CallableTrait);
	surfelStrategyGUIRegistry[strategy._printableName] = provider;
};

registry.getStrategies := fn() { return surfelStrategyRegistry.clone(); };
registry.getStrategy := fn(strategyName){ return surfelStrategyRegistry[strategyName]; };
registry.getGUIProvider := fn(strategy){ return surfelStrategyGUIRegistry[strategy._printableName]; };

// -----------------------------------------------------------------------
// MinSG.BlueSurfels.FixedSizeStrategy

registry.registerStrategy(MinSG.BlueSurfels.FixedSizeStrategy);
registry.registerStrategyConfigGUI(MinSG.BlueSurfels.FixedSizeStrategy, fn(strategy, refreshCallback) {
	return [
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Point Size",
			GUI.RANGE : [1,64],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(strategy->strategy.getSize, strategy->strategy.setSize),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
		},
	];
});

// -----------------------------------------------------------------------
// MinSG.BlueSurfels.FixedCountStrategy

registry.registerStrategy(MinSG.BlueSurfels.FixedCountStrategy);
registry.registerStrategyConfigGUI(MinSG.BlueSurfels.FixedCountStrategy, fn(strategy, refreshCallback) {
	return [
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Surfel Count",
			GUI.RANGE : [0,100000],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(strategy->strategy.getCount, strategy->strategy.setCount),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
		},
	];
});

// -----------------------------------------------------------------------
// MinSG.BlueSurfels.FactorStrategy

registry.registerStrategy(MinSG.BlueSurfels.FactorStrategy);
registry.registerStrategyConfigGUI(MinSG.BlueSurfels.FactorStrategy, fn(strategy, refreshCallback) {
	return [
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Count Factor",
			GUI.RANGE : [0,2],
			GUI.RANGE_STEP_SIZE : 0.01,
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(strategy->strategy.getCountFactor, strategy->strategy.setCountFactor),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Size Factor",
			GUI.RANGE : [0,2],
			GUI.RANGE_STEP_SIZE : 0.01,
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(strategy->strategy.getSizeFactor, strategy->strategy.setSizeFactor),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
		},
	];
});
  
// -----------------------------------------------------------------------
// MinSG.BlueSurfels.BlendStrategy

registry.registerStrategy(MinSG.BlueSurfels.BlendStrategy);
registry.registerStrategyConfigGUI(MinSG.BlueSurfels.BlendStrategy, fn(strategy, refreshCallback) {
	return [
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Blending",
			GUI.RANGE : [0,1],
			GUI.RANGE_STEP_SIZE : 0.1,
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(strategy->strategy.getBlend, strategy->strategy.setBlend),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
		},
	];
});
  
// -----------------------------------------------------------------------
// MinSG.BlueSurfels.DebugStrategy

registry.registerStrategy(MinSG.BlueSurfels.DebugStrategy);
registry.registerStrategyConfigGUI(MinSG.BlueSurfels.DebugStrategy, fn(strategy, refreshCallback) {
	return [
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Hide Surfels",
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(strategy->strategy.getHideSurfels, strategy->strategy.setHideSurfels),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Fix Surfels",
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(strategy->strategy.getFixSurfels, strategy->strategy.setFixSurfels),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
		},
	];
});
  
// -----------------------------------------------------------------------
// MinSG.BlueSurfels.AdaptiveStrategy

registry.registerStrategy(MinSG.BlueSurfels.AdaptiveStrategy);
registry.registerStrategyConfigGUI(MinSG.BlueSurfels.AdaptiveStrategy, fn(strategy, refreshCallback) {
	return [
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Max. Point Size",
			GUI.RANGE : [1,64],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(strategy->strategy.getMaxSize, strategy->strategy.setMaxSize),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Target Frame Time (ms)",
			GUI.RANGE : [1,100],
			GUI.RANGE_STEP_SIZE : 0.1,
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(strategy->strategy.getTargetTime, strategy->strategy.setTargetTime),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
		},
	];
});
  
// -----------------------------------------------------------------------
// MinSG.BlueSurfels.FoveatedStrategy

registry.registerStrategy(MinSG.BlueSurfels.FoveatedStrategy);
registry.registerStrategyConfigGUI(MinSG.BlueSurfels.FoveatedStrategy, fn(strategy, refreshCallback) {
	return [
		{
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.LABEL : "Offset",
			GUI.OPTIONS : ["0, 0"],
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
			GUI.DATA_PROVIDER : [strategy] => fn(strategy){
        var vec = strategy.getOffset();
        return "" + vec.x() + ", " + vec.y();
			},
			GUI.ON_DATA_CHANGED : [strategy] => fn(strategy,data) {
        strategy.setOffset(eval("new Geometry.Vec2("+data+");"));
			}
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.LABEL : "Zones",
			GUI.OPTIONS : ["0.5, 2.0"],
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
			GUI.DATA_PROVIDER : [strategy] => fn(strategy){
        return strategy.getFoveaZones().implode(",");
			},
			GUI.ON_DATA_CHANGED : [strategy] => fn(strategy,data) {
        strategy.setFoveaZones(parseJSON("["+data+"]"));
			}
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Debug",
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(strategy->strategy.getDebug, strategy->strategy.setDebug),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
		},
	];
});
  
// -----------------------------------------------------------------------
// MinSG.BlueSurfels.ShaderStrategy

registry.registerStrategy(MinSG.BlueSurfels.ShaderStrategy);
registry.registerStrategyConfigGUI(MinSG.BlueSurfels.ShaderStrategy, fn(strategy, refreshCallback) {	
	
	var config = new ExtObject({
		$shaderVS : DataWrapper.createFromFunctions(strategy->strategy.getShaderVS, strategy->strategy.setShaderVS),
		$shaderFS : DataWrapper.createFromFunctions(strategy->strategy.getShaderFS, strategy->strategy.setShaderFS),
		$shaderGS : DataWrapper.createFromFunctions(strategy->strategy.getShaderGS, strategy->strategy.setShaderGS),
		$preset : new Std.DataWrapper(""),
	});
	
	foreach(PADrend.getSceneManager()._getSearchPaths() as var path) {
		strategy.addSearchPath(path);
	}
	
	config.preset.onDataChanged += [config] => fn(config, presetName) {
		if(presetName && !presetName.empty()) {
			var shaderFile = PADrend.getSceneManager().locateFile(presetName);
			if(!shaderFile){
				Runtime.warn("Unknown shader:"+shaderName);
				return;
			}
			var fs = ""; var gs = ""; var vs = "";
			var m = parseJSON( Util.loadFile(shaderFile) );
			if(m['shader/glsl_fs'])
				fs = m['shader/glsl_fs'].front();
			if(m['shader/glsl_gs'])
				gs = m['shader/glsl_gs'].front();
			if(m['shader/glsl_vs'])
				vs = m['shader/glsl_vs'].front();
			
			config.shaderVS(vs);
			config.shaderFS(fs);
			config.shaderGS(gs);
		}
	};
	
	var setFromPreset = [config] => fn(config) {
		gui.openDialog({
			GUI.TYPE : GUI.TYPE_POPUP_DIALOG,
			GUI.LABEL : "Preset",
			GUI.ACTIONS : ["Done"],
			GUI.SIZE : [400,100],
			GUI.OPTIONS : [
				{
					GUI.TYPE : GUI.TYPE_TEXT,
					GUI.LABEL : "Preset:",
					GUI.OPTIONS_PROVIDER : fn(){
						var entries = [""];
						foreach(PADrend.getSceneManager()._getSearchPaths() as var path) {
							foreach(Util.getFilesInDir(path,[".shader"]) as var filename) {
								entries += (new Util.FileName(filename)).getFile();
							}
						}
						return entries;
					},
					GUI.DATA_WRAPPER : config.preset
				}
			]
		});
	};
	
	return [
    {
      GUI.LABEL : "Set from preset",
      GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.ON_CLICK : setFromPreset,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
    },
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
    {
      GUI.LABEL : "VS",
      GUI.TYPE : GUI.TYPE_FILE,
      GUI.ENDINGS : [".sfn", ".vs", ".glsl"],
			GUI.DATA_WRAPPER : config.shaderVS,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
    },
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
    {
      GUI.LABEL : "FS",
      GUI.TYPE : GUI.TYPE_FILE,
      GUI.ENDINGS : [".sfn", ".fs", ".glsl"],
			GUI.DATA_WRAPPER : config.shaderFS,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
    },
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
    {
      GUI.LABEL : "GS",
      GUI.TYPE : GUI.TYPE_FILE,
      GUI.ENDINGS : [".sfn", ".gs", ".glsl"],
			GUI.DATA_WRAPPER : config.shaderGS,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
    },
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Refresh",
      GUI.ON_CLICK : strategy->strategy.refreshShader,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
		},
	];
});

return registry;

/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */

// -----------------------------------------------------------------------
// Surfel Strategy Registry

static surfelStrategyRegistry = new Map;  // displayableName -> strategy
static surfelStrategyGUIRegistry = new Map; // strategyName -> guiProvider(obj)

static NS = new Namespace;

NS.registerStrategy := fn(strategy, String displayableName=""){
	if(displayableName.empty())
		displayableName = strategy._printableName;
	surfelStrategyRegistry[displayableName] = strategy;
};

NS.registerStrategyGUI := fn(strategy, provider) {
	Std.Traits.requireTrait(provider, Std.Traits.CallableTrait);
	surfelStrategyGUIRegistry[strategy._printableName] = provider;
};

NS.getStrategies := fn() { return surfelStrategyRegistry.clone(); };
NS.getStrategy := fn(strategyName){ return surfelStrategyRegistry[strategyName]; };
NS.getGUIProvider := fn(strategy){ return surfelStrategyGUIRegistry[strategy._printableName]; };

// -----------------------------------------------------------------------
// Basic GUI

NS.initGUI := fn(gui) {
	
	Util.registerExtension('NodeEditor_QueryAvailableStates',fn(m) {
		m["[ext] SurfelRenderer"] = fn(){
			var state = new MinSG.SurfelRenderer;
			state.addSurfelStrategy(new MinSG.BlueSurfels.FixedSizeStrategy);
			state.addSurfelStrategy(new MinSG.BlueSurfels.BlendStrategy);
			return state;
		};
	});
	
	static strategyTitleProperties = [
		new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,gui._createRectShape(new Util.Color4ub(200,200,200,255),new Util.Color4ub(200,200,200,255),true))
	];
	
	NodeEditor.registerConfigPanelProvider(MinSG.SurfelRenderer, fn(state, panel) {
		var refreshCallback = fn(){ thisFn.container.refreshContents(); }.clone();
		
		var container = gui.create({
			GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
			GUI.LABEL : "Strategies",
			GUI.COLLAPSED : false,
			GUI.CONTENTS : {
				GUI.TYPE : GUI.TYPE_COMPONENTS,
				GUI.PROVIDER : 'NodeEditor_SurfelStrategy',
				GUI.CONTEXT_ARRAY : [state, refreshCallback]
			},
			GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS , 10 ,5 ]
		});
		refreshCallback.container := container;
		
		panel += container;
		panel++;
	});
	
	gui.register('NodeEditor_SurfelStrategy.2_strategies', fn(state, refreshCallback) {
		var entries = [];
		foreach(state.getSurfelStrategies() as var strategy) {
			var provider = NS.getGUIProvider(strategy);
			if(provider) {
				entries += { GUI.TYPE : GUI.TYPE_NEXT_ROW };
				entries += '----';
				entries += { GUI.TYPE : GUI.TYPE_NEXT_ROW };
				entries += {
					GUI.TYPE : GUI.TYPE_LABEL,
					GUI.LABEL : strategy.getTypeName(),
					GUI.FLAGS : GUI.BACKGROUND | GUI.USE_SCISSOR,
					GUI.PROPERTIES : strategyTitleProperties,
					GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS, 60, 16],
				};
				entries += {
					GUI.TYPE : GUI.TYPE_BOOL,
					GUI.FLAGS : GUI.FLAT_BUTTON | GUI.BACKGROUND,
					GUI.TOOLTIP : "Enabled",
					GUI.LABEL : "",
					GUI.SIZE : [GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 16, 16],
					GUI.PROPERTIES : strategyTitleProperties,
	  			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(strategy->strategy.isEnabled, strategy->strategy.setEnabled),
				};
				entries += {
					GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
					GUI.FLAGS : GUI.FLAT_BUTTON | GUI.BACKGROUND,
					GUI.TOOLTIP : "Remove Strategy",
					GUI.LABEL : "-",
					GUI.SIZE : [GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 16, 16],
					GUI.PROPERTIES : strategyTitleProperties,
					GUI.ON_CLICK : [state, strategy, refreshCallback] => fn(state, strategy, refreshCallback){
						state.removeSurfelStrategy(strategy);
						refreshCallback();
					}
				};
				entries += { GUI.TYPE : GUI.TYPE_NEXT_ROW };
				entries.append(provider(strategy, refreshCallback));
			}
		}
		return entries;
	});
	
	gui.register('NodeEditor_SurfelStrategy.3_addStrategy', fn(state, refreshCallback) {
		return [
			{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
			'----',
			{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
			{
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "Add strategy",
				GUI.MENU : [state, refreshCallback] => fn(state, refreshCallback){
					var entries = [];
					foreach(NS.getStrategies() as var name, var Strategy) {						
						entries += {
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : name,
							GUI.WIDTH : 200,
							GUI.ON_CLICK : [state, Strategy, refreshCallback] => fn(state, Strategy, refreshCallback){
								state.addSurfelStrategy(new Strategy);
								refreshCallback();
							},
						};
					}
					return entries;
				}
			},
			{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		];
	});
};

// -----------------------------------------------------------------------
// MinSG.BlueSurfels.FixedSizeStrategy

NS.registerStrategy(MinSG.BlueSurfels.FixedSizeStrategy);
NS.registerStrategyGUI(MinSG.BlueSurfels.FixedSizeStrategy, fn(strategy, refreshCallback) {
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

NS.registerStrategy(MinSG.BlueSurfels.FixedCountStrategy);
NS.registerStrategyGUI(MinSG.BlueSurfels.FixedCountStrategy, fn(strategy, refreshCallback) {
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

NS.registerStrategy(MinSG.BlueSurfels.FactorStrategy);
NS.registerStrategyGUI(MinSG.BlueSurfels.FactorStrategy, fn(strategy, refreshCallback) {
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

NS.registerStrategy(MinSG.BlueSurfels.BlendStrategy);
NS.registerStrategyGUI(MinSG.BlueSurfels.BlendStrategy, fn(strategy, refreshCallback) {
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
// MinSG.BlueSurfels.ReferencePointStrategy

NS.registerStrategy(MinSG.BlueSurfels.ReferencePointStrategy);
NS.registerStrategyGUI(MinSG.BlueSurfels.ReferencePointStrategy, fn(strategy, refreshCallback) {
	return [
		{
			GUI.TYPE : GUI.TYPE_SELECT,
			GUI.LABEL : "Reference Point",
			GUI.OPTIONS : [
				[MinSG.BlueSurfels.CLOSEST_SURFEL, "Closest Surfel"],
				[MinSG.BlueSurfels.CLOSEST_BB, "Closest BB"],
				[MinSG.BlueSurfels.FARTHEST_BB, "Farthest BB"],
				[MinSG.BlueSurfels.CENTER_BB, "Center BB"],
			],
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(strategy->strategy.getReferencePoint, strategy->strategy.setReferencePoint),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
		},
	];
});

// -----------------------------------------------------------------------
// MinSG.BlueSurfels.DebugStrategy

NS.registerStrategy(MinSG.BlueSurfels.DebugStrategy);
NS.registerStrategyGUI(MinSG.BlueSurfels.DebugStrategy, fn(strategy, refreshCallback) {
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

NS.registerStrategy(MinSG.BlueSurfels.AdaptiveStrategy);
NS.registerStrategyGUI(MinSG.BlueSurfels.AdaptiveStrategy, fn(strategy, refreshCallback) {
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

NS.registerStrategy(MinSG.BlueSurfels.FoveatedStrategy);
NS.registerStrategyGUI(MinSG.BlueSurfels.FoveatedStrategy, fn(strategy, refreshCallback) {
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

NS.registerStrategy(MinSG.BlueSurfels.ShaderStrategy);
NS.registerStrategyGUI(MinSG.BlueSurfels.ShaderStrategy, fn(strategy, refreshCallback) {	
	
	var config = new ExtObject({
		$shaderVS : DataWrapper.createFromFunctions(strategy->strategy.getShaderVS, strategy->strategy.setShaderVS),
		$shaderFS : DataWrapper.createFromFunctions(strategy->strategy.getShaderFS, strategy->strategy.setShaderFS),
		$shaderGS : DataWrapper.createFromFunctions(strategy->strategy.getShaderGS, strategy->strategy.setShaderGS),
		$culling : DataWrapper.createFromFunctions(strategy->strategy.getSurfelCulling, strategy->strategy.setSurfelCulling),
		$dynSize : DataWrapper.createFromFunctions(strategy->strategy.getSurfelDynSize, strategy->strategy.setSurfelDynSize),
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
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Surfel Culling",
			GUI.DATA_WRAPPER : config.culling,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 20, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Dynamic Size",
			GUI.DATA_WRAPPER : config.dynSize,
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

return NS;

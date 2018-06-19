/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012-2013 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2014-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
var plugin = new Plugin({
	Plugin.NAME				:	'BlueSurfels',
	Plugin.DESCRIPTION		:	"Progressive Blue Surfels",
	Plugin.VERSION			:	0.3,
	Plugin.AUTHORS			:	"Sascha Brandt, Claudius Jaehn",
	Plugin.OWNER			:	"Sascha Brandt",
	Plugin.LICENSE			:	"Proprietary",
	Plugin.REQUIRES			:	['NodeEditor'],
	Plugin.EXTENSION_POINTS	:	[]
});

plugin.init:=fn() {
	PADrend.SceneManagement.addSearchPath(__DIR__ + "/resources/shader/");
	
	module.on('PADrend/gui', this->initGUI);	
	
	Util.registerExtension('NodeEditor_QueryAvailableStates',fn(m) {
		m["[ext] SurfelRenderer"] = fn(){
			var state = new MinSG.SurfelRenderer;
			state.addSurfelStrategy(new MinSG.BlueSurfels.FixedSizeStrategy);
			state.addSurfelStrategy(new MinSG.BlueSurfels.BlendStrategy);
			return state;
		};
	});

  Util.registerExtension('PADrend_Init',this->fn(){      
		loadOnce(__DIR__+"/SurfelDebugRenderer.escript");
  });
	
	return true;
};

plugin.initGUI := fn(gui) {
	static strategyRegistry = Std.module("BlueSurfels/GUI/SurfelStrategyConfig");
		
	static strategyTitleProperties = [
		new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,gui._createRectShape(new Util.Color4ub(200,200,200,255),new Util.Color4ub(200,200,200,255),true))
	];
	
	static blueSurfelsGUI = Std.module('BlueSurfels/GUI');
	blueSurfelsGUI.initGUI(gui);
	
	Util.registerExtension('PADrend_KeyPressed' , fn(evt) {
		if(evt.key == Util.UI.KEY_F6) {
			blueSurfelsGUI.toggleWindow(gui);
			return true;
		}
		return false;
	});

	gui.register('PADrend_PluginsMenu.blueSurfels', {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Blue Surfels...",
		GUI.ON_CLICK : [gui] => blueSurfelsGUI.toggleWindow
	});

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
			var provider = strategyRegistry.getGUIProvider(strategy);
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
					foreach(strategyRegistry.getStrategies() as var name, var Strategy) {						
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

return plugin;
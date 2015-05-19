/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var plugin = new Plugin({
		Plugin.NAME : 'StatisticsWindow',
		Plugin.DESCRIPTION : "Window showing configurable statistics",
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Benjamin Eikel",
		Plugin.OWNER : "All",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.REQUIRES : ['PADrend/GUI'],
		Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) := fn() {
	Util.registerExtension('PADrend_Init', this -> fn() {
		gui.register('Tools_ToolsMenu.info_statistics', [{
			GUI.TYPE		:	GUI.TYPE_MENU,
			GUI.LABEL		:	"Statistics Windows",
			GUI.MENU		:	'StatisticsWindow'
		}]);
		gui.register('StatisticsWindow.Windows', this -> this.buildWindowsMenu);
		var windowMap = PADrend.configCache.getValue("StatisticsWindow", new Map);
		foreach(windowMap as var key, var value) {
			if(value["openAutomatically"]) {
				createStatisticsWindow("StatisticsWindow." + key);
			}
		}
	},Extension.LOW_PRIORITY); // low priority to allow other plugins to register new statistic counters.
	return true;
};

plugin.buildWindowsMenu := fn() {
	var windowEntries = [];

	var unusedIndex = 0;
	var windowMap = PADrend.configCache.getValue("StatisticsWindow", new Map);
	foreach(windowMap as var key, var value) {
		if(key == "Window" + unusedIndex) {
			++unusedIndex;
		}
		windowEntries += {
			GUI.TYPE		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	value["title"],
			GUI.ON_CLICK	:	["StatisticsWindow." + key] => this.createStatisticsWindow,
			GUI.TOOLTIP		:	"Open an existing statistics window."
		};
	}

	if(windowMap.count() != 0) {
		windowEntries += GUI.H_DELIMITER;
	}
	windowEntries += {
		GUI.TYPE		:	GUI.TYPE_BUTTON,
		GUI.LABEL		:	"New Window",
		GUI.ON_CLICK	:	["StatisticsWindow.Window" + unusedIndex] => this.createStatisticsWindow,
		GUI.TOOLTIP		:	"Open a new statistics window."
	};
	return windowEntries;
};

plugin.createStatisticsWindow := fn(String windowConfigPrefix) {
	var windowRectDefault = [0, GLOBALS.renderingContext.getWindowHeight() - 220,260, 220];

	{ //! Compatibility (refs #601) Remove after 2013-04-07
		var pos = PADrend.configCache.getValue(windowConfigPrefix + ".position");
		var dim = PADrend.configCache.getValue(windowConfigPrefix + ".dimensions");
		if(pos&&dim){
			windowRectDefault[0] = pos[0];
			windowRectDefault[1] = pos[1];
			windowRectDefault[2] = dim[0];
			windowRectDefault[3] = dim[1];
		}
	}
	var window = gui.create(
		{
			GUI.TYPE 			: 	GUI.TYPE_WINDOW,
			GUI.FLAGS 			: 	GUI.ONE_TIME_WINDOW | GUI.HIDDEN_WINDOW,
			GUI.LABEL 			: 	""
		}
	);
	//! \see GUI.ContextMenuTrait
	Std.Traits.addTrait(window, Std.module('LibGUIExt/Traits/ContextMenuTrait'),200);

	//! \see GUI.StorableRectTrait
	Std.Traits.addTrait(window, Std.module('LibGUIExt/Traits/StorableRectTrait'),
			Std.DataWrapper.createFromEntry(PADrend.configCache, windowConfigPrefix + ".rect", windowRectDefault));


	var openAutomatically = Std.DataWrapper.createFromEntry(PADrend.configCache, windowConfigPrefix + ".openAutomatically", false);

	// *** Window Title ***
	var windowTitle = Std.DataWrapper.createFromEntry(PADrend.configCache, windowConfigPrefix + ".title", windowConfigPrefix);
	windowTitle.onDataChanged += window -> window.setTitle;
	window.setTitle(windowTitle());

	// *** Window Colors ***
	var windowForegroundColor = Std.DataWrapper.createFromEntry(PADrend.configCache, windowConfigPrefix + ".foregroundColor", [1, 1, 1, 1]);
	var windowBackgroundColor = Std.DataWrapper.createFromEntry(PADrend.configCache, windowConfigPrefix + ".backgroundColor", [0, 0, 0, 0]);
	var windowHighlightColor = Std.DataWrapper.createFromEntry(PADrend.configCache, windowConfigPrefix + ".highlightColor", [1, 0, 0, 1]);
	var backgroundShapeProperty = new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
														gui._createRectShape(GUI.BLACK, GUI.NO_COLOR, true));

	var resetBackground = [backgroundShapeProperty] => fn(GUI.ShapeProperty property, Array bgValues) {
		var backgroundColor = new Util.Color4ub(new Util.Color4f(bgValues));
		property.setShape(gui._createRectShape(backgroundColor, GUI.NO_COLOR, true));
	};
	windowBackgroundColor.onDataChanged += resetBackground;

	var fontSize = Std.DataWrapper.createFromEntry(PADrend.configCache, windowConfigPrefix + ".fontSize", 1);

	// *** Context Menu *** \see GUI.ContextMenuTrait
	window.contextMenuProvider += [
		GUI.H_DELIMITER,
		{
			GUI.TYPE				:	GUI.TYPE_TEXT,
			GUI.LABEL				:	"Title",
			GUI.DATA_WRAPPER		:	windowTitle
		},
		{
			GUI.TYPE				:	GUI.TYPE_BOOL,
			GUI.LABEL				:	"Open automatically",
			GUI.TOOLTIP				:	"If true, the window is opened when the plugin is loaded",
			GUI.DATA_WRAPPER		:	openAutomatically
		},
		{
			GUI.TYPE				:	GUI.TYPE_SELECT,
			GUI.LABEL				:	"Font size",
			GUI.OPTIONS				:	[[0, "normal"], [1, "large"], [2, "extra large"], [3, "huge"]],
			GUI.DATA_WRAPPER		:	fontSize
		},
		{
			GUI.TYPE	:	GUI.TYPE_MENU,
			GUI.LABEL	:	"Colors",
			GUI.MENU	:	[
								{
									GUI.TYPE				:	GUI.TYPE_COLOR,
									GUI.LABEL				:	"Foreground",
									GUI.DATA_PROVIDER		:	[windowForegroundColor]=>fn(dataWrapper) {
																	return new Util.Color4f(dataWrapper());
																},
									GUI.ON_DATA_CHANGED		:	[windowForegroundColor]=>fn(dataWrapper, color) {
																	dataWrapper(color.toArray());
																},
								},
								{
									GUI.TYPE				:	GUI.TYPE_COLOR,
									GUI.LABEL				:	"Background",
									GUI.DATA_PROVIDER		:	[windowBackgroundColor]=>fn(dataWrapper) {
																	return new Util.Color4f(dataWrapper());
																},
									GUI.ON_DATA_CHANGED		:	[windowBackgroundColor]=>fn(dataWrapper, color) {
																	dataWrapper(color.toArray());
																},
								},
								{
									GUI.TYPE				:	GUI.TYPE_COLOR,
									GUI.LABEL				:	"Highlight",
									GUI.DATA_PROVIDER		:	[windowHighlightColor]=>fn(dataWrapper) {
																	return new Util.Color4f(dataWrapper());
																},
									GUI.ON_DATA_CHANGED		:	[windowHighlightColor]=>fn(dataWrapper,color) {
																	dataWrapper(color.toArray());
																},
								}
							]
		},
		{
			GUI.TYPE				:	GUI.TYPE_CRITICAL_BUTTON,
			GUI.LABEL				:	"Destroy",
			GUI.TOOLTIP				:	"Destroy the window background and delete all its settings",
			GUI.ON_CLICK			:	[windowConfigPrefix, window] => fn(String configKey, GUI.Window window) {
											window.close();
											gui.markForRemoval(window);
											PADrend.configCache.unset(configKey);
										}
		},
		"*Statistics Counters*"
	];

	// *** Window Panel ***
	var page = gui.create({
		GUI.TYPE					:	GUI.TYPE_PANEL,
		GUI.FLAGS					:	GUI.AUTO_LAYOUT | GUI.AUTO_MAXIMIZE | GUI.BACKGROUND
	});
	page.addProperty(backgroundShapeProperty);
	resetBackground(windowBackgroundColor());

	// *** Labels for Counters ***
	var counterConfigData = [];
	var showFpsLabel = Std.DataWrapper.createFromEntry(PADrend.configCache, windowConfigPrefix + ".showFpsLabel", true);
	var rebuildLabels = [page, counterConfigData, showFpsLabel, windowForegroundColor, windowHighlightColor, fontSize] =>
							fn(panel, Array counterConfigData, showFpsLabel, fgValues, highlightValues, fontSize, ...) {
		panel.destroyContents();
		var fgColor = new Util.Color4ub(new Util.Color4f(fgValues()));
		var highlightColor = new Util.Color4ub(new Util.Color4f(highlightValues()));
		var font = GUI.FONT_ID_DEFAULT;
		if(fontSize() == 1) {
			font = GUI.FONT_ID_LARGE;
		} else if(fontSize() == 2) {
			font = GUI.FONT_ID_XLARGE;
		} else if(fontSize() == 3) {
			font = GUI.FONT_ID_HUGE;
		}
		// Special label for frame rate
		if(showFpsLabel()) {
			var fpsLabel = gui.create({
				GUI.TYPE			:	GUI.TYPE_LABEL,
				GUI.LABEL			:	"...",
				GUI.COLOR			:	fgColor,
				GUI.FONT			:	font,
				GUI.ON_MOUSE_BUTTON	:	[highlightColor, fgColor]=>fn( Util.Color4ub highlightColor, Util.Color4ub normalColor,event) {
											if(event.button != Util.UI.MOUSE_BUTTON_LEFT || !event.pressed) {
												return false;
											}
											highlight = !highlight;
											setColor(highlight ? highlightColor : normalColor);
											return true;
										},
				GUI.SIZE			:	[GUI.WIDTH_FILL_ABS,10,0],
				GUI.TEXT_ALIGNMENT	:	GUI.TEXT_ALIGN_RIGHT
			});
			fpsLabel.highlight := false;
			panel += fpsLabel;
			Util.registerExtension('PADrend_OnAvgFPSUpdated', [fpsLabel]=>fn(fpsLabel,fps) {
				if(fpsLabel.isDestroyed()) {
					return Extension.REMOVE_EXTENSION;
				}
				fpsLabel.setText("" + fps.round(0.1) + " fps");
			});
			panel++;
		}

		for(var counter = 0; counter < PADrend.frameStatistics.getNumCounters(); ++counter) {
			if(counterConfigData[counter] && counterConfigData[counter]()) {
				var description = PADrend.frameStatistics.getDescription(counter);
				var unit = PADrend.frameStatistics.getUnit(counter);
				if(unit != "1") {
					description += " [" + unit + "]";
				}
				panel += {
					GUI.TYPE			:	GUI.TYPE_LABEL,
					GUI.LABEL			:	description,
					GUI.COLOR			:	fgColor,
					GUI.FONT			:	font
				};
				panel += {	GUI.TYPE	:	GUI.TYPE_NEXT_COLUMN	};

				var label = gui.create({
					GUI.TYPE			:	GUI.TYPE_LABEL,
					GUI.LABEL			:	"...",
					GUI.COLOR			:	fgColor,
					GUI.FONT			:	font,
					GUI.ON_MOUSE_BUTTON	:	[highlightColor, fgColor]=>fn(Util.Color4ub highlightColor, Util.Color4ub normalColor,event) {
												if(event.button != Util.UI.MOUSE_BUTTON_LEFT || !event.pressed) {
													return false;
												}
												highlight = !highlight;
												setColor(highlight ? highlightColor : normalColor);
												return true;
											},
					GUI.SIZE			:	[GUI.WIDTH_FILL_ABS,10,0],
					GUI.TEXT_ALIGNMENT	:	GUI.TEXT_ALIGN_RIGHT
				});
				label.highlight := false;
				panel += label;

				Util.registerExtension('PADrend_AfterRendering', [label, counter]=>fn(label, Number counter,camera) {
					if(label.isDestroyed()) {
						return Extension.REMOVE_EXTENSION;
					}
					var value = PADrend.frameStatistics.getValue(counter);
					if(value >= 1e+9) {
						value = "" + (value / 1e+9).round(0.001) + " G";
					} else if(value >= 1.0e+6) {
						value = "" + (value / 1.0e+6).round(0.001) + " M";
					} else {
						value = "" + value.round(0.001);
					}
					label.setText(value);
				});

				panel++;
			}
		}
	};
	windowForegroundColor.onDataChanged += rebuildLabels;
	windowHighlightColor.onDataChanged += rebuildLabels;
	fontSize.onDataChanged += rebuildLabels;

	// Rebuild the panel when the value is changed
	showFpsLabel.onDataChanged += rebuildLabels;
	window.contextMenuProvider += [
		{
			GUI.TYPE			:	GUI.TYPE_BOOL,
			GUI.LABEL			:	"frame rate",
			GUI.DATA_WRAPPER	:	showFpsLabel
		}
	];
	
	var refreshConfigData =  [windowConfigPrefix,rebuildLabels,counterConfigData] => fn(windowConfigPrefix,rebuildLabels,counterConfigData){
		for(var counter = 0; counter < PADrend.frameStatistics.getNumCounters(); ++counter) {
			var description = PADrend.frameStatistics.getDescription(counter);
			counterConfigData[counter] = Std.DataWrapper.createFromEntry(PADrend.configCache, windowConfigPrefix + ".Counters." + description, false);
			// Rebuild the panel when a counter is changed
			counterConfigData[counter].onDataChanged += rebuildLabels;
		}
	};

	// \see GUI.ContextMenuTrait
	window.contextMenuProvider += [refreshConfigData,counterConfigData] => fn(refreshConfigData,counterConfigData){
		refreshConfigData();
		var menuEntries = [];

		for(var counter = 0; counter < PADrend.frameStatistics.getNumCounters(); ++counter) {
			var description = PADrend.frameStatistics.getDescription(counter);
			menuEntries +=	{
								GUI.TYPE			:	GUI.TYPE_BOOL,
								GUI.LABEL			:	description,
								GUI.DATA_WRAPPER	:	counterConfigData[counter]
							};
		}
	
		return menuEntries;
	};
	refreshConfigData();
	rebuildLabels();
	window += page;

	return window;
};

return plugin;

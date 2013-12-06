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
		Plugin.REQUIRES : ['LibUtilExt', 'PADrend/GUI'],
		Plugin.EXTENSION_POINTS : []
});

plugin.init := fn() {
	registerExtension('PADrend_Init', this -> fn() {
		gui.registerComponentProvider('Tools_ToolsMenu.info_statistics', [{
			GUI.TYPE		:	GUI.TYPE_MENU,
			GUI.LABEL		:	"Statistics Windows",
			GUI.MENU		:	'StatisticsWindow'
		}]);
		gui.registerComponentProvider('StatisticsWindow.Windows', this -> this.buildWindowsMenu);
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
			GUI.ON_CLICK	:	this.createStatisticsWindow.bindFirstParams("StatisticsWindow." + key),
			GUI.TOOLTIP		:	"Open an existing statistics window."
		};
	}

	if(windowMap.count() != 0) {
		windowEntries += GUI.H_DELIMITER;
	}
	windowEntries += {
		GUI.TYPE		:	GUI.TYPE_BUTTON,
		GUI.LABEL		:	"New Window",
		GUI.ON_CLICK	:	this.createStatisticsWindow.bindFirstParams("StatisticsWindow.Window" + unusedIndex),
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
	Traits.addTrait(window,GUI.ContextMenuTrait,200);

	//! \see GUI.StorableRectTrait
	Traits.addTrait(window,GUI.StorableRectTrait,
			DataWrapper.createFromConfig(PADrend.configCache, windowConfigPrefix + ".rect", windowRectDefault));


	var openAutomatically = DataWrapper.createFromConfig(PADrend.configCache, windowConfigPrefix + ".openAutomatically", false);

	// *** Window Title ***
	var windowTitle = DataWrapper.createFromConfig(PADrend.configCache, windowConfigPrefix + ".title", windowConfigPrefix);
	windowTitle.onDataChanged += window -> window.setTitle;
	window.setTitle(windowTitle());

	// *** Window Colors ***
	var windowForegroundColor = DataWrapper.createFromConfig(PADrend.configCache, windowConfigPrefix + ".foregroundColor", [1, 1, 1, 1]);
	var windowBackgroundColor = DataWrapper.createFromConfig(PADrend.configCache, windowConfigPrefix + ".backgroundColor", [0, 0, 0, 0]);
	var windowHighlightColor = DataWrapper.createFromConfig(PADrend.configCache, windowConfigPrefix + ".highlightColor", [1, 0, 0, 1]);
	var backgroundShapeProperty = new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
														gui._createRectShape(GUI.BLACK, GUI.NO_COLOR, true));

	var resetBackground = (fn(Array bgValues, GUI.ShapeProperty property) {
		var backgroundColor = new Util.Color4ub(new Util.Color4f(bgValues));
		property.setShape(gui._createRectShape(backgroundColor, GUI.NO_COLOR, true));
	}).bindLastParams(backgroundShapeProperty);
	windowBackgroundColor.onDataChanged += resetBackground;

	var fontSize = DataWrapper.createFromConfig(PADrend.configCache, windowConfigPrefix + ".fontSize", 1);

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
									GUI.DATA_PROVIDER		:	(fn(dataWrapper) {
																	return new Util.Color4f(dataWrapper());
																}).bindLastParams(windowForegroundColor),
									GUI.ON_DATA_CHANGED		:	(fn(color, dataWrapper) {
																	dataWrapper(color.toArray());
																}).bindLastParams(windowForegroundColor),
								},
								{
									GUI.TYPE				:	GUI.TYPE_COLOR,
									GUI.LABEL				:	"Background",
									GUI.DATA_PROVIDER		:	(fn(dataWrapper) {
																	return new Util.Color4f(dataWrapper());
																}).bindLastParams(windowBackgroundColor),
									GUI.ON_DATA_CHANGED		:	(fn(color, dataWrapper) {
																	dataWrapper(color.toArray());
																}).bindLastParams(windowBackgroundColor),
								},
								{
									GUI.TYPE				:	GUI.TYPE_COLOR,
									GUI.LABEL				:	"Highlight",
									GUI.DATA_PROVIDER		:	(fn(dataWrapper) {
																	return new Util.Color4f(dataWrapper());
																}).bindLastParams(windowHighlightColor),
									GUI.ON_DATA_CHANGED		:	(fn(color, dataWrapper) {
																	dataWrapper(color.toArray());
																}).bindLastParams(windowHighlightColor),
								}
							]
		},
		{
			GUI.TYPE				:	GUI.TYPE_CRITICAL_BUTTON,
			GUI.LABEL				:	"Destroy",
			GUI.TOOLTIP				:	"Destroy the window background and delete all its settings",
			GUI.ON_CLICK			:	(fn(String configKey, GUI.Window window) {
											window.close();
											gui.markForRemoval(window);
											PADrend.configCache.unsetValue(configKey);
										}).bindFirstParams(windowConfigPrefix, window)
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
	var showFpsLabel = DataWrapper.createFromConfig(PADrend.configCache, windowConfigPrefix + ".showFpsLabel", true);
	var rebuildLabels = (fn(panel, Array counterConfigData, showFpsLabel, fgValues, highlightValues, fontSize, ...) {
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
				GUI.ON_MOUSE_BUTTON	:	(fn(event, Util.Color4ub highlightColor, Util.Color4ub normalColor) {
											if(event.button != Util.UI.MOUSE_BUTTON_LEFT || !event.pressed) {
												return false;
											}
											highlight = !highlight;
											setColor(highlight ? highlightColor : normalColor);
											return true;
										}).bindLastParams(highlightColor, fgColor),
				GUI.SIZE			:	[GUI.WIDTH_FILL_ABS,10,0],
				GUI.TEXT_ALIGNMENT	:	GUI.TEXT_ALIGN_RIGHT
			});
			fpsLabel.highlight := false;
			panel += fpsLabel;
			registerExtension('PADrend_OnAvgFPSUpdated', (fn(fps, fpsLabel) {
				if(fpsLabel.isDestroyed()) {
					return Extension.REMOVE_EXTENSION;
				}
				fpsLabel.setText("" + fps.round(0.1) + " fps");
			}).bindLastParams(fpsLabel));
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
					GUI.ON_MOUSE_BUTTON	:	(fn(event, Util.Color4ub highlightColor, Util.Color4ub normalColor) {
												if(event.button != Util.UI.MOUSE_BUTTON_LEFT || !event.pressed) {
													return false;
												}
												highlight = !highlight;
												setColor(highlight ? highlightColor : normalColor);
												return true;
											}).bindLastParams(highlightColor, fgColor),
					GUI.SIZE			:	[GUI.WIDTH_FILL_ABS,10,0],
					GUI.TEXT_ALIGNMENT	:	GUI.TEXT_ALIGN_RIGHT
				});
				label.highlight := false;
				panel += label;

				registerExtension('PADrend_AfterRendering', (fn(camera, label, Number counter) {
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
				}).bindLastParams(label, counter));

				panel++;
			}
		}
	}).bindFirstParams(page, counterConfigData, showFpsLabel, windowForegroundColor, windowHighlightColor, fontSize);
	windowForegroundColor.onDataChanged += rebuildLabels;
	windowHighlightColor.onDataChanged += rebuildLabels;
	fontSize.onDataChanged += rebuildLabels;

	// Rebuild the panel when the value is changed
	var menuEntries = [];
	showFpsLabel.onDataChanged += rebuildLabels;
	menuEntries +=	{
						GUI.TYPE			:	GUI.TYPE_BOOL,
						GUI.LABEL			:	"frame rate",
						GUI.DATA_WRAPPER	:	showFpsLabel
					};

	for(var counter = 0; counter < PADrend.frameStatistics.getNumCounters(); ++counter) {
		var description = PADrend.frameStatistics.getDescription(counter);
		counterConfigData[counter] = DataWrapper.createFromConfig(PADrend.configCache, windowConfigPrefix + ".Counters." + description, false);
		// Rebuild the panel when a counter is changed
		counterConfigData[counter].onDataChanged += rebuildLabels;
		menuEntries +=	{
							GUI.TYPE			:	GUI.TYPE_BOOL,
							GUI.LABEL			:	description,
							GUI.DATA_WRAPPER	:	counterConfigData[counter]
						};
	}
	// \see GUI.ContextMenuTrait
	window.contextMenuProvider += menuEntries;

	rebuildLabels();
	window += page;

	return window;
};

return plugin;

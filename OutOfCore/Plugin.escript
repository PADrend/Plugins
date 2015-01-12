/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/**
 *	[Plugin:OutOfCore] OutOfCore/Plugin.escript
 *	2011-03-08	Benjamin Eikel	Creation.
 */

var plugin = new Plugin({
			Plugin.NAME : "OutOfCore",
			Plugin.VERSION : "1.0",
			Plugin.DESCRIPTION : "Display status information for the MinSG out-of-core system. When this plug-in is loaded, the out-of-core system is activated.",
			Plugin.AUTHORS : "Benjamin Eikel",
			Plugin.OWNER : "Benjamin Eikel",
			Plugin.REQUIRES : []
});

plugin.init @(override) := fn() {
	if(!MinSG.isSet($OutOfCore)) {
		out("MinSG::OutOfCore not supported. Did you compile with MINSG_EXT_OUTOFCORE defined?\n");
		return false;
	}
	{ /// Register ExtensionPointHandler:
		registerExtension('PADrend_Init', this -> this.ex_Init);
		registerExtension('PADrend_Init', this -> fn() {
			gui.registerComponentProvider('PADrend_PluginsMenu.outOfCore', {
				GUI.LABEL		:	"OutOfCore",
				GUI.ON_CLICK	:	this -> this.createNewWindow
			});
		});
	}
	return true;
};

plugin.ex_Init := fn() {
	// Activate the out-of-core system.
	MinSG.OutOfCore.setUp(GLOBALS.frameContext);
	
	// Add the out-of-core cache levels.
	var configString = 'OutOfCore.CacheLevel';
	setConfigInfo("OutOfCore", "Cache level configuration (0 is the lowest, 7 is the highest cache level)");
	for(var i = 0; i < 8; ++i) {
		setConfigInfo(configString + i, "Type (deactivated = 0, FileSystem = 1, Files = 2, MainMemory = 3, GraphicsMemory = 4) and size (in MiB) of cache level " + i);
		var cacheLevelType = systemConfig.getValue(configString + i + ".type", i == 0 ? 1 : 0);
		if(cacheLevelType == 0) {
			break;
		}
		var cacheLevelSize = systemConfig.getValue(configString + i + ".size", 0);
		MinSG.OutOfCore.addCacheLevel(cacheLevelType, cacheLevelSize);
	}
};

plugin.createNewWindow := fn() {
	var window = gui.createWindow(380, 200, "MinSG::OutOfCore statistics", GUI.ONE_TIME_WINDOW);
	window.setPosition(5, 25);

	var panelContents = [
			"Level",
			{GUI.TYPE : GUI.TYPE_NEXT_COLUMN},
			"Mem. Used\n[MiB]",
			{GUI.TYPE : GUI.TYPE_NEXT_COLUMN},
			"Mem. Overall\n[MiB]",
			{GUI.TYPE : GUI.TYPE_NEXT_COLUMN},
			"Fill Level\n[%]",
			{GUI.TYPE : GUI.TYPE_NEXT_COLUMN},
			"Stored\nObjects",
			{GUI.TYPE : GUI.TYPE_NEXT_COLUMN},
			{GUI.TYPE : GUI.TYPE_NEXT_COLUMN},
			"Last Work\n[ms]",
			
			{GUI.TYPE : GUI.TYPE_NEXT_ROW}
	];
	
	for(var level = 7; level >= 0; --level) {
		panelContents += {
			GUI.TYPE				:	GUI.TYPE_NUMBER, 
			GUI.DATA_VALUE			:	level, 
			GUI.WIDTH				:	25, 
			GUI.FLAGS				:	GUI.LOCKED
		};
		panelContents += {GUI.TYPE : GUI.TYPE_NEXT_COLUMN};
		var usedMemory = DataWrapper.createFromValue(0);
		panelContents += {
			GUI.TYPE				:	GUI.TYPE_NUMBER, 
			GUI.DATA_WRAPPER		:	usedMemory,
			GUI.WIDTH				:	75, 
			GUI.FLAGS				:	GUI.LOCKED
		};
		panelContents += {GUI.TYPE : GUI.TYPE_NEXT_COLUMN};
		var overallMemory = DataWrapper.createFromValue(0);
		panelContents += {
			GUI.TYPE				:	GUI.TYPE_NUMBER, 
			GUI.DATA_WRAPPER		:	overallMemory,
			GUI.WIDTH				:	75, 
			GUI.FLAGS				:	GUI.LOCKED
		};
		panelContents += {GUI.TYPE : GUI.TYPE_NEXT_COLUMN};
		var fillLevel = DataWrapper.createFromValue(100);
		panelContents += {
			GUI.TYPE				:	GUI.TYPE_NUMBER, 
			GUI.DATA_WRAPPER		:	fillLevel,
			GUI.WIDTH				:	60, 
			GUI.FLAGS				:	GUI.LOCKED
		};
		panelContents += {GUI.TYPE : GUI.TYPE_NEXT_COLUMN};
		var objects = DataWrapper.createFromValue(0);
		panelContents += {
			GUI.TYPE				:	GUI.TYPE_NUMBER, 
			GUI.DATA_WRAPPER		:	objects,
			GUI.WIDTH				:	60, 
			GUI.FLAGS				:	GUI.LOCKED
		};
		panelContents += {GUI.TYPE : GUI.TYPE_NEXT_COLUMN};
		var lastWorkDuration = DataWrapper.createFromValue(0.0);
		panelContents += {
			GUI.TYPE				:	GUI.TYPE_NUMBER, 
			GUI.DATA_WRAPPER		:	lastWorkDuration,
			GUI.WIDTH				:	60, 
			GUI.FLAGS				:	GUI.LOCKED
		};

		panelContents += {GUI.TYPE : GUI.TYPE_NEXT_ROW};

		registerExtension('PADrend_AfterRendering', [window, level, 
							usedMemory, overallMemory, fillLevel,
							objects, lastWorkDuration]=>fn(window, level,
														usedMemory, overallMemory, fillLevel,
														objects, lastWorkDuration, ...) {
			if(window.isDestroyed()) {
				return Extension.REMOVE_EXTENSION;
			}
			var levelStats = MinSG.OutOfCore.getStatisticsForLevel(level);
			if(!levelStats) {
				return;
			}

			usedMemory(levelStats.usedMemory);
			overallMemory(levelStats.overallMemory);
			if(levelStats.overallMemory > 0) {
				fillLevel(100.0 * (levelStats.usedMemory / levelStats.overallMemory));
			}
			objects(levelStats.objects);
			lastWorkDuration(levelStats.lastWorkDuration);
		});
	}

	panelContents += {
		GUI.LABEL			:	"Missing Mode",
		GUI.TOOLTIP			:	"Mode for cache objects that are not in memory.",
		GUI.TYPE			:	GUI.TYPE_SELECT,
		GUI.OPTIONS			:	[
									[MinSG.OutOfCore.MISSINGMODE_NOWAITDONOTHING, "No Wait, Do Nothing"],
									[MinSG.OutOfCore.MISSINGMODE_NOWAITDISPLAYCOLOREDBOX, "No Wait, Display Colored Box"],
									[MinSG.OutOfCore.MISSINGMODE_NOWAITDISPLAYDEPTHBOX, "No Wait, Display Depth Box"],
									[MinSG.OutOfCore.MISSINGMODE_WAITDISPLAY, "Wait, Display"]
								],
		GUI.DATA_WRAPPER	:	DataWrapper.createFromFunctions(MinSG.OutOfCore.getMissingMode, MinSG.OutOfCore.setMissingMode)
	};

	window += {
		GUI.TYPE		:	GUI.TYPE_CONTAINER,
		GUI.LAYOUT		:	GUI.LAYOUT_FLOW,
		GUI.SIZE		:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_FILL_ABS, 0, 0],
		GUI.CONTENTS	:	panelContents
	};

	return window;
};

return plugin;

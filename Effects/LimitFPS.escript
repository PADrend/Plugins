/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var plugin = new Plugin({
			Plugin.NAME : "Effects_LimitFPS",
			Plugin.VERSION : "1.0",
			Plugin.DESCRIPTION : "Limit the fps to a given value.",
			Plugin.AUTHORS : "Claudius Jaehn, Benjamin Eikel",
			Plugin.OWNER : "All",
			Plugin.REQUIRES : ['PADrend','PADrend/GUI','PADrend/EventLoop']
});

plugin.init := fn() {
	var fps = DataWrapper.createFromConfig(systemConfig, 'Effects.LimitFPS.fps', 25);

	var enabled = DataWrapper.createFromConfig(systemConfig, 'Effects.LimitFPS.enabled', false);
	enabled.onDataChanged += [fps] => fn(DataWrapper fps, value) {
		if(value) {
			registerExtension(
				'PADrend_AfterFrame', 
				[this, fps] => fn(DataWrapper enabled, DataWrapper fps) {
					var timer = new Util.Timer;
					while(enabled()) {
						// render next frame
						yield;

						// wait
						var pause = 1.0 / [fps(), 1].max();
						while(timer.getSeconds() < pause);
						timer.reset();
					}
					return Extension.REMOVE_EXTENSION;
				},
				Extension.LOW_PRIORITY
			);
		}
	};
	enabled.forceRefresh();

	registerExtension('PADrend_Init', [enabled, fps] => fn(enabled, fps) {
		gui.registerComponentProvider('Effects_MiscEffectsMenu.limitFps', [
			{
				GUI.TYPE			:	GUI.TYPE_BOOL,
				GUI.LABEL			:	"Limit fps",
				GUI.TOOLTIP			:	"When enabled, do busy waiting after the frame\nin order to reach the specified frame rate.",
				GUI.DATA_WRAPPER 	:	enabled
			},
			{
				GUI.TYPE			:	GUI.TYPE_RANGE,
				GUI.TOOLTIP			:	"Fps",
				GUI.TOOLTIP			:	"Target frame rate in frames per second (fps).",
				GUI.RANGE			:	[1,100],
				GUI.RANGE_STEP_SIZE	:	1,
				GUI.DATA_WRAPPER	:	fps
			},
			'----'
		]);
	});

	return true;
};

return plugin;

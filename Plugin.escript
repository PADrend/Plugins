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
	Plugin.VERSION			:	0.4,
	Plugin.AUTHORS			:	"Sascha Brandt, Claudius Jaehn",
	Plugin.OWNER			:	"Sascha Brandt",
	Plugin.LICENSE			:	"Proprietary",
	Plugin.REQUIRES			:	['NodeEditor'],
	Plugin.EXTENSION_POINTS	:	[]
});

plugin.init := fn() {
	PADrend.SceneManagement.addSearchPath(__DIR__ + "/resources/shader/");
	
	module.on('PADrend/gui', fn(gui) {
		Std.module('BlueSurfels/GUI/SurfelGUI').initGUI(gui);
		Std.module('BlueSurfels/GUI/SurfelRendererGUI').initGUI(gui);
	});

	Util.registerExtension('PADrend_Init',this->fn() {
		Std.module('BlueSurfels/Tools/SurfelDebugRenderer');
		Std.module('BlueSurfels/Sampler/GreedyCluster');
		Std.module('BlueSurfels/Sampler/ProgressiveBlueSurfels');
		Std.module('BlueSurfels/Sampler/RandomSampler');
	});
	
	return true;
};

return plugin;
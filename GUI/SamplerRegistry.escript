/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
static samplerRegistry = new Map;  // samplerName -> sampler
static samplerGUIRegistry = new Map; // samplerName -> guiProvider(obj)

static registry = new Namespace;

registry.registerSampler := fn(sampler, String displayableName=""){
	if(displayableName.empty())
		displayableName = sampler._printableName;
	samplerRegistry[displayableName] = sampler;
};

registry.registerSamplerGUI := fn(sampler, provider) {
	Std.Traits.requireTrait(provider, Std.Traits.CallableTrait);
	samplerGUIRegistry[sampler._printableName] = provider;
};

registry.getSamplers := fn() { return samplerRegistry.clone(); };
registry.getSampler := fn(samplerName){ return samplerRegistry[samplerName]; };
registry.getGUIProvider := fn(samplerName){ return samplerGUIRegistry[samplerName]; };


registry.applyConfig := fn(sampler, config) {
	applyCommonConfig(sampler, config);
	samplerConfigRegistry[sampler._printableName](sampler, config);
};
registry.getCachedConfig := fn() {
	static config;
	@(once) {
		config = new ExtObject({
			$samplerName : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.sampler','ProgressiveSampler'),
			$seed : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.seed', 0),
			$targetCount : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.targetCount', 10000),
			$samplesPerRound : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.samplesPerRound', 200),
		});
	}
	return config;
};

static applyCommonConfig = fn(sampler, config) {
	sampler.setSeed(config.seed());
	sampler.setTargetCount(config.targetCount());
};
registry.getCommonConfigGUI := fn(config) {
	return [
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Target Surfels",
			GUI.RANGE : [0,100000],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : config.targetCount,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Seed",
			GUI.RANGE : [0,10000],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : config.seed,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
    { GUI.TYPE : GUI.TYPE_NEXT_ROW },
	];
};

// -----------------------------------------------------------------------
// MinSG.BlueSurfels.ProgressiveSampler

registry.registerSampler(new MinSG.BlueSurfels.ProgressiveSampler);
registry.registerSamplerConfig(MinSG.BlueSurfels.ProgressiveSampler, fn(sampler, config) {
	sampler.setSamplesPerRound(config.samplesPerRound());
});
registry.registerSamplerGUI(MinSG.BlueSurfels.ProgressiveSampler, fn(config) {
	var entries = registry.getCommonConfigGUI(config);
	entries += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "Samples per round",
		GUI.RANGE : [0,1000],
		GUI.RANGE_STEP_SIZE : 1,
		GUI.DATA_WRAPPER : config.samplesPerRound,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
	};
	return entries;
});

// -----------------------------------------------------------------------
// MinSG.BlueSurfels.RandomSampler

registry.registerSampler(new MinSG.BlueSurfels.RandomSampler);
registry.registerSamplerConfig(MinSG.BlueSurfels.RandomSampler, fn(sampler, config) { });
registry.registerSamplerGUI(MinSG.BlueSurfels.RandomSampler, fn(config) {
	return registry.getCommonConfigGUI(config);
});

// -----------------------------------------------------------------------
// MinSG.BlueSurfels.GreedyCluster

registry.registerSampler(new MinSG.BlueSurfels.GreedyCluster);
registry.registerSamplerConfig(MinSG.BlueSurfels.GreedyCluster, fn(sampler, config) { });
registry.registerSamplerGUI(MinSG.BlueSurfels.GreedyCluster, fn(config) {
	return registry.getCommonConfigGUI(config);
});

return registry;

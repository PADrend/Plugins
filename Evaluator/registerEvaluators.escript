/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2008-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010-2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*!
 *	[Plugin:Evaluator] Evaluator/Evaluators.escript
 *	EScript extensions for different Evaluator implementations (GUI/Serialization/...)
 */

module('./extendEvaluator');

static CONFIG_PREFIX = 'Evaluator_Config_';

// -------------------------------------------------------------------------------------------------------------------------------------------------
// OverdrawFactorEvaluator

module.on('PADrend/gui', fn(gui){
	gui.register( CONFIG_PREFIX + MinSG.OverdrawFactorEvaluator.toString(), fn(evaluator){
		var entries = gui.createComponents( {
				GUI.TYPE : GUI.TYPE_COMPONENTS,
				GUI.PROVIDER : 	CONFIG_PREFIX + MinSG.OverdrawFactorEvaluator.getBaseType().toString(), 
				GUI.CONTEXT : evaluator
		});
		var quantileDataWrapper = DataWrapper.createFromFunctions(	evaluator -> evaluator.getResultQuantile,
																	evaluator -> evaluator.setResultQuantile);
		entries += {
			GUI.TYPE			:	GUI.TYPE_RANGE,
			GUI.LABEL			:	"Result quantile",
			GUI.TOOLTIP			:	"The quantile of the values in the image that is returned as result.",
			GUI.RANGE			:	[0, 1],
			GUI.RANGE_STEPS		:	20,
			GUI.DATA_WRAPPER	:	quantileDataWrapper,
			GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		entries += GUI.NEXT_ROW;

		var ignoreZeroDataWrapper = DataWrapper.createFromFunctions(evaluator -> evaluator.areZeroValuesIgnored,
																	evaluator -> fn(data) {
																		if(data) {
																			this.ignoreZeroValues();
																		} else {
																			this.keepZeroValues();
																		}
																	});
		entries += {
			GUI.TYPE			:	GUI.TYPE_BOOL,
			GUI.LABEL			:	"Ignore zero values",
			GUI.TOOLTIP			:	"If checked, ignore zero values for the calculation of the quantile.",
			GUI.DATA_WRAPPER	:	ignoreZeroDataWrapper,
			GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		entries += GUI.NEXT_ROW;

		return entries;
	});
});
	

// -------------------------------------------------------------------------------------------------------------------------------------------------
// StatsEvaluator

module.on('PADrend/gui', fn(gui){
	gui.register( CONFIG_PREFIX + MinSG.StatsEvaluator.toString(), fn(evaluator){
		var entries = gui.createComponents( {
				GUI.TYPE : GUI.TYPE_COMPONENTS,
				GUI.PROVIDER : 	CONFIG_PREFIX + MinSG.StatsEvaluator.getBaseType().toString(), 
				GUI.CONTEXT : evaluator
		});
		return entries.append([	
			{
				GUI.TYPE				:	GUI.TYPE_NUMBER,
				GUI.LABEL				:	"Iterations:",
				GUI.TOOLTIP				:	"If iterations = 2, the second value is used. If iterations > 2, the median is used.",
				GUI.DATA_PROVIDER		:	evaluator -> evaluator.getNumberOfIterations,
				GUI.ON_DATA_CHANGED		:	evaluator -> fn(data) {
												this.setNumberOfIterations(data);
												this.update();
											},
				GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE				:	GUI.TYPE_SELECT,
				GUI.LABEL				:	"Stats:",
				GUI.OPTIONS				:	{
					var stats = [];
					for(var counter = 0; counter < PADrend.frameStatistics.getNumCounters(); ++counter)
						stats += [counter, PADrend.frameStatistics.getDescription(counter)];
					stats;
				},
				GUI.DATA_PROVIDER		:	evaluator -> evaluator.getStatIndex,
				GUI.ON_DATA_CHANGED		:	evaluator -> fn(data) {
												this.setStatIndex(data);
												this.update();
											},
				GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE				:	GUI.TYPE_BOOL,
				GUI.LABEL				:	"Call glFinish",
				GUI.TOOLTIP				:	"If checked, call glFinish() after each measurement.",
				GUI.DATA_PROVIDER		:	evaluator -> evaluator.getCallGlFinish,
				GUI.ON_DATA_CHANGED		:	evaluator -> fn(data) {
												this.setCallGlFinish(data);
												this.update();
											},
				GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
			},
			GUI.NEXT_ROW,
		]);
	});
});


//! MinSG.StatsEvaluator ---|> MinSG.Evaluator
MinSG.StatsEvaluator.createName @(override) ::= fn() {
	return this.getEvaluatorTypeName() + " (" +
			PADrend.frameStatistics.getDescription(this.getStatIndex()) + ", " +
			this.getNumberOfIterations() + " iter, " + 
			"glFinish=" + this.getCallGlFinish() + ", " + 
			this.directionPresetName()+", "+
			(this.getMode() == MinSG.Evaluator.DIRECTION_VALUES ? "directional" : "single") + ")";
};


PADrend.Serialization.registerType( MinSG.StatsEvaluator, "MinSG.StatsEvaluator")
	.initFrom( PADrend.Serialization.getTypeHandler(MinSG.Evaluator))
	.addDescriber( fn(ctxt,MinSG.StatsEvaluator obj,Map d){
		d['iterations'] =  obj.getNumberOfIterations();
		d['statId'] =  obj.getStatIndex();
		d['useGLFinish'] =  obj.getCallGlFinish();
	})
	.addInitializer( fn(ctxt,MinSG.StatsEvaluator obj,Map d){
		obj.setNumberOfIterations(d['iterations']);
		obj.setStatIndex(d['statId']);
		obj.setCallGlFinish(d['useGLFinish']);
	});



// -------------------------------------------------------------------------------------------------------------------------------------------------
// VisibilityEvaluator

module.on('PADrend/gui', fn(gui){
	gui.register( CONFIG_PREFIX + MinSG.VisibilityEvaluator.toString(), fn(evaluator){
		var entries = gui.createComponents( {
				GUI.TYPE : GUI.TYPE_COMPONENTS,
				GUI.PROVIDER : 	CONFIG_PREFIX + MinSG.VisibilityEvaluator.getBaseType().toString(), 
				GUI.CONTEXT : evaluator
		});
		entries +=	{
			GUI.TYPE				:	GUI.TYPE_SELECT,
			GUI.LABEL				:	"Operation mode:",
			GUI.OPTIONS				:	[
											[false, "Count visible objects"],
											[true, "Count polygons in visible objects"]
										],
			GUI.DATA_PROVIDER		:	evaluator -> evaluator.doesCountPolygons,
			GUI.ON_DATA_CHANGED		:	evaluator -> fn(data) {
											this.setCountPolygons(data);
											this.update();
										},
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		return entries;
	});
});

/*! MinSG.VisibilityEvaluator ---|> MinSG.Evaluator */
MinSG.VisibilityEvaluator.createName @(override) ::= fn(){
	return this.getEvaluatorTypeName()+" ("+ (doesCountPolygons() ? "Number of polygons" : "Number of objects")+")";
};

PADrend.Serialization.registerType( MinSG.VisibilityEvaluator, "MinSG.VisibilityEvaluator")
	.initFrom( PADrend.Serialization.getTypeHandler(MinSG.Evaluator))
	.addDescriber( fn(ctxt,MinSG.VisibilityEvaluator obj,Map d){
		d['countPolygons'] =  obj.doesCountPolygons();
	})
	.addInitializer( fn(ctxt,MinSG.VisibilityEvaluator obj,Map d){
		obj.setCountPolygons( d['countPolygons'] );
	});

return true;

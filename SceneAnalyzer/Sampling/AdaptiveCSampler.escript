/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2012,2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static CSamplingContext = module('./CSamplingContext');
static CSampler = module('./CSampler');

/****
 **	[Plugin:GASP] GASP/Sampling/AdaptiveCSampler.escript
 ** 2010-05 Claudius
 **/
var sampler = new CSampler;

sampler.name = "Adaptive Sampler";


sampler.settings := new ExtObject({
	$breakExpression : (new Std.DataWrapper( "" )).setOptions([ "ctxt.sampleCount>500","ctxt.sampleCount>1000"]),
	$numberOfSamplesExpression : (new Std.DataWrapper( "" )).setOptions(["region.getSize().sqrt().floor()*0.1+1","region.getDiameter().floor()*0.1+1"]),
	$qualityExpression : (new Std.DataWrapper( "" )).setOptions([ "numSamples / (diff*region.getDiameter())" ]),
	$sampleExpression1 : (new Std.DataWrapper( "" )).setOptions([ "getRandomPositions2(ctxt,region,numNewSamples)" ]),
	$sampleExpression2 : (new Std.DataWrapper( "" )).setOptions([ "getRegionCorners(newRegion)","[]"]),
});

sampler.presetManager := new (Std.module('LibGUIExt/PresetManager'))( PADrend.configCache,'SceneAnalyzer.cSampler',sampler.settings );



/*!	---|> CSampler */
sampler.init := fn(	CSamplingContext ctxt) {
	out("Adaptive init...\n");

	ctxt.regionQueue:=new PriorityQueue(
			fn(MinSG.ValuatedRegionNode a,MinSG.ValuatedRegionNode b){
				return a.quality<b.quality;
			});

	var rootNode=ctxt.gasp.rootNode;
	initRegion(rootNode);
	ctxt.regionQueue+=rootNode;

	ctxt.sampleCount:=0;
	ctxt.cacheHitCount:=0;

	ctxt.breakExpression_fun := eval("fn(ctxt){ return ("+settings.breakExpression()+"); };" );
	ctxt.numberOfSamplesExpression_fun := eval("fn(ctxt,region){ return ("+settings.numberOfSamplesExpression()+"); };" );
	
	ctxt.qualityExpression_fun := eval("fn(ctxt,region,numSamples,min,max,diff){ return ("+settings.qualityExpression()+"); };");
	ctxt.sampleExpression1_fun := eval("fn(ctxt,region,numNewSamples){ return ("+settings.sampleExpression1()+"); };");
	ctxt.sampleExpression2_fun := eval("fn(ctxt,newRegion){ return ("+settings.sampleExpression2()+"); };");

	if(!ctxt.getAttribute('resultCache'))
		ctxt.resultCache:=new Map();

	return true;
};

/*! ---|> CSampler */
sampler.createConfigPanel :=fn(){
	var p=gui.create({
		GUI.TYPE : GUI.TYPE_PANEL,
		GUI.FLAGS : GUI.AUTO_LAYOUT|GUI.BORDER,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -20 ,200 ]
	});
	p+="*Adaptive sampler*";
		
	p++;
	presetManager.createGUI(p);

	p++;
	// -------------------
	
	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Break expression",
		GUI.DATA_WRAPPER : settings.breakExpression,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -20 ,15 ],
		GUI.TOOLTIP : "Available parameters: (ctxt)",
	};

	p++;

	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Region sample count",
		GUI.DATA_WRAPPER : settings.numberOfSamplesExpression,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -20 ,15 ],
		GUI.TOOLTIP : "Available parameters: (ctxt,region)",
	};
	p++;
	
	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Region quality",
		GUI.DATA_WRAPPER : settings.qualityExpression,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -20 ,15 ],
		GUI.TOOLTIP : "Available parameters: (ctxt,region,numSamples,min,max,diff)",
	};
	
	p++;
		
	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Sampling strategy",
		GUI.DATA_WRAPPER : settings.sampleExpression1,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -20 ,15 ],
		GUI.TOOLTIP : "Available parameters: (ctxt,region,numNewSamples)"
	};

	p++;
		
	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Sampling strategy (new regions)",
		GUI.DATA_WRAPPER : settings.sampleExpression2,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -20 ,15 ],
		GUI.TOOLTIP : "Available parameters: (ctxt,newRegion)",
	};
	
	p++;

	return p;
};

/*! ---|> CSampler
	@return true if finished. */
sampler.step := fn(CSamplingContext ctxt){
//	out("Adaptive sample sample...\n");

	if(ctxt.regionQueue.empty() || ctxt.breakExpression_fun(ctxt))
		return true;


	var region=ctxt.regionQueue.extract();
	if(!region.isLeaf()){
		foreach( MinSG.getChildNodes(region) as var child){
			ctxt.regionQueue+=child;
		}
		return false;
	}
//
	out("\rSamples: ",ctxt.sampleCount,"\tCacheHits: ",ctxt.cacheHitCount,"\tQSize: ",ctxt.regionQueue.count()," \t[",ctxt.duration,"]    ");

	// calculate number of samples for that region
	var numSamples=ctxt.numberOfSamplesExpression_fun(ctxt,region);
	if(region.getSize()==1)
		numSamples=1;

	if(region.samples.count() < numSamples){
		var numNewSamples = numSamples+1-region.samples.count();
		
		var positions = (this->ctxt.sampleExpression1_fun) (ctxt,region,numNewSamples);
		ctxt.sampleCount+=this.performMeasurements(ctxt,region, positions);

		var mergedValue=ctxt.evaluator.mergeValues(region.samples);
		region.setValue(mergedValue.valueVec);
//		print_r(mergedValue.valueVec);
//		out("\n");
		region.quality=calculateRegionQuality(ctxt, region, mergedValue);
		ctxt.regionQueue+=region;

//		var color=region.quality*0.1;
		region.clearColors();
//		region.addColor(1-(color),(color>0.5 ? (color-0.5) : 0),0,0.2);
		ctxt.gasp.onNewRegions([region]);
	}else if(numSamples>1) {
		// Split region
		region.splitUp(region.getXResolution() > 1 ? 2 : 1, region.getYResolution() > 1 ? 2 : 1, region.getZResolution() > 1 ? 2 : 1);
		region.clearColors();
		var newRegions=[];
		foreach(MinSG.getChildNodes(region) as var newRegion){
			newRegions+=newRegion;

			initRegion(newRegion);

			foreach(region.positions as var index,var pos){
				if(newRegion.getWorldBB().contains(pos)){
					newRegion.samples+=region.samples[index].clone();
					newRegion.positions+=pos.clone();
				}
			}

			var positions = (this->ctxt.sampleExpression2_fun)(ctxt,newRegion);
			ctxt.sampleCount+=this.performMeasurements(ctxt,newRegion, positions);
			var mergedValue=ctxt.evaluator.mergeValues(newRegion.samples);
			
			newRegion.setValue(mergedValue.valueVec);

			newRegion.quality=calculateRegionQuality(ctxt, newRegion, mergedValue);

			ctxt.regionQueue+=newRegion;

//			var color=newRegion.quality*0.1;
			newRegion.clearColors();
//			newRegion.addColor(1-(color),(color>0.5 ? (color-0.5) : 0),0,0.1);
		}
		ctxt.gasp.onNewRegions(newRegions);
	}
	return false;
};

/*! (internal) */
sampler.initRegion:=fn(MinSG.ValuatedRegionNode region){
	region.quality:=-100000;
	region.samples:=[];
	region.positions:=[];
};

/*! (internal)
	Perform a measurement for each position in _positions_.
	The results are added to region.samples.
	\note The results are cached.
	\note uses GASP.measure(...)
	\return number of measurements (without the chached ones)	*/
sampler.performMeasurements:=fn(CSamplingContext ctxt,MinSG.ValuatedRegionNode region,Array positions){
	showWaitingScreen( true );
	
	var measureCount=0;
	foreach(positions as var pos){ // measure (or lookup old result from cache)
		var results;
		var key=":"+ctxt.evaluator+pos;
		var cacheValue=ctxt.resultCache[key];
		if(cacheValue){
			ctxt.cacheHitCount++;
			results=cacheValue[0];
		}else{
			results=ctxt.evaluator.cubeMeasure(ctxt.sceneRoot,pos);
			ctxt.resultCache[key]=[results];
			measureCount++;
		}
		region.samples.pushBack(results);
		region.positions.pushBack(pos);
		
		ctxt.gasp.storeSample(pos,results.clone());
//        out("\n");
	}
	return measureCount;
};

/*!	Calculate the quality for the given region.
	By default, the quality is the result of the qualityExpression.
	\return The quality value as Number.	*/
sampler.calculateRegionQuality:=fn(CSamplingContext ctxt, MinSG.ValuatedRegionNode region, mergedValues){
	
	var diff=mergedValues.diffRatioVec.max();
	if(!diff || diff==0)
		diff=0.01;

	var max=mergedValues.maxVec.max();
	var min=mergedValues.minVec.min();
	var numSamples=region.samples.count();

	var quality=0;
	try{
		quality = ctxt.qualityExpression_fun( ctxt,region,numSamples,min,max,diff );
	}catch(e){
		print_r(mergedValues.diffRatioVec);
		out(e);
	}
	return quality;
};


return sampler;
// ------------------------------------------------------------------

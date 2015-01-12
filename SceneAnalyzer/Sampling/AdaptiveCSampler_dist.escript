/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012,2015 Claudius Jähn <claudius@uni-paderborn.de>
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
 **	[Plugin:GASP] GASP/Sampling/AdaptiveCSampler_dist.escript
 ** 2011-05 Claudius
 **/

module('./Sampling/ConcurrentCSampler');

//! Sampler ---|> ConcurrentCSampler
var Sampler = new Type(ConcurrentCSampler);

Sampler.name = "Adaptive Sampler(distributed)";

Sampler.breakExpression := "ctxt.sampleCount>500";
Sampler.numberOfSamplesExpression := "region.getSize().sqrt().floor()*0.1+1";
Sampler.qualityExpression := "numSamples / (diff*region.getDiameter())";
Sampler.sampleExpression1 := "getRandomPositions2(ctxt,region,numNewSamples)";
Sampler.sampleExpression2 := "getRegionCorners(newRegion)";

Sampler.regionCounter ::= 0; //< internally used to assign unique ids to regions

/*!	---|> CSampler */
Sampler.init @(override) ::= fn( CSamplingContext ctxt) {
	out("Adaptive init...\n");

	var rootNode=ctxt.gasp.rootNode;
	initRegion(rootNode);

	ctxt.sampleCount:=0;
	ctxt.cacheHitCount:=0;

	ctxt.breakExpression:=parse(breakExpression+";");
	ctxt.numberOfSamplesExpression:=parse(numberOfSamplesExpression+";"); //*2
	ctxt.qualityExpression:=parse(qualityExpression+";");
	ctxt.sampleExpression1:=parse(sampleExpression1+";");
	ctxt.sampleExpression2:=parse(sampleExpression2+";");

	if(!ctxt.getAttribute( $resultCache ))
		ctxt.resultCache:=new Map();

	if(!ctxt.getAttribute( $activeRegions ))
		ctxt.activeRegions := new Map();  //! id --> region

	return true;
};

/*! ---|> CSampler */
Sampler.createConfigPanel ::= fn(){
	var p=gui.create({
		GUI.TYPE : GUI.TYPE_PANEL,
		GUI.FLAGS : GUI.AUTO_LAYOUT|GUI.BORDER,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -20 ,200 ]
	});
	p+="*Adaptive sampler*";
	
	p++;
	
	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Break expression",
		GUI.DATA_OBJECT : this,
		GUI.DATA_ATTRIBUTE : $breakExpression,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -20 ,15 ]
	};
	
	p++;

	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Region sample count",
		GUI.DATA_OBJECT : this,
		GUI.DATA_ATTRIBUTE : $numberOfSamplesExpression,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -20 ,15 ]
	};
	
	p++;
	
	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Region quality",
		GUI.DATA_OBJECT : this,
		GUI.DATA_ATTRIBUTE : $qualityExpression,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -20 ,15 ]
	};
	
	p++;
	
	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Initial samples",
		GUI.DATA_OBJECT : this,
		GUI.DATA_ATTRIBUTE : $sampleExpression2,
		GUI.OPTIONS : [sampleExpression2,"[]"],
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -20 ,15 ]
	};
	
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Random samples",
		GUI.DATA_OBJECT : this,
		GUI.DATA_ATTRIBUTE : $sampleExpression1,
		GUI.OPTIONS : [sampleExpression1,"getRandomPositions(ctxt,region,numNewSamples)"],
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -20 ,15 ]
	};
	
	p++;
		


	return p;
};




/*! ---|> CSampler
	@return true if finished. */
Sampler.step ::= fn(CSamplingContext ctxt){
	static JobScheduling = Std.require('JobScheduling/JobScheduling');

//	out("Adaptive sample sample...\n");

	var shedulerId = "Sampling";
	JobScheduling.initScheduler(shedulerId,0,2);

	// recalculate leafs' quality and rebuild priority queue
	var regionQueue = new PriorityQueue(	fn(MinSG.ValuatedRegionNode a,MinSG.ValuatedRegionNode b){	return a.quality<b.quality;	}	);
	{
		out("Building priority queue...");
		var rootNode = ctxt.gasp.rootNode;
		initRegion(rootNode);
		
		var regions = [rootNode];
		while(!regions.empty()){
			var region = regions.popBack();
			if(!region.isLeaf()){
				foreach( MinSG.getChildNodes(region) as var child)
					regions+=child;
				continue;
			}else{
				var mergedValue=ctxt.evaluator.mergeValues(region.samples);
				region.quality = calculateRegionQuality(ctxt, region, mergedValue);
				regionQueue+=region;
			}
		}
		out("(starting with ",regionQueue.count()," regions)\n");
	}
	
	while(true){
				
		// -------------------------------------------------
		// while there are still active regions...
		if(!ctxt.activeRegions.empty()){

			var results = JobScheduling.fetchResults(shedulerId);
				
			// add sampling results to region
			foreach(results as var resultDescription){
				// add sample to region
				
				var results = resultDescription['results'];
				var position = resultDescription['position'];
				
				// store sample 
				ctxt.activeRegions[resultDescription['regionId']].samples[position] = results;
				
				// store sample in global point octree
				ctxt.gasp.storeSample(position,results.clone());				
			}

			// if further samples are still pending, wait...
			if(!JobScheduling.isSchedulerEmpty(shedulerId) ){
				yield;
				continue;
			}

			out("\nActive regions processed...\n");
			
			// update regions
			foreach(ctxt.activeRegions as var region){
				var mergedValue=ctxt.evaluator.mergeValues(region.samples);
				region.setValue(mergedValue.valueVec);
				region.quality = calculateRegionQuality(ctxt, region, mergedValue);
//				out("Quality:",region.quality,"\n");
				regionQueue+=region;

			}
	
			// clear active regions
			ctxt.activeRegions.clear();
		}
		
		// -------------------------------------------------

		// there are no active regions...
		{
			// finished?
			if( regionQueue.empty() || ctxt.breakExpression.execute()){
				break;
			}
		
			// extract the region with lowest quality from the regionQueue
			var region=regionQueue.extract();
			
			// region is inner node -> continue with its children (should not happen!) 
			if(!region.isLeaf()){
				foreach( MinSG.getChildNodes(region) as var child){
					regionQueue+=child;
				}
				continue;
			}
			
			// unsplittable? -> do nothing
			if(region.getSize()<=1){
				continue;
			}
			
			// split the region 
			region.splitUp(region.getXResolution() > 1 ? 2 : 1, region.getYResolution() > 1 ? 2 : 1, region.getZResolution() > 1 ? 2 : 1);
			region.clearColors();

			foreach(MinSG.getChildNodes(region) as var newRegion){
				ctxt.activeRegions[newRegion.toString()] = newRegion;

				initRegion(newRegion);

				// distribute samples to children
				foreach(region.samples as var position,var result){
					if(newRegion.getWorldBB().contains(position)){
						newRegion.samples[position.clone()] = result.clone();
					}
				}
				
				// get new sample positions
				var positions;
				{
					// calculate number of samples for that region
					
					var region = newRegion; // alias temp!!!!
					var numSamples = ctxt.numberOfSamplesExpression.execute();
					if(region.getSize()==1)
						numSamples=1;					
					
//					var positions = getRegionCorners(newRegion);
					positions = ctxt.sampleExpression2.execute();
					var numNewSamples = numSamples+1-positions.count();
//	//			
//					for(var i=0;i<numNewSamples;++i){
						positions.append( ctxt.sampleExpression1.execute());// getRandomPositions(ctxt,region,numNewSamples);
//						ctxt.sampleCount+=this.performMeasurements(ctxt,region, positions);
//					}
				}
				
				foreach(positions as var position){
					if(newRegion.samples[position]){
						ctxt.cacheHitCount++;
						continue;
					}
					JobScheduling.addJob(shedulerId , 
						[newRegion.toString(),ctxt.evaluator,position]=>fn(String regionId,MinSG.Evaluator evaluator,Geometry.Vec3 position){
							out(".");
							var results=evaluator.cubeMeasure(PADrend.getCurrentScene(),position);
							return { 'regionId' : regionId , 'results' : results , 'position': position } ;
						},
						2 // sec timeout
					);
					ctxt.sampleCount++;
				}
			}
			
//			ctxt.gasp.onNewRegions([regions]);
		}
		
		// else: add new sampling jobs
		yield;
	}
	
	
	JobScheduling.closeScheduler(shedulerId);
	out("Finished.\n");
	return true;
};


/*! (internal) */
Sampler.initRegion ::= fn(MinSG.ValuatedRegionNode region){
	region.quality:=-100000;
	region.samples:=new Map(); //! position -> result
};

/*!	Calculate the quality for the given region.
	By default, the quality is the result of the qualityExpression.
	\return The quality value as Number.	*/
Sampler.calculateRegionQuality ::= fn(CSamplingContext ctxt, MinSG.ValuatedRegionNode region, mergedValues){

	var diff=mergedValues.diffRatioVec.max();
	if(diff==0 || !diff)
		diff=0.01;
	var max=mergedValues.maxVec.max();
	var min=mergedValues.minVec.min();
	var numSamples=region.samples.count();

	var quality=0;
	try{
		quality=ctxt.qualityExpression.execute();
	}catch(e){
		print_r(mergedValues.diffRatioVec);
		out(e);
	}
	return quality;
};


return new Sampler();
// ------------------------------------------------------------------

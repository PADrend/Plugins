/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:GASP] GASP/Sampling/ObserverCSampler.escript
 ** 2010-05 Claudius
 **/
static GASP = module('../GASP');
static CSamplingContext = module('./CSamplingContext');
static CSampler = module('./CSampler');

var sampler = new CSampler;

sampler.name = "Observer Sampler";


sampler.config := new ExtObject({
//	$breakExpression : DataWrapper.createFromConfig( PADrend.configCache,'SceneAnalyzer.cSampler.break',"ctxt.sampleCount>500" ),
	$qualityExpression : DataWrapper.createFromConfig( PADrend.configCache,'SceneAnalyzer.cSampler.quality',"numSamples / (diff*region.getDiameter())" ),
});

sampler.activeContext := void;
sampler.handlerRegistered := false;

sampler.fbo := void;
sampler.fbo_renderBuffer := void;
sampler.fbo_depthBuffer := void;

/*!	---|> CSampler */
sampler.execute @(override) := fn(MinSG.Node sceneNode,
						MinSG.Evaluator evaluator,
						GASP gasp){

	if(activeContext){
		stop();
		return;
	}
	// ------

	// create fbo
	if(!fbo){
		fbo=new Rendering.FBO();

		renderingContext.pushAndSetFBO(fbo);
		fbo_renderBuffer=Rendering.createHDRTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight(),true);
		fbo.attachColorTexture(renderingContext,fbo_renderBuffer);
		fbo_depthBuffer=Rendering.createDepthTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight());
		fbo.attachDepthTexture(renderingContext,fbo_depthBuffer);
		out(fbo.getStatusMessage(renderingContext),"\n");
		renderingContext.popFBO();
	}

	// Create sampling context from gasp if necessary
	if(!gasp.getAttribute('_samplingContext') ||
			gasp._samplingContext.sampler != this ){
		gasp._samplingContext:=new CSamplingContext(sceneNode,evaluator,gasp,this);
	}

	// get sampling context
	var ctxt=gasp._samplingContext;

	// init data
	if(!this.init(ctxt))
		return;

	// register extensionPoint
	if(!handlerRegistered){
		registerExtension('PADrend_AfterRenderingPass',this->fn(...){
			if(activeContext){
				var c=PADrend.getCameraMover().getDolly();
				//c=camera;
				activeContext.observerPosition = c.getWorldOrigin();

				renderingContext.pushAndSetFBO(fbo);
				if(step(activeContext)){
					stop();
				}
				renderingContext.popFBO();
			}
		});
		handlerRegistered=true;
	}

	activeContext=ctxt;
	out("Sampling started!");
};

/*!	*/
sampler.stop:=fn(){
	if(activeContext){
		// set sampling description of the gasp
//		ctxt.description['duration'] = ctxt.duration;
		activeContext.gasp.applyDescription(activeContext.description);
		activeContext=void;

		out("Sampling stopped!\n");
	}
};

/*!	---|> CSampler */
sampler.init @(override) := fn(	CSamplingContext ctxt) {
	out("ObserverSampler init...\n");

//	ctxt.regionQueue:=new PriorityQueue(
//			fn(MinSG.ValuatedRegionNode a,MinSG.ValuatedRegionNode b){
//				return a.quality<b.quality;
//			});

	var rootNode=ctxt.gasp.rootNode;
	initRegion(rootNode);
//    ctxt.regionQueue+=rootNode;

	ctxt.sampleCount:=0;
	ctxt.cacheHitCount:=0;

	ctxt.qualityExpression_fun := eval("fn(ctxt,region,numSamples,min,max,diff){ return ("+config.qualityExpression()+"); };");
//	ctxt.qualityExpression:=parse(qualityExpression+";");

	if(!ctxt.getAttribute('resultCache'))
		ctxt.resultCache:=new Map();

	ctxt.observerPosition := new Geometry.Vec3(0,0,0);

	ctxt.activeRegions:=[];

	return true;
};

/*! ---|> CSampler */
sampler.createConfigPanel @(override) :=fn(){
	var p=gui.createPanel(400,100,GUI.AUTO_LAYOUT|GUI.BORDER);
	p+="*Observer sampler*";
	p.nextRow();
//	p+="Break expression";
//	p.nextColumn();
//	var tf=gui.createTextfield(250,15);
//	tf.connectToAttribute( this,'breakExpression');
//	p+=tf;
//	p.nextRow();
//
//	p+="Region sample count";
//	p.nextColumn();
//	tf=gui.createTextfield(250,15);
//	tf.connectToAttribute( this,'numberOfSamplesExpression');
//	p+=tf;
//	p.nextRow();

	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Region quality",
		GUI.DATA_WRAPPER : config.qualityExpression,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -20 ,15 ],
		GUI.TOOLTIP : "Available parameters: (ctxt,region,numSamples,min,max,diff)",
		GUI.OPTIONS : ["numSamples / (diff*region.getDiameter())"]
	};

	return p;
};

/*! ---|> CSampler
	@return true if finished. */
sampler.step @(override) := fn(CSamplingContext ctxt){
//	out("Observer sample sample...\n");

	// handle new region
	if( ctxt.activeRegions.empty() ){
		// select region to split
		//collectClosedNodesIntersectingBox(resizeRel
//		var regions=MinSG.collectClosedNodesAtPosition(ctxt.gasp.getRootNode(),ctxt.observerPosition);
		var regions=MinSG.collectClosedNodesIntersectingBox(ctxt.gasp.getRootNode(),new Geometry.Box(ctxt.observerPosition,0.5,0.5,0.5));
		if(regions.empty())
			return false;

		var region=regions[0];

		// random selection
		var counter=0;
		while(counter++ < 20){
			var bb=region.getWorldBB().resizeRel(2.1);
			regions=MinSG.collectClosedNodesIntersectingBox(ctxt.gasp.getRootNode(),bb);
			var weights=[];
			foreach(regions as var r)
				weights+=1.0/(r.quality+0.001);
			var index = Rand.categorial(weights);
			region=regions[index];
			if(region.getSize()<=1 || Rand.uniform(0,1)<0.5 ){ //
				continue;
			}
			break;
		}
		out( " steps:",counter," ");

		if(region.getSize() <= 1)
			return false;

		if(!region.isLeaf()){
			out(__FILE__,":",__LINE__,": Should not happen!\n");
			return false;
		}

		out(region.quality," ");

		region.splitUp(2, 2, 2);
		region.clearColors();
		var newRegions=MinSG.getChildNodes(region);
		foreach( newRegions as var newRegion){
			initRegion(newRegion);
			newRegion.pendingPositions.append(getRegionCorners(newRegion));

			// distribute old samples
			foreach(region.positions as var index,var pos){
				if(newRegion.getWorldBB().contains(pos)){
					newRegion.samples+=region.samples[index].clone();
					newRegion.positons+=region.positions[index].clone();
				}
			}
		}

		ctxt.activeRegions:=newRegions;
		return false;
	}else { // sample active region
		out(".");
		var region=ctxt.activeRegions.back();

		var actualMeasurementPerformed=false;

		while(!region.pendingPositions.empty()){
			var pos=region.pendingPositions.popBack();
			var i=this.performMeasurement(ctxt,region,pos );
			if(i>0){
				ctxt.sampleCount+=i;
				actualMeasurementPerformed=true;
				break;
			}
		}

		if(region.pendingPositions.empty()){
			var mergedValue=ctxt.evaluator.mergeValues(region.samples);
			region.setValue(mergedValue.valueVec);
			region.quality=calculateRegionQuality(ctxt, region, mergedValue);
//			ctxt.regionQueue+=region;

			var color=region.quality*0.01;
			region.clearColors();
			region.addColor(1-(color),(color>0.5 ? (color-0.5) : 0),0,0.2);
			
			ctxt.gasp.onNewRegions([region]);
			ctxt.activeRegions.popBack();
		}

		if(!actualMeasurementPerformed)
			(this->thisFn)(ctxt);


		return false;
	}
};

/*! (internal) */
sampler.initRegion:=fn(MinSG.ValuatedRegionNode region){
	region.quality:=-100000;
	region.samples:=[];
	region.positions:=[];
	region.pendingPositions:=[];
};

/*! (internal)
	Performs a measurement for the given position.
	The results are added to region.samples.
	\note The results are cached.
	\note uses GASP.measure(...)
	\note uses GASP.calculateRegionValue(...)
	\return 1 if really measured, 0 if value was cached	*/
sampler.performMeasurement:=fn(CSamplingContext ctxt,MinSG.ValuatedRegionNode region,Geometry.Vec3 pos){
	var measureCount=0;
	// measure (or lookup old result from cache)
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

	return measureCount;
};
/*!	Calculate the quality for the given region.
	By default, the quality is the result of the qualityExpression.
	\return The quality value as Number.	*/
sampler.calculateRegionQuality:=fn(CSamplingContext ctxt, MinSG.ValuatedRegionNode region, mergedValues){

	var diff=mergedValues.diffRatioVec.max();
	if(diff==0 || !diff)
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

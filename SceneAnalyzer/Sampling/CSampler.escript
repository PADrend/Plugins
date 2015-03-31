/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:GASP] GASP/Sampling/CSampler.escript
 ** 2010-05 Claudius
 ** Base class for gasp sampling algorithms
 ** TODO: camera.setAngle / screenRect /... /screenshot
 **/
static Listener = Std.module('LibUtilExt/deprecated/Listener');
Listener.CSAMPLER_STEP:='csampler_step';

// ------------------------------------------------------
// ------------------------------------------------------
static CSamplingContext = module('./CSamplingContext');
static GASP = module('../GASP');


static T = new Type;

/*! This should be set */
T.name := "CSampler";

/*!	---o
	@return true if ok. */
T.init ::= fn(CSamplingContext ctxt) {
	out("Init sampling context...");
	return true;
};

/*! ---o
	@return true if finished. */
T.step ::= fn(CSamplingContext ctxt){
	out("Sample...sample...sample...\n");
	return true;
};

//! ---o
T.createConfigPanel ::=fn(){
	var panel=gui.createPanel(100,100,GUI.AUTO_LAYOUT);
	panel+="";
	return panel();
};

// ----------
// Main

/*! ---o
	Perform the sampling process by repeatedly calling the step(...) method.
*/
T.execute ::= fn(MinSG.Node sceneNode,
						MinSG.Evaluator evaluator,
						GASP gasp){

	// Create sampling context from gasp if necessary
	if(!gasp.getAttribute($_samplingContext) ||
			gasp._samplingContext.sampler != this ){
		gasp._samplingContext:=new CSamplingContext(sceneNode,evaluator,gasp,this);
	}

	// get sampling context
	var ctxt=gasp._samplingContext;

	// init data
	if(!this.init(ctxt))
		return;

	// init time measurement
	var start=clock();
	var initialDuration=ctxt.duration;

	// main sampling loop
	while(true){
		// perform sampling step
		if(this.step(ctxt)){
			break;
		}
		ctxt.stepNum++;

		Listener.notify(Listener.CSAMPLER_STEP,ctxt);

		// todo!
		// display
//		if(!this.showMeasurements){
//			//    var cam=camera.clone();
//	//        var rect=new Geometry.Rect(screenRect.getX(),screenRect.getY(),screenRect.getWidth()/4,screenRect.getHeight()/4);
//	//        cam.setViewport(rect);
//			frameContext.setCamera(camera);
//			renderingContext.clearScreen(PADrend.bgColor);
//			sceneRoot.display(frameContext,PADrend.getRenderingFlags());
//
//			var c=GASPManager.getCurrentClassifiaction();
//			if(c)
//				c.display(frameContext);
//		}
		PADrend.SystemUI.swapBuffers();

		// handle user events
		var stop=false;
		PADrend.getEventQueue().process();
		while(PADrend.getEventQueue().getNumEventsAvailable() > 0) {
			var evt = PADrend.getEventQueue().popEvent();
			if (evt.type==Util.UI.EVENT_KEYBOARD && evt.pressed && (evt.key == Util.UI.KEY_ESCAPE || evt.key == Util.UI.KEY_SPACE) ) {
				stop=true;
				out("Break!\n");
				break;
			}
		}
		if(stop)
			break;

		// update duration (to always keep the context.duration up to date)
		ctxt.duration=initialDuration+clock()-start;
	}
	// calculate final duration
	ctxt.duration=initialDuration+clock()-start;

	// set sampling description of the gasp
	ctxt.description['duration'] = ctxt.duration;
	ctxt.description['evaluator'] = evaluator.createName();

	gasp.applyDescription(ctxt.description);
};

T.getConfigPanel ::= fn(){
	if(!getAttribute('_configPanel'))
		this._configPanel:=createConfigPanel();
	return _configPanel;
};

T.getName ::= fn(){	return name;	};


// -------------------------------
// internal helper


/*! (helper)
	Get _count_ many random points lying inside of the region.
	\return [Vec3*]	*/
T.getRandomPositions:=fn(CSamplingContext ctxt,MinSG.ValuatedRegionNode region, count) {
	var p=[];
	for(;count>0;count--){
		var x= Rand.equilikely(0,region.getXResolution()-1);
		var y= Rand.equilikely(0,region.getYResolution()-1);
		var z= Rand.equilikely(0,region.getZResolution()-1);
		p += region.getPosition(x,y,z);
	}
	return p;
};

/*! (helper)
	Get _count_ many random points lying inside of the region.
	\return [Vec3*]	*/
T.getRandomPositions2:=fn(CSamplingContext ctxt,MinSG.ValuatedRegionNode region, count,runs=200) {
	var newPoints=[];
	
	
	var newPointsSearchOctree = new Geometry.PointOctree(region.getBB(),1.0,10);
	
	for(;count>0;count--){
		var pos;
		var largestDistance = false;
		for(var run=0;run<runs;++run){
			var candidate = region.getPosition(Rand.uniform(0,region.getXResolution()-1),
										Rand.uniform(0,region.getYResolution()-1),
										Rand.uniform(0,region.getZResolution()-1));
			
			var closestOldNeighbour = ctxt.gasp.getClosestSample(candidate);
			var candidateDistance = closestOldNeighbour ? closestOldNeighbour.pos.distance(candidate) : false;
			
			if( candidateDistance && largestDistance && candidateDistance<largestDistance)
				continue;
			
			// search for the closest point of the new points
			var closestNewNeighbours = newPointsSearchOctree.getClosestPoints(candidate,1);
			if(!closestNewNeighbours.empty()){
				var d = candidate.distance(closestNewNeighbours[0].pos);
				if(!candidateDistance || d<candidateDistance)
					candidateDistance = d;
			} 
			if( candidateDistance && largestDistance && candidateDistance<largestDistance)
				continue;
			
			pos=candidate;
			largestDistance=candidateDistance;
		}
		newPoints+=pos;
		newPointsSearchOctree.insert(pos,true);

	}
	return newPoints;
};



/*! (helper)
	Get the corners of the region .
	\return [Vec3*]	*/
T.getRegionCorners:=fn(MinSG.ValuatedRegionNode region) {
	var p=[];
	var xs=(region.getXResolution()>1) ? [-0.5,region.getXResolution()-1+0.5] : [0];
	var ys=(region.getYResolution()>1) ? [-0.5,region.getYResolution()-1+0.5] : [0];
	var zs=(region.getZResolution()>1) ? [-0.5,region.getZResolution()-1+0.5] : [0];
	foreach(xs as var x){
		foreach(ys as var y){
			foreach(zs as var z){
				p+=region.getPosition(x,y,z);
			}
		}
	}
	return p;
};

return T;

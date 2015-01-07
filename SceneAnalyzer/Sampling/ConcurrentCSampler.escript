/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:GASP] GASP/Sampling/ConcurrentCSampler.escript
 ** 2011-08 Claudius
 **/

static CSampler = module('./CSampler');
static CSamplingContext = module('./CSamplingContext');

//! ConcurrentCSampler ---|> CSampler
GLOBALS.ConcurrentCSampler := new Type(CSampler);

ConcurrentCSampler._activeSamplingContext := void;

static GASP = Std.require('SceneAnalyzer/GASP');
//! ---|> CSampler
ConcurrentCSampler.execute @(override) ::= fn(MinSG.Node sceneNode,
						MinSG.Evaluator evaluator,
						GASP gasp){

	if( isActive() ){
		stop();
		return;
	}
	// ------

	// Get or create sampling context
	if(!gasp.getAttribute($_samplingContext) || gasp._samplingContext.sampler != this ){
		gasp._samplingContext:=new CSamplingContext(sceneNode,evaluator,gasp,this);
	}

	// get sampling context
	_activeSamplingContext = gasp._samplingContext;

	// init data
	if(!this.init(_activeSamplingContext))
		return;

	// register extensionPoint
	registerExtension('PADrend_AfterFrame',this->ex_AfterFrame);
	out("Sampling started!");
};

//! [ex:PADrend_AfterFrame]
ConcurrentCSampler.ex_AfterFrame ::= fn(...){
	var iterator;
	while(isActive()){
		// execute next step or continue current step
		var result = iterator? iterator.next() : step(getActiveSamplingContext());

		// if step returned by using yield ...
		if( result ---|> YieldIterator ){
			// store the iterator
			iterator = result;
			// extract the result
			result = iterator.value();

			if(iterator.end())
				iterator = void;
		}
		
		// if the result is true, the sampling has finished
		if(result)
			stop();
		yield;
	}
	return Extension.REMOVE_EXTENSION;
};

ConcurrentCSampler.getActiveSamplingContext ::= fn(){	return _activeSamplingContext;	};
ConcurrentCSampler.isActive 				::= fn(){	return !(void==_activeSamplingContext);	};

ConcurrentCSampler.stop ::= fn(){	
	if(isActive()){
		_activeSamplingContext.gasp.applyDescription(_activeSamplingContext.description);
		_activeSamplingContext=void;
		out("Sampling stopped!\n");
	}
};


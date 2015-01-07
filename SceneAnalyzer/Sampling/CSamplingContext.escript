/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*! CSamplingContext */
var CSamplingContext = new Type;

CSamplingContext.sceneRoot:=void;
CSamplingContext.evaluator:=void;
CSamplingContext.gasp:=void;
CSamplingContext.sampler:=void;
CSamplingContext.duration:=void;
CSamplingContext.description:=void;
CSamplingContext.stepNum:=void;
// flags?????



/*! (ctor) CSamplingContext */
CSamplingContext._constructor::=fn( MinSG.Node _sceneRoot,
									MinSG.Evaluator _evaluator,
									module('../GASP') _gasp,
									module('./CSampler') _sampler ){
	this.sceneRoot=_sceneRoot;
	this.evaluator=_evaluator;
	this.gasp=_gasp;
	this.sampler=_sampler;
	this.duration=0;
	this.description=new Map();
	this.stepNum=0;
};
return CSamplingContext;

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/**
 *	[Plugin:Evaluator] Evaluator/EvaluatorManager.escript
 *	Static factories and registry for evaluators.
 */

GLOBALS.EvaluatorManager := new ExtObject();

EvaluatorManager.evaluators := [];
EvaluatorManager.evaluator := false;

//! (static)
EvaluatorManager.getSelectedEvaluator := fn() {
	return EvaluatorManager.evaluator;
};

//! (static)
EvaluatorManager.selectEvaluator := fn(e) {
	if(!e) {
		return;
	}
	if( EvaluatorManager.evaluator != e){
		EvaluatorManager.evaluator = e;
		executeExtensions('Evaluator_OnEvaluatorSelected', e);
		executeExtensions('Evaluator_OnEvaluatorDescriptionChanged', e, e.name());
	}
};

//! (static)
EvaluatorManager.registerEvaluator := fn(MinSG.Evaluator e){
	e.init();
	evaluators+=e;
	if(!getSelectedEvaluator())
		selectEvaluator(e);
};

//! (static)
EvaluatorManager.updateEvaluatorList := fn( [String,void] select=void){
	this.evaluators.clear();
		
	if(!select && this.evaluator){
		select =  this.evaluator.getEvaluatorTypeName();
	}
	//  Create Evaluators
	var arr=[];
	executeExtensions('Evaluator_QueryEvaluators', arr);
	foreach(arr as var e){
		this.registerEvaluator(e);
		if(select && e.getEvaluatorTypeName()==select){
			this.selectEvaluator(e);
		}
	}
	
};

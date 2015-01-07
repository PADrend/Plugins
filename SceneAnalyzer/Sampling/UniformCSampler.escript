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
/****
 **	[Plugin:GASP] GASP/Sampling/UniformCSampler.escript
 ** 2010-05 Claudius
 **/
static CSamplingContext = module('./CSamplingContext');
static CSampler = module('./CSampler');

var sampler = new CSampler;

sampler.name = "Uniform Sampler";

/*!	---|> CSampler */
sampler.init @(override) := fn(CSamplingContext ctxt) {

	if(!ctxt.isSet('regions')) {
		var resX = ctxt.gasp.rootNode.getXResolution();
		var resY = ctxt.gasp.rootNode.getYResolution();
		var resZ = ctxt.gasp.rootNode.getZResolution();
		
		ctxt.gasp.rootNode.splitUp(resX, resY, resZ);
		
		ctxt.regions := new Array();
		foreach(MinSG.getChildNodes(ctxt.gasp.rootNode) as var newRegion) {
			ctxt.regions += newRegion;
		}
	}
	
	return true;
};

/*! ---|> CSampler
	@return true if finished. */
sampler.step @(override) := fn(CSamplingContext ctxt) {
	if(ctxt.regions.empty()) {
		return true;
	}
	
	var region = ctxt.regions.back();
	ctxt.regions.popBack();
	
	var pos = region.getBB().getCenter();
	var result = ctxt.evaluator.cubeMeasure(ctxt.sceneRoot, region.getBB().getCenter());
	region.setValue(result);
//	if(!region.isSet($position)) region.positions := [];
//	if(!region.isSet($samples)) region.samples := [];
//	region.positions += pos;
//	region.samples += result;
	 ctxt.gasp.storeSample(pos,result.clone());
	
	if(ctxt.regions.size() % 10 == 0) {
		out("\r", ctxt.regions.size(), " regions remaining             ");
	}

	return false;
};

/*! ---|> CSampler */
sampler.createConfigPanel @(override) := fn() {
	var p = gui.createPanel(400, 100, GUI.AUTO_LAYOUT | GUI.BORDER);
	
	p += "*Uniform sampler*";
	p.nextRow();
		
	return p;
};

return sampler;

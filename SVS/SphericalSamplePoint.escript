/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
declareNamespace($SVS);

//! Human-readable description
MinSG.SphericalSampling.SamplePoint.description := "";

//! GUI selection status
MinSG.SVS.SamplePoint.selected := false;

PADrend.Serialization.registerType(MinSG.SphericalSampling.SamplePoint, "SVS.SphericalSamplePoint")
	.addDescriber(fn(ctxt, MinSG.SphericalSampling.SamplePoint obj, Map desc) {
		desc['position'] = ctxt.createDescription(obj.getPosition());
		desc['description'] = obj.description;
		desc['value'] = ctxt.createDescription(obj.getValue());
	})
	.setFactory(fn(ctxt, type, Map desc) {
		var obj = new type(ctxt.createObject(desc['position']));
		obj.setValue(ctxt.createObject(desc['value']));
		obj.description = desc['description'];
		return obj;
	});

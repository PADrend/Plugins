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

loadOnce(__DIR__ + "/Camera.escript");
loadOnce(__DIR__ + "/SphericalSamplePoint.escript");

//! Human-readable description
MinSG.SVS.VisibilitySphere.description := "";

PADrend.Serialization.registerType(MinSG.SVS.VisibilitySphere, "SVS.VisibilitySphere")
	.addDescriber(fn(ctxt, MinSG.SVS.VisibilitySphere obj, Map desc) {
		desc['sphere'] = ctxt.createDescription(obj.getSphere());
		desc['samples'] = ctxt.createDescription(obj.getSamples());
		desc['description'] = obj.description;
	})
	.setFactory(fn(ctxt,type, Map desc) {
		var obj = new type(ctxt.createObject(desc['sphere']), ctxt.createObject(desc['samples']));
		obj.description = desc['description'];
		return obj;
	});

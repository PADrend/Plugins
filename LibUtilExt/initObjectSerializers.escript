/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*! Collection of serializers for various types from Util.	*/
var defaultRegistry = Std.require('Std/ObjectSerialization').defaultRegistry;

defaultRegistry.registerType(Util.Color4f,"Util.Color4f")
	.addDescriber(fn(ctxt,Util.Color4f obj,Map d){ d['rgba'] = obj.toArray().implode(" ");	})
	.setFactory(fn(ctxt,Type actualType,Map d){
		return new Util.Color4f((d['rgba']---|>Array) ? d['rgba'] : d['rgba'].split(" "));
	});

defaultRegistry.registerType(Util.Color4ub,"Util.Color4ub")
	.addDescriber(fn(ctxt,Util.Color4ub obj,Map d){ d['rgba'] = obj.toArray().implode(" ");	})
	.setFactory(fn(ctxt,Type actualType,Map d){
		return new Util.Color4ub((d['rgba']---|>Array) ? d['rgba'] : d['rgba'].split(" "));
	});

return true;

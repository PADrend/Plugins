/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
 
/*! Marks an Object (or Type) as NetworkService.
	Assures the following interface:
		+ void close()
		+ Bool isOpen()
		+ void execute()	*/
var t = new Std.Traits.GenericTrait('NetworkServiceTrait');

t.onInit += fn(service){
	if(service---|>Type){
		if(!service.isSet($close))
			service.close ::= UserFunction.pleaseImplement;
		if(!service.isSet($isOpen))
			service.isOpen ::= UserFunction.pleaseImplement;
		if(!service.isSet($execute))
			service.execute ::= UserFunction.pleaseImplement;
	}else{
		if(!service.isSet($close))
			service.close := UserFunction.pleaseImplement;
		if(!service.isSet($isOpen))
			service.isOpen := UserFunction.pleaseImplement;
		if(!service.isSet($execute))
			service.execute := UserFunction.pleaseImplement;
	}
};
Util.Network.NetworkServiceTrait := t;
return t;
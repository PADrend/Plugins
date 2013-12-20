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
 
/*! Marks an Object (or Type) as to be able to receive data using a channel handler.
	Assures the following interface:
	 + setChannelHandler( channelNr, channelListener )
*/
var t = new Std.Traits.GenericTrait('MultiChannelReceiverTrait');
t.onInit += fn(obj){
	if(obj---|>Type){
		if(!obj.isSet($setChannelHandler))
			obj.setChannelHandler ::= UserFunction.pleaseImplement;
	}else{
		if(!obj.isSet($setChannelHandler))
			obj.setChannelHandler := UserFunction.pleaseImplement;
	}
};
Util.Network.MultiChannelReceiverTrait := t;
return t;
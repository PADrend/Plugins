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

/*! MultiChannelReceiverTrait implementation for ExtUDPSockets.
	\see LibUtilExt/Network/MultiChannelReceiverTrait	*/
var t = new Std.Traits.GenericTrait('UDPMultiChannelReceiverTrait');

t.attributes.channelHandler @(private,init) := Map;

//! \see LibUtilExt/Network/MultiChannelReceiverTrait
t.attributes.setChannelHandler ::= fn(Number channel,listener){
	Std.Traits.requireTrait(listener,Traits.CallableTrait);
	this.channelHandler[channel] = listener;
	return this;
};
static ExtUDPSocket = Std.module('LibUtilExt/Network/ExtUDPSocket');
t.onInit += fn(ExtUDPSocket socket){
	Std.Traits.addTrait(socket, Std.module('LibUtilExt/Network/MultiChannelReceiverTrait'));		//!	\see	LibUtilExt/Network/MultiChannelReceiverTrait
	socket.onDataReceived += fn(data){
		var parts = data.data.split(":",2);
		if(parts.count()==2){
			var handler = this.channelHandler[parts[0]];
			if(handler)
				handler(parts[1]);
		}
	};
};

Util.Network.UDPMultiChannelReceiverTrait := t;
return t;

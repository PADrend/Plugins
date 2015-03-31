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

/*! Extends a multi channel connection to support ping (and pong) messages.
	\note requires the LibUtilExt/Network/MultiChannelReceiverTrait and the 'LibUtilExt/Network/MultiChannelSenderTrait'
	Adds the following methods:
	 + sendPing()
	 + Number|false getPongReceivedClock()	result is relative to clock()
	 + Number|false getPingReceivedClock()	result is relative to clock()
*/
Util.Network.CHANNEL_ID_PING := 0x0101;

var t = new Std.Traits.GenericTrait('MultiChannel_Ping_Trait');

t.attributes.sendPing ::= fn(){
	this.sendValue(Util.Network.CHANNEL_ID_PING,"ping");													//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
};
t.attributes.lastPingReceiveClock @(private) := false;
t.attributes.lastPongReceiveClock @(private) := false;
t.attributes.getPongReceivedClock ::= fn(){	return lastPongReceiveClock;};
t.attributes.getPingReceivedClock ::= fn(){	return lastPingReceiveClock;};

t.onInit += fn(connection){
	Std.Traits.requireTrait(connection, Std.module('LibUtilExt/Network/MultiChannelReceiverTrait'));	//!	\see	LibUtilExt/Network/MultiChannelReceiverTrait
	Std.Traits.requireTrait(connection, Std.module('LibUtilExt/Network/MultiChannelSenderTrait'));		//!	\see	LibUtilExt/Network/MultiChannelSenderTrait

	//! \see MultiChannelReceiverTrait
	connection.setChannelHandler(Util.Network.CHANNEL_ID_PING,fn(data){
		if(data=="ping"){
			this.sendValue(Util.Network.CHANNEL_ID_PING,"pong");
			this.lastPingReceiveClock = clock();
//				out("(i)");
		}else if(data=="pong"){
			this.lastPongReceiveClock = clock();
			out("(pong)");
		}
	});
};
Util.Network.MultiChannel_Ping_Trait := t;
return t;
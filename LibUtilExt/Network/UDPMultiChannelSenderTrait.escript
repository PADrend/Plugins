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

/*! MultiChannelSenderTrait implementation for ExtUDPSockets.
	\see LibUtilExt/Network/MultiChannelSenderTrait	*/
var t = new Std.Traits.GenericTrait('UDPMultiChannelSenderTrait');

//! \see LibUtilExt/Network/MultiChannelSenderTrait
t.attributes.sendValue ::= fn(Number channel,String strData){
	this.sendString(""+channel+":"+strData);
	return this;
};
static ExtUDPSocket = Std.require('LibUtilExt/Network/ExtUDPSocket');
t.onInit += fn(ExtUDPSocket socket){
	Traits.addTrait(socket, Std.require('LibUtilExt/Network/MultiChannelSenderTrait'));			//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
};
Util.Network.UDPMultiChannelSenderTrait := t;
return t;

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

/*!	Extends an ExtUDPSocket to periodically register at a remote socket having an UDPAutoTargetResponderTrait.
	\param targetHost			host name or ip
	\param uint16_t targetPort
	\param Number duration		(optional) time in seconds after which the registration is refreshed
*/
var t = new Std.Traits.GenericTrait('UDPAutoRegisterTrait');

t.attributes.timeToRegister @(private) := 0;

static ExtUDPSocket = Std.require('LibUtilExt/Network/ExtUDPSocket');
t.onInit += fn(ExtUDPSocket socket, targetHost, Number targetPort, Number duration=1){
	socket.addTarget(targetHost,targetPort);
	(socket->fn(duration){
	
		this.onExecute += [duration]=> this->fn(duration){
			var t = clock();
			if(t>this.timeToRegister){
				this.sendString("!");
				this.timeToRegister = t+duration;
			}
		};

	})(duration);
};
Util.Network.UDPAutoRegisterTrait := t;
return t;
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

/*!	Extends an ExtUDPSocket to support automatically registering targets.
	If a request packet is received from an address, the sender is added to the set of targets for a while.
	\param Number duration		(optional) time in seconds after which an idle target is removed.
*/
var t = new Std.Traits.GenericTrait('UDPAutoTargetResponderTrait');

t.attributes.targets @(init,private) := Map; // ip:port -> [ip,target,timeout]
t.attributes.duration @(private) := void;
t.attributes.timeToCheck @(private) := 0;

static ExtUDPSocket = Std.require('LibUtilExt/Network/ExtUDPSocket');
t.onInit += fn(ExtUDPSocket socket, Number duration=10){
	(socket->fn(duration){
		this.onExecute += this->fn(){
			var t = clock();
			if(t>this.timeToCheck){
				foreach(targets as var key,var tArr){
					if(tArr && t>tArr[2]){
						outln("UDP remove target:",key);
						this.removeTarget(tArr[0],tArr[1]);
						targets[key]=void;
					}
				}
				this.timeToCheck = t+1;
			}
		};
	
		this.duration = duration;
		this.onDataReceived += this->fn(data){
			var key = ""+data.host+":"+data.port;
			 if(!targets[key]){
				this.addTarget(data.host,data.port);
				print_r("New UDP Target:",data._getAttributes());
			 }
			 targets[key] = [data.host,data.port,clock()+this.duration];
		};
	
	})(duration);
};
Util.Network.UDPAutoTargetResponderTrait := t;
return t;
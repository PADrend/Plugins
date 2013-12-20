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

/*!	Extends an ExtTCPConnection to support communication using multiple channels.
	\note Internally uses a Util.Network.DataConnection.
	\note Overrides the connection's execute() method \see NetworkServiceTrait
	\note adds the MultiChannelSenderTrait-interface
	\note adds the MultiChannelReceiverTrait-interface
	\note The internal Util.Network.TCPConnection object should NOT be accessed if adding this trait.
	Implements the following methods:
	 + setChannelHandler( channelNr, callable )		\see 	LibUtilExt/Network/MultiChannelReceiverTrait
	 + sendValue( channelNr, stringData )    		\see 	LibUtilExt/Network/MultiChannelSenderTrait
*/
var t = new Std.Traits.GenericTrait('MultiChannelTCPConnectionTrait');

t.attributes.channelHandler @(init,private) := Map;

//! \see LibUtilExt/Network/MultiChannelReceiverTrait
t.attributes.setChannelHandler ::= fn(Number channel,listener){
	Traits.requireTrait(listener,Traits.CallableTrait);										//!	\see	Traits.CallableTrait
	channelHandler[channel] = listener;
};

//! \see LibUtilExt/Network/MultiChannelSenderTrait
t.attributes.sendValue ::= fn(Number channel,String value){
	this.getConnection().sendValue(channel,value);											//! \see	LibUtilExt/Network/ExtTCPConnection
	return this;
};
//!\see LibUtilExt/Network/NetworkServiceTrait
t.attributes.execute ::= fn(){
	while(var data = this.getConnection().receiveValue()){
		var handler = this.channelHandler[data.channelId];
		if(handler){
			(this->handler)(data.data);
		}else{
			outln("No handler for '",data.data,"'@",data.channelId);
		}
	}
//		this.sendString(toJSON(data,false));
//		return this;
};
static ExtTCPConnection = Std.require('LibUtilExt/Network/ExtTCPConnection');
t.onInit += fn(ExtTCPConnection connection){
	Traits.addTrait(connection, Std.require('LibUtilExt/Network/MultiChannelReceiverTrait'));	//!	\see 	LibUtilExt/Network/MultiChannelReceiverTrait
	Traits.addTrait(connection, Std.require('LibUtilExt/Network/MultiChannelSenderTrait'));		//!	\see 	LibUtilExt/Network/MultiChannelSenderTrait
	
	// replace normal tcpConnection by DataConnection.
	//! \see LibUtilExt/Network/ExtTCPConnection
	(connection -> fn(){		this.connection = new Util.Network.DataConnection(this.connection);		})();
};
Util.Network.MultiChannelTCPConnectionTrait := t;	
return t;	
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

/*! A wrapper for a TCPServer object (expendable with traits.)
	- calls onConnect(new connection) when a new connection is available.
	\see LibUtilExt/Network/NetworkServiceTrait	*/
var T = new Type;
Traits.addTrait(T,Traits.PrintableNameTrait,$ExtTCPServer); 								//!	\see 	Traits.PrintableNameTrait
Traits.addTrait(T,Std.require('LibUtilExt/Network/NetworkServiceTrait'));					//! \see	LibUtilExt/Network/NetworkServiceTrait

T.server @(private) := void;
T.onConnect @(init,public) := MultiProcedure;

T._constructor ::= fn(Number port){
	this.server = Util.Network.TCPServer.create(port);
	if(!this.server)
		Runtime.exception("Could not create tcpServer on port "+port);
};

//!\see LibUtilExt/Network/NetworkServiceTrait
T.close 	@(override) ::= fn(){	this.server.close();	return this;	};
//!\see LibUtilExt/Network/NetworkServiceTrait
T.isOpen	@(override) ::= fn(){	return this.server.isOpen();	};

static ExtTCPConnection = Std.require('LibUtilExt/Network/ExtTCPConnection');
//!\see LibUtilExt/Network/NetworkServiceTrait
T.execute	@(override) ::= fn(){
	if(this.isOpen()){
		while(var newConnections = this.server.getIncomingConnection()){
			var extConnection = new ExtTCPConnection(newConnections);
			this.onConnect(extConnection);
		}
	}
};
Util.Network.ExtTCPServer := T;
return T;
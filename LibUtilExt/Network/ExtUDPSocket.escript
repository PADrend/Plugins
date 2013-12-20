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

/*! A wrapper for an UDPSocket object (expendable with traits.)
	\see LibUtilExt/Network/NetworkServiceTrait	*/
var T = new Type;
Traits.addTrait(T,Traits.PrintableNameTrait,$ExtUDPSocket); 								//!	\see Traits.PrintableNameTrait
Traits.addTrait(T,Std.require('LibUtilExt/Network/NetworkServiceTrait'));					//!\see LibUtilExt/Network/NetworkServiceTrait

T.socket @(private) := void;
T.onDataReceived @(init) := MultiProcedure;
T.onExecute @(init) := MultiProcedure;

T._constructor ::= fn(p...){
	this.socket = Util.Network.createUDPNetworkSocket(p...);
	if(!this.socket)
		Runtime.exception("Could not create UDP Socket: "+p.implode(","));
	this.socket.open(); // ???? why is this necessary
	if(!this.socket.isOpen())
		Runtime.exception("Could not create UDP Socket: "+p.implode(","));
};

//!\see LibUtilExt/Network/NetworkServiceTrait
T.close 		@(override) ::= fn(){		this.socket.close();	return this;	};

//! ---o \see LibUtilExt/Network/NetworkServiceTrait
T.execute		@(override) ::= fn(){
	while(var data = this.socket.receive())
		this.onDataReceived(data);
	this.onExecute();
	return this;
};

//! (internal) Access the wrapped socket.
T.getSocket					::=	fn(){		return this.socket;	};

//!\see LibUtilExt/Network/NetworkServiceTrait
T.isOpen		@(override) ::= fn(){		return this.socket.isOpen();	};


T.sendString				::= fn(p...){	return this.socket.sendString(p...);	};
T.addTarget					::= fn(p...){	this.socket.addTarget(p...); return this;	};
T.removeTarget				::= fn(p...){	this.socket.removeTarget(p...); return this;	};

Util.Network.ExtUDPSocket := T;
return T;
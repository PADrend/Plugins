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

/*! A wrapper for a TCPConnection object (expendable with traits.)
	\see LibUtilExt/Network/NetworkServiceTrait	*/
var T = new Type;
Traits.addTrait(T,Traits.PrintableNameTrait,$ExtTCPConnection); 								//! \see		Std.Traits.PrintableNameTrait
Traits.addTrait(T, Std.module('LibUtilExt/Network/NetworkServiceTrait'));						//! \see		LibUtilExt/Network/NetworkServiceTrait

T.connection @(private) := void;

T._constructor ::= fn(Util.Network.TCPConnection c){
	this.connection = c;
};
//! (static) Factory
T.connect ::= fn(host,port){
	var c =	Util.Network.TCPConnection.connect(host,port);
	if(!c)
		Runtime.exception("Could not connect to "+host+":"+port);
	return new this(c);
};

//!\see LibUtilExt/Network/NetworkServiceTrait
T.close 		@(override) ::= fn(){		this.connection.close();	return this;	};

//! ---o \see LibUtilExt/Network/NetworkServiceTrait
T.execute		@(override) ::= fn(){};

//! (internal) Access the wrapped connection.
T.getConnection				::=	fn(){		return this.connection;	};

//!\see LibUtilExt/Network/NetworkServiceTrait
T.isOpen		@(override) ::= fn(){		return this.connection.isOpen();	};

Util.Network.ExtTCPConnection := T;
return T;
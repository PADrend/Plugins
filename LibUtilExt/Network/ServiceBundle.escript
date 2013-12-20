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
 
/*! A collection of NetworkServices.
	\see LibUtilExt/Network/NetworkServiceTrait	*/
var T = new Type;
Traits.addTrait(T,Traits.PrintableNameTrait,$ServiceBundle);						//! \see 	Traits.PrintableNameTrait

T.services @(private,init) := Array;

//!	Add network service
T."+="				::= fn(c){	
	Traits.requireTrait(c, Std.require('LibUtilExt/Network/NetworkServiceTrait'));	//!	\see 	'LibUtilExt/Network/NetworkServiceTrait'
	this.services += c;	
};
//!	Remove network service
T."-="				::= fn(c){	this.services.removeValue(c);	};

//!	Return true iff empty
T.empty				::=	fn(){	return this.services.empty();	};

//! Allows foreach loops.
T.getIterator		::=	fn(){	return this.services.getIterator();	};

//! Calls close() on all services.
T.close ::=	fn(){
	while(!services.empty()){
		var s = services.popBack();
		s.close();
	}
	return this;
};

/*! Execute all open services; all closed services are removed.
	This function should be called regularly (e.g. in the application's main event loop).	*/
T.execute ::= fn(){
	var closedServices = [];
	foreach(this as var service){
		if(service.isOpen()){
			service.execute();
		}else{
			closedServices += service;
		}
	}
	foreach(closedServices as var s)
		this -= s;
};
Util.Network.ServiceBundle := T;
return T;
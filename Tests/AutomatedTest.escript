/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var T = new Type;

T.description @(private) := void;
T.fun @(private) := void;
T.result @(private) := void;
T.resultMessage @(private) := "?";
T.partialResults @(private,init) := Array;

/*! (ctor)
	@param description A text describing the test
	@param fun A function that is called as member of the tests when the test is executed.
				The function may return true or false on success or failure, 
				or addResult(...,...) may be called inside the function to set partial results,
				or the result may throw an exception to signal a failure.	*/
T._constructor ::= fn(String description,fun){
	this.description = description;
	this.fun = fun;
};
T.addResult ::= fn(String partDescription,Bool partResult){
	partialResults += [partDescription,partResult];
	result &= partResult;
};
T.execute ::= fn(){
	result = true;
	try{
		var r2 = fun();
		if(void !== r2){
			result &= r2;
		}
	}catch(e){
		out(e);
		resultMessage = "exception";
		result=false;
		return;
	}
	resultMessage = result ?"ok":"failed";
};
T.getDescription ::= 		fn(){	return description;	};
T.getPartialResults ::= 	fn(){	return partialResults;	};
T.getResult ::= 			fn(){	return result;	};
T.getResultMessage ::=		fn(){	return resultMessage;	};

return T;

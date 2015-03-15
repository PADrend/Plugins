/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*! GUI.ChainedEventHandler ---|> Std.MultiProcedure

	A GUI.ChainedEventHandler is similar to an ordinary Std.MultiProcedure with
	different behavior depending on the result of the registered functions:
		$BREAK (or true)		skip other functions; return true (event consumed)
		$BREAK_AND_REMOVE		remove this function; skip other functions; return true (event consumed)
		$CONTINUE (or void)		continue with other functions; if this was the last one, return false. (event not consumed)
		$CONTINUE_AND_REMOVE	remove this function;  continue with other functions; 
								if this was the last one, return false (event consumed).
		
	\see Std.MultiProcedure
*/

var T = new Type(Std.MultiProcedure);
T._printableName @(override) ::= $ChainedEventHandler;
T.BREAK ::= $BREAK;
T.BREAK_AND_REMOVE ::= $BREAK_AND_REMOVE;
T.CONTINUE ::= $CONTINUE;
T.CONTINUE_AND_REMOVE ::= $CONTINUE_AND_REMOVE;

//! Calls all the registered functions and returns true iff the event has been consumed (one function returned true or $BREAK...)
T._call @(override) ::= fn(obj,params...){
	for(var i=0;i<functions.count();){
		var result = (obj->functions[i])(params...);
		if(result){
			if(result == CONTINUE){
				++i;
			}else if(result == BREAK  || result === true){
				return true; // event handled
			}else if(result == BREAK_AND_REMOVE){
				functions.removeIndex(i);
				return true; // event handled
			}else if(result == CONTINUE_AND_REMOVE || result == REMOVE){
				functions.removeIndex(i);
			}else {
				Runtime.warn("Invalid return value '"+result+"'. Expected $BREAK, $BREAK_AND_REMOVE, $CONTINUE, or $CONTINUE_AND_REMOVE");
				++i;
			}
		}else{
			++i;
		}
	}
	return false;
};
return T;

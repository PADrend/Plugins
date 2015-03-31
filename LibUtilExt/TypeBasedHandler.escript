/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[PADrend] Util/TypeBasedHandler.escript
 **/

/*!
 \example // simple non recursive example
 
	static TypeBasedHandler = Std.module('LibUtilExt/TypeBasedHandler');
	var describer = new TypeBasedHandler(false); // one (non recursive) type handler for all instances
	describer.addHandler(Object,fn(obj){		return "(generic object '"+obj.getTypeName()+"')";	});
	describer.addHandler(Number,fn(Number s){	return "(Number "+s+")"; });

	out( describer( 4 ) ); 		// (Number 4)
	out( describer( void ) );	// (generic object 'Void')


 \example // recursive example
	
	var rDescriber ::= new TypeBasedHandler(true); // one (recursive) type handler for all instances
	
	// first handler for 'Collection'
	rDescriber += [Collection,fn(Collection c, Array result){
		result += "Collection";
	}];	
	// second handler for 'Collection'
	rDescriber += [Collection,fn(Collection c, Array result){
		result += "Size:" +c.count();
	}];	
	// handler for 'Array' just adds the maximum.
	rDescriber += [Array,fn(Array a, Array result){
		result += "Maximum:" +a.max();
	}];

	var	r1=[];
	rDescriber([1,2,3],r1);
	out( r1.implode(",") ); // Collection,Size:3,Maximum:3
*/

var T = new Type;

T._printableName @(override) ::= $TypeBasedHandler;
T._registry @(private,init) := Map; //!< Type ---> [ fn(obj, params...){....}* ]
T._recursive @(private) := false;

/*! (ctor)
	@param recursive 
		Controlls the behavior of the handler:
		'true' ... at first the most basic factory is called followed by the more and more specialized factories.
						The value of the last and most specialied factory is returned.
		'false' ...  only the most specialized handler are executed and the last result value is returned.
*/
T._constructor ::= fn( Bool recursive){
	_recursive = recursive;
};

/*! A TypeBasedHandler can be used as a callable object. 
	\note The calling object (this), which is used for calling the handler functions, is the 
		object the TypeBasedHandler is called from (and not the TypeBasedHandler).
	\note if no handler is found, an exception is thrown. */
T._call ::= fn(callingObject, obj, additionalParameters* ){
	var handler = queryHandlerForType(obj.getType());
	if(handler.empty())
		Runtime.exception("No handler for type '"+obj.getType()+"'");

	var parameters = [obj];
	parameters.append(additionalParameters);

	var result;
	while(!handler.empty()){
		result = (callingObject->handler.popBack())(parameters...);
	}
	return result;
};

//! [Type, function]
T."+=" ::= fn(Array a){
	addHandler(a...);
};

//! Register a handler function for a given Type.
T.addHandler ::= fn(Type type,fun){
	if(!_registry[type]){
		_registry[type] = [];
	}else if(!_recursive){
		Runtime.warn("More than one handler is registered for Type '"+Type+"' using a non-recursive TypeBasedHandler.");
	}
	// when adding multiple handler for one type, the new ones are added to the front so that they are executed first.
	_registry[type].pushFront(fun); 
};

/*! Returns a possibly empty array of handlers found for the given Type in reversed execution order.
	To call them in the right order, use it like this:
	\example 
		for(var handler = tbh.queryHandlerForType(myObj.getType()); !handler.empty() ; handler.popBack() )
			(handler.last()) (myObj);
*/
T.queryHandlerForType ::= fn(Type type){
	var handler = [];
	do{
		var a = _registry[type];
		if(a){
			handler.append(a);
			if(!_recursive)
				break;
		}
		type = type.getBaseType();
	}while(type);
	return handler;
};
return T;

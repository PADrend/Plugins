/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **		LibUtilExt/CommonTraits.escript
 **
 **		Collection of common traits.
 **/
loadOnce(__DIR__+"/EScript_Traits.escript");
declareNamespace($Traits);

// -----

 /*!	Allows calling multiple methods when creating an instance of the type.
	- The methods can be added to the type's new static '_constructors' MultiProcedure.
	- All constructor parameters are passed to all registered methods.
	- Super-constructor parameters are not supported.
	- The type's '_constructor' method is set and should not be altered.
	\code 
		var T = new Type;
		Traits.addTrait(T,Traits.MultiConstructorTrait);
		T._constructors += fn(...){	outln("Constructing T..."); };
		
		var t = new T;
	\endcode
};
*/
Traits.MultiConstructorTrait := new Traits.GenericTrait("Traits.MultiConstructorTrait");
Traits.MultiConstructorTrait.onInit += fn(Type type){
	if(type.isSetLocally($_constructor))
		Runtime.exception("Traits.MultiConstructorTrait: Type already has a constructor.");
	type._constructors ::= new MultiProcedure;
	type._constructor @(public,const)::= fn(p...){
		(this->_constructors)(p...);
	};
};


// -----

Traits.PrintableNameTrait := new Traits.GenericTrait($PrintableNameTrait);
Traits.PrintableNameTrait.onInit += fn(obj,typename){	obj._printableName @(override) ::= typename;	};

 // ------

Traits.SingletonTrait := new Traits.GenericTrait($SingletonTrait);
{
	var t = Traits.SingletonTrait;
	t.attributes._constructor @(private) ::= fn(){};
	t.attributes.instance @(public) ::= fn(){
		if(!this.isSetLocally($__instance))
			this.__instance @(private) ::= new this;
		return this.__instance;
	};
	t.onInit += fn(Type t){}; // only accept types.
}
// ---------------------------------------
/*!sets up default compare functions for all objects ( <, >, <=, >=, ==, != )
 * @param smaller the < function has to be given as parameter, all others are redirected to it.
 * @note this changes the behaviour of == and != which no longer behave like === and !== 
 */
Traits.DefaultComparisonOperatorsTrait := new Traits.GenericTrait("Traits.DefaultComparisonOperatorsTrait");
{
	var t = Traits.DefaultComparisonOperatorsTrait;

	t.attributes.'<'	::= fn(b){
		assert( b ---|> __compare_baseType , "tried to compare objects of different type.");
		return 	__compare_isSmaller(b);
	};
	t.attributes.'<='	::= fn(b){ return !(b < this);                };
	t.attributes.'>='	::= fn(b){ return !(this < b);                };
	t.attributes.'>'	::= fn(b){ return  (b < this);                };
	t.attributes.'=='	::= fn(b){ return !(this < b) && !(b < this); };
	t.attributes.'!='	::= fn(b){ return  (this < b) ||  (b < this); };

	t.onInit += fn(Type t,smaller){
		t.__compare_isSmaller @(private) ::= smaller;
		t.__compare_baseType @(private) ::= t; // store the calling Type as basetype. Objects of this type (or of a subtype) can be compared.
	};
};

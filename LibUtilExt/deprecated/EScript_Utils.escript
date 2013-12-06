/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
 

		
/****
 **	[PADrend] Util/EScript_Utils.escript
 **
 **  Various EScript extensions
 **/
 
// -------------------------------------
// Array extensions

//! Chunks an array into 'size' large chunks. The last chunk may contain less than 'size' elements. 
GLOBALS.Array.chunk ::= fn(size){
	var chunks = [];
	var currentChunk;
	foreach(this as var index,var obj){
		if( (index % size)==0){
			currentChunk = [];
			chunks += currentChunk;
		}
		currentChunk += obj;
	}
	return chunks;
};

Array.fill ::= fn(value){
	var end = count();
	for(var i = 0;i<end;++i)
		this[i] = value;
};

Array.fill_n ::= fn(Number start,Number size, value){
	var end = start+size;
	if( end > count()) 
		end = count();
	if( start<0 ) 
		start = 0;
	for(var i = start;i<end;++i)
		this[i] = value;
};

Array."=>" ::= fn(callable){
	var myWrapper = thisFn.wrapperFn.clone();
	myWrapper.wrappedFun := callable;
	myWrapper.boundParams := this.clone();
	return myWrapper;
};

Array."=>".wrapperFn := fn(params...){
	// _getCurrentCaller() is used instead of "this", as "this" may not be defined if this function
	// is called without a caller. This then results in a warning due to an undefined variable "this".
	return (Runtime._getCurrentCaller()->thisFn.wrappedFun)(thisFn.boundParams...,params...);
};

// fill_n

// -------------------------------------
// Collection extensions

//!	Calculate the average value of Maps and Arrays.
GLOBALS.Collection.avg ::= fn(){
    if(this.count()==0)
        return 0;
    var accum;
    var first = true;
    foreach(this as var v){
        if(first){
            accum = v;
            first = false;
        }else{
            accum+=v;
        }
    }
    return accum/this.count();
};

//!	 Calculate the sum of values of Maps and Arrays.
GLOBALS.Collection.sum ::= fn(){
    if(this.count()==0)
        return 0;
    var accum;
    var first = true;
    foreach(this as var v){
        if(first){
            accum = v;
            first = false;
        }else{
            accum+=v;
        }
    }
    return accum;
};


// -------------------------------------
// Math extensions

/**
 * Calculate k-combinations for the set {0, 1, 2, ..., n - 1}.
 * The binomial(n, k) subsets of size k are the possible combinations of the set of size n.
 * 
 * @param n Size of the set
 * @param k Size of the subsets
 * @return Array of binomial(n, k) arrays of size k
 * @note Code taken from http://compprog.wordpress.com/2007/10/17/generating-combinations-1/ including fix suggested in comments.
 * @see http://en.wikipedia.org/wiki/Combinations
 */
GLOBALS.Math.createCombinations := fn(Number n, Number k) {
	var nextCombination = fn(Array comb, Number n, Number k) {
		var i = k - 1;
		comb[i] = comb[i] + 1;
		while ((i > 0) && (comb[i] >= n - k + 1 + i)) {
			--i;
			comb[i] = comb[i] + 1;
		}

		if (comb[0] > n - k) { // Combination (n-k, n-k+1, ..., n) reached.
			return false; // No more combinations can be generated.
		}

		// comb now looks like (..., x, n, n, n, ..., n).
		// Turn it into (..., x, x + 1, x + 2, ...).
		for (var j = i + 1; j < k; ++j) {
			comb[j] = comb[j - 1] + 1;
		}
		return true;
	};

	var comb = [];

	// Setup the initial combination.
	for (var i = 0; i < k; ++i) {
		comb.pushBack(i);
	}

	// Generate all other combinations.
	var combinations = [comb.clone()];
	while (nextCombination(comb, n, k)) {
		combinations.pushBack(comb.clone());
	}
	return combinations;
};

//!	Set all the bits set in \param mask to the value \param b.
Number.setBitMask ::= fn(Number mask,Bool b=true){
	return b ? (this|mask) : (this^(this&mask));
};


// -------------------------------------
// Multi MultiProcedure
/*! Extendable function without result.
	\example
		var f = new MultiProcedure;
		f+=fn(a){out( "x:",a,"\n" );};
		f+=fn(a){out( "y:",(a+1),"\n" );};
		f+=fn(a){out( "z:",(a+2),"\n"); return MultiProcedure.REMOVE; }; // removed after one call
	
		f(27);
		// x:27
		// y:28
		// z:29
		f(27);
		// x:27
		// y:28
	*/
GLOBALS.MultiProcedure := new Type;
MultiProcedure._printableName @(override) ::= $MultiProcedure;

MultiProcedure.REMOVE ::= $REMOVE;

MultiProcedure.functions @(private,init) := Array;

MultiProcedure._call ::= fn(obj,params...){
	for(var i = 0;i<functions.count();){
		if( (obj->functions[i])(params...)==REMOVE){
			functions.removeIndex(i);
		}else{
			++i;
		}
	}
};
MultiProcedure."+=" ::= fn(f){	this.functions += f;	};
MultiProcedure.accessFunctions ::= fn(){	return functions;	};
MultiProcedure.clear ::= fn(){	return functions.clear();	};
MultiProcedure.clone ::= fn(){
	var other = new MultiProcedure;
	(other->fn(f){	functions = f;	})(functions.clone());
	return other;
};
MultiProcedure.count ::= fn(){	return functions.count();	};
MultiProcedure.empty ::= fn(){	return functions.empty();	};
MultiProcedure.filter ::= fn(fun){
	functions.filter(fun);
	return this;
};

// -------------------------------------
// Namespace extensions

/*!	Declare a (possibly nested) namespace, if it is not already delcared.
	\example
		declareNamespace( $MinSG,$SomeNamespace,$SomeOtherNamespace );
		// makes sure that MinSG.SomeNamespace.SomeOtherNamespace exists.
*/
GLOBALS.declareNamespace := fn( ids... ){
	var currentNamespace = GLOBALS;
	while(!ids.empty()){
		var id = ids.popFront();
		if( !currentNamespace.isSet(id) ){
			var ns = new Namespace;
			ns._printableName @(override) := id;
			currentNamespace.setAttribute(id,ns,EScript.ATTR_CONST_BIT);
		}
		currentNamespace = currentNamespace.getAttribute(id);
	}
	return currentNamespace;
};//declareNamespace($MinSG,$Foo);

// -------------------------------------
// Set

GLOBALS.Set := new Type;
Set._data := void;
Set._printableName @(override) ::= $Set;

//! (ctor)
Set._constructor ::= fn( values = void ){
	this._data = new Map;
	if(void!=values){
		foreach(values as var v)
			this+=v;
	}
};

Set.add ::= fn(value){
	this._data[value]=value;
	return this;
};
Set.clear ::= fn(){	
	_data.clear();	
	return this;	
};
Set.clone ::= fn(){	
	var c = new Set;
	c._data = this._data.clone();
	return c;	
};
Set.contains ::= fn(value){	
	return _data.containsKey(value);	
};
Set.count ::= fn(){	
	return _data.count();	
};
Set.getIntersection ::= fn(Set other){
	if(other.count()<this.count())
		return other.getIntersection(this);
	var s = new Set;
	foreach(this as var value){
		if(other.contains(value))
			s+=value;
	}
	return s;
};
Set.getIterator ::= fn(){
	return _data.getIterator();
};
Set.getMerged ::= fn(Set other){
	var a = this.clone();
	return a.merge(other);
};
Set.getRemoved ::= fn(Set other){
	var a = this.clone();
	return a.remove(other);
};
Set.getSubstracted ::= fn(Set other){
	var a = this.clone();
	return a.substract(other);
};
Set.intersect ::= fn(Set other){
	s.swap(getIntersection(other));
	return this;
};
Set.merge ::= fn(Set other){
	_data.merge(other._data);
	return this;
};
Set.remove ::= fn(value){
	this._data.unset(value);
	return this;
};
Set.substract ::= fn(Set other){
	foreach(other as var value)
		_data.unset(value);
	return this;
};
Set.toArray ::= fn(){	
	var a = [];
	foreach(_data as var value,var dummy)
		a+=value;
	return a;
};
Set.swap ::= fn(Set other){
	_data.swap(other._data);
	return this;
};
Set."+=" ::= Set.add;
Set."-=" ::= Set.remove;
Set."|=" ::= Set.merge;
Set."|" ::= Set.getMerged;
Set."&=" ::= Set.intersect;
Set."&" ::= Set.getIntersection;

Set."==" ::= fn(other){
	return (other---|>Set) ? (_data==other._data) : false;
};


loadOnce(__DIR__+"/EScript_Traits.escript");




/*!	Markes a Type as Callable.
	\param (optional) fun	Function called when an instance of the type is used as function.
							The first parameter is the instance object.
*/
Traits.CallableTrait := new Traits.GenericTrait("Traits.CallableTrait");
{
	var t = Traits.CallableTrait;
	t.onInit += fn(t,fun=void){
		if(fun){
			if(t---|>Type){
				t._call ::= fun;
			}else{
				t._call := fun;
			}
		}
	};
}

Traits.addTrait(Function,		Traits.CallableTrait);
Traits.addTrait(UserFunction,	Traits.CallableTrait);
Traits.addTrait(Delegate,		Traits.CallableTrait);
Traits.addTrait(MultiProcedure,	Traits.CallableTrait);



// -----------------------------------------

IO.loadTextFile := IO.fileGetContents; // alias
IO.saveTextFile := IO.filePutContents; // alias


String._beginsWith ::= String.beginsWith;
String.beginsWith ::= fn(subj,startPos = 0){
	return (startPos>0) ? this.substr(startPos)._beginsWith(subj) : this._beginsWith(subj);
};
{
	var s = "foobar";
	assert(
		s.beginsWith("foo")&& s.beginsWith(s)&&  !s.beginsWith(s+s)
		&& s.beginsWith("bar",3) && !s.beginsWith("barx",3) && ! s.beginsWith("l",1000)
	);
}



// -------------------------------------
// Function extensions 


//! Use this method as way to show that a member function has to be implemented by an inheriting Type (kind of 'pure virtual').
UserFunction.pleaseImplement ::= fn(...){	Runtime.exception("This method is not implemented. Implement in subtype, or do not call!");	};



//! \todo move into std-namespace
GLOBALS._bindLastParams := fn(wrappedFun,params...){
	var myWrapper = thisFn.wrapperFn.clone();
	myWrapper._wrappedFun := wrappedFun;
	myWrapper._boundParams := params;
	return myWrapper;
};
/*! (internal) 
	\note _getCurrentCaller() is used instead of "this", as "this" may not be defined if this function
	is called without a caller. This then results in a warning due to an undefined variable "this". */
GLOBALS._bindLastParams.wrapperFn := fn(params...){
	return (Runtime._getCurrentCaller()->thisFn._wrappedFun)(params...,thisFn._boundParams...);
};
//! \todo move into std-namespace
GLOBALS._bindFirstParams := fn(wrappedFun,params...){
	var myWrapper = thisFn.wrapperFn.clone();
	myWrapper._wrappedFun := wrappedFun;
	myWrapper._boundParams := params;
	return myWrapper;
};
//! (internal) 
GLOBALS._bindFirstParams.wrapperFn := fn(params...){
	return (Runtime._getCurrentCaller()->thisFn._wrappedFun)(thisFn._boundParams...,params...);
};

	//! Returns a possibly empty Array of the bound parameters.
GLOBALS._getBoundParams := fn(fun){
	return fun.isSet($_boundParams) ? fun._boundParams.clone() : [];
};

/*!	Adds the following methods to the target:
 
 - bindFirstParams(p...)
 - bindLastParams(p...)
 - getBoundParams()
 
 \note Requires the target to have the Traits.CallableTrait.
 \see Traits.CallableTrait
*/
Traits.BindableParametersTrait := new Traits.GenericTrait("Traits.BindableParametersTrait");
{
	var t = Traits.BindableParametersTrait;

	// Binding parameters with function wrappers
	t.attributes.bindLastParams ::=	fn(params...){		return _bindLastParams(this,params...);		};

	// Binding parameters with function wrappers
	t.attributes.bindFirstParams ::=	fn(params...){		return _bindFirstParams(this,params...);	};

	//! Returns a possibly empty Array of the bound parameters.
	t.attributes.getBoundParams ::=	fn(){		return _getBoundParams(this);	};

	t.onInit += fn(t){
		Traits.requireTrait(t,Traits.CallableTrait);
	};
}


Traits.addTrait(Function,		Traits.BindableParametersTrait);
Traits.addTrait(UserFunction,	Traits.BindableParametersTrait);
Traits.addTrait(Delegate,		Traits.BindableParametersTrait);
Traits.addTrait(MultiProcedure,	Traits.BindableParametersTrait);

// -----

// ------------------------------------------

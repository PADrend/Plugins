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
assert(EScript.VERSION>=607); 

/*
	This file loads the EScript Std library (available since 0.6.7) and makes
	some adjustments to provide compatibility with the former EScript extensions
	in LibUtilExt.
	If possible, try not to use any of the compatibility interfaces defined in 
	this file in new code!
*/

addSearchPath(__DIR__ + "/../../modules/EScript");
addSearchPath(__DIR__ + "/../../../EScript");
addSearchPath("EScript.exp");
loadOnce("Std/basics.escript");
Std.addModuleSearchPath(__DIR__ + "/../../modules/EScript");
Std.addModuleSearchPath(__DIR__ + "/../../../EScript");
Std.addModuleSearchPath("EScript.exp");

Std.require('Std/TypeExtensions');

GLOBALS.ObjectSerialization := Std.require('Std/ObjectSerialization');
GLOBALS.MultiProcedure := Std.require('Std/MultiProcedure');
GLOBALS.DataWrapperContainer := Std.require('Std/DataWrapperContainer');
GLOBALS.Set := Std.require('Std/Set');
GLOBALS.info := Std.require('Std/info');
GLOBALS.PriorityQueue := Std.require('Std/PriorityQueue');
GLOBALS.Traits := Std.require('Std/Traits/basics');
Traits.CallableTrait := Std.require('Std/Traits/CallableTrait');
Traits.DefaultComparisonOperatorsTrait := Std.require('Std/Traits/DefaultComparisonOperatorsTrait');
Traits.PrintableNameTrait := Std.require('Std/Traits/PrintableNameTrait');

// --------------------------------------------------
// DataWrapper
GLOBALS.DataWrapper := Std.require('Std/DataWrapper');
DataWrapper.createFromConfig ::= DataWrapper.createFromEntry;

//! Returns an array of possible default values
DataWrapper.getOptions ::= fn(){
	return isSet($_options) ? 
		(_options---|>Array ? _options.clone() : (this->_options) () ) : [];
};

//! Returns if the dataWrapper has possible default values
DataWrapper.hasOptions ::= fn(){
	return isSet($_options);
};

//! Set an Array of possible default values. Returns this.
DataWrapper.setOptions ::= fn(Array options){
	this._options @(private) := options.clone();
	return this;
};

/*! Set a function providing options (caller is the DataWrapper, must return an Array).
	\code
		var myDataWrapper = DataWrapper.createFromValue(5).setOptionsProvider( fn(){ return [this(),this()*2] } );
		print_r(myDataWrapper.getOptions()); // [5,10]
*/
DataWrapper.setOptionsProvider ::= fn(callable){
	this._options @(private) := callable;
	return this;
};



// --------------------------------------------------
// Config
GLOBALS.ConfigManager := Std.require('Std/JSONDataStore');
ConfigManager.getValue ::= ConfigManager.get;
ConfigManager.setValue ::= ConfigManager.set;

// system' main config manager
GLOBALS.systemConfig := new ConfigManager;

// compatibility interface
GLOBALS.getConfigValue := systemConfig->systemConfig.getValue;
GLOBALS.loadConfig := systemConfig->systemConfig.init;
GLOBALS.saveConfig  := systemConfig->systemConfig.save;
GLOBALS.setConfigInfo := systemConfig->systemConfig.setInfo;
GLOBALS.setConfigValue := systemConfig->systemConfig.setValue;

// ---------------------------------------------------
// Function extensions 

//! Use this method as way to show that a member function has to be implemented by an inheriting Type (kind of 'pure virtual').
UserFunction.pleaseImplement ::= fn(...){	Runtime.exception("This method is not implemented. Implement in subtype, or do not call!");	};

/*!	Adds the following methods to the target:
 
 - bindFirstParams(p...)
 - bindLastParams(p...)
 - getBoundParams()
 
 \note Requires the target to have the Traits.CallableTrait.
 \see Traits.CallableTrait
*/
Traits.BindableParametersTrait := new Traits.GenericTrait("Traits.BindableParametersTrait");
{

	static _bindLastParams = fn(wrappedFun,params...){
		var myWrapper = thisFn.wrapperFn.clone();
		myWrapper._wrappedFun := wrappedFun;
		myWrapper._boundParams := params;
		return myWrapper;
	};
	
	/*! (internal) 
		\note _getCurrentCaller() is used instead of "this", as "this" may not be defined if this function
		is called without a caller. This then results in a warning due to an undefined variable "this". */
	_bindLastParams.wrapperFn := fn(params...){
		return (Runtime._getCurrentCaller()->thisFn._wrappedFun)(params...,thisFn._boundParams...);
	};
	
	//! \todo move into std-namespace
	static _bindFirstParams = fn(wrappedFun,params...){
		var myWrapper = thisFn.wrapperFn.clone();
		myWrapper._wrappedFun := wrappedFun;
		myWrapper._boundParams := params;
		return myWrapper;
	};
	//! (internal) 
	_bindFirstParams.wrapperFn := fn(params...){
		return (Runtime._getCurrentCaller()->thisFn._wrappedFun)(thisFn._boundParams...,params...);
	};

	//! Returns a possibly empty Array of the bound parameters.
	static _getBoundParams = fn(fun){
		return fun.isSet($_boundParams) ? fun._boundParams.clone() : [];
	};


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
// --------------------------------------------------


GLOBALS.declareNamespace := Std.declareNamespace;
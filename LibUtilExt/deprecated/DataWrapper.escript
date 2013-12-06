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
 **	plugins/Util/DataWrapper.escript
 ** 2012-03 Claudius
 **/
loadOnce(__DIR__+"/Config.escript");
loadOnce(__DIR__+"/EScript_Utils.escript");


/*! A DataWrapper encaspulates a value that can be internally stored as attribute, 
	inside of a configManager, or which is accessible only by function calls.	
	A DataWrapper provides an unified interface, indepentently from the real location of the value.
*/
GLOBALS.DataWrapper := new Type;
DataWrapper._printableName @(override) ::= $DataWrapper;


/*! (static) Factory
	Creates a DataWrapper connected to an object's attribute.
	\code var someValue = DataWrapper.createFromAttribute( someObject, $attr );	
	\note refreshOnGet is set to true. */
DataWrapper.createFromAttribute ::= fn( obj, Identifier attrName){
	return new AttributeWrapper(obj,attrName);
};

/*! (static) Factory
	Create a dataWrapper for a config value.
	\code var someValue = DataWrapper.createFromConfig( systemConfig, "SomePlugin.someKey", 17 );
	\see Config.escript
	\param _refreshOnGet Iff true, the data is refreshed implicitly when calling get() -- set this
			to false, if it may be that the config entry is changed from another position 
			(although this is not a good idea...). Iff false, the last queried value is returned by get().
*/
DataWrapper.createFromConfig ::= fn(ConfigManager configManager,String key,defaultValue = void,Bool _refreshOnGet = false){
	return new ConfigEntryWrapper(configManager,key,defaultValue,_refreshOnGet);
};

/*! (static) Factory
	Create a dataWrapper from a pair of functions.
	\code var someValue = DataWrapper.createFromFunctions( A->fn(){ return this.m1;},  A->fn(newValue){ this.m1 = newValue; } );
	\param getter Parameterless function called to get the current value
	\param setter (optional; may be void) Function with one parameter called to set the current value
	\param _refreshOnGet Iff true, the data is refreshed implicitly (=the getter is called) when calling get().
			Iff false, the last queried value is returned by get().
*/
DataWrapper.createFromFunctions ::= fn(getter, setter = void,_refreshOnGet = false){
	return new FnDataWrapper(getter,setter,_refreshOnGet);
};

/*! (static) Factory
	Creates a DataWrapper connected to a collection's entry.
	\code	var values = { 'foo' : 1, 'bar' : 2 };
			var someValue = DataWrapper.createFromMapEntry( values, 'foo' );	
	\note refreshOnGet is set to true. */
DataWrapper.createFromEntry ::= fn(Collection collection, key){
	return new CollectionEntryWrapper(collection,key);
};

//! (static) Factory
DataWrapper.createFromValue ::= fn(value){
	return new SimpleValueWrapper(value);
};

// --------------

DataWrapper.currentValue @(private) := void;
DataWrapper.refreshOnGet @(private) := false;

//! (internal) ---o
DataWrapper.doGet @(private) ::= 		UserFunction.pleaseImplement;

//! (internal) ---o
DataWrapper.doSet @(private) ::= 		UserFunction.pleaseImplement;

//! (internal)
DataWrapper.initCurrentValue @(private) ::= fn(value,_refreshOnGet){	
	currentValue = value;	
	refreshOnGet = _refreshOnGet;	
};

/*! ---o
	\note Do NOT alter the returned value if it is not a primitive value! If you have to, clone it and the set it again!	*/
DataWrapper.get ::= fn(){
	if(refreshOnGet)
		refresh();
	return currentValue;
};

//! Like refresh(), but always calls onDataChanged(newData) even if the value didn't change.
DataWrapper.forceRefresh ::= fn(){	
	currentValue = doGet();
	onDataChanged(currentValue);
};

/*! Called when the value has been changed.
	To add a custom listener use the '+=' operator. E.g.
	\code
		myDataWrapper += fn(newData){	out("The value is now:",newData); };
*/
DataWrapper.onDataChanged @(init) := MultiProcedure;

/*! Refresh the internal data from the dataWrapper's data source. If the data has changed, 
	onDataChanged(newData) is called. This function has only to be called  manually if the connected data may change externally.*/
DataWrapper.refresh ::= fn(){
	var newValue = doGet();
	if( !(currentValue==newValue) ){
		currentValue = newValue;
		onDataChanged(newValue);
	}
};

/*! ---o 
	Set a new value. If the value does not equal the old value, onDataChanged(...) is called. */
DataWrapper.set ::= fn(newValue){
	if(! (currentValue==newValue) ){
		doSet(newValue);
		currentValue = doGet();
		onDataChanged(newValue);
	}
	return this;
};

/*! Use a DataWrapper as a function without parameters to get its value; use it with one parameter to set its value.
	\code
		var myDataWrapper = DataWrapper.createFromValue(5);
		myDataWrapper(10);  // is the same as myDataWrapper.set(10);
		out( myDataWrapper() ); // outputs '10'. Is the same as out( myDataWrapper.get() );
*/
Traits.addTrait(DataWrapper,Traits.CallableTrait,fn(obj,params...){
	return params.empty() ? this.get() : this.set(params...);
});

// ---------------
// Options represent typical values for the dataWrapper. They are mainly used to automatically fill the corresponding field in a corresponding gui component.

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

// ------------------------------------------
// (internal) AttributeWrapper ---|> DataWrapper
DataWrapper.AttributeWrapper ::= new Type(DataWrapper);
var AttributeWrapper = DataWrapper.AttributeWrapper;

//! ctor
AttributeWrapper._constructor ::= fn(_obj,Identifier _attr){
	this.obj @(private) := _obj;
	this.attr @(private) := _attr;
	initCurrentValue(doGet(),true);
};

//! ---|> DataWrapper
AttributeWrapper.doGet @(override,private) ::= 	fn(){	return obj.getAttribute(attr);	};
	
//! ---|> DataWrapper
AttributeWrapper.doSet @(override,private) ::= 	fn(newValue){	obj.assignAttribute(attr, newValue);	};


// ------------------------------------------
// (internal) CollectionEntryWrapper ---|> DataWrapper
DataWrapper.CollectionEntryWrapper ::= new Type(DataWrapper);
var CollectionEntryWrapper = DataWrapper.CollectionEntryWrapper;

//! ctor
CollectionEntryWrapper._constructor ::= fn(Collection _collection,_key){
	this.collection @(private) := _collection;
	this.key @(private) := _key;
	initCurrentValue(doGet(),true);
};

//! ---|> DataWrapper
CollectionEntryWrapper.doGet @(override,private) ::= 	fn(){	return collection[key];	};
	
//! ---|> DataWrapper
CollectionEntryWrapper.doSet @(override,private) ::= 	fn(newValue){	collection[key] = newValue;	};

// ------------------------------------------
// (internal) ConfigEntryWrapper ---|> DataWrapper
DataWrapper.ConfigEntryWrapper ::= new Type(DataWrapper);
var ConfigEntryWrapper = DataWrapper.ConfigEntryWrapper;

//! ctor
ConfigEntryWrapper._constructor ::= fn(ConfigManager _config,String _key,defaultValue,Bool _refreshOnGet){
	this.config @(private) := _config;
	this.key @(private) := _key;
	initCurrentValue(config.getValue(key,defaultValue),_refreshOnGet);
};
//! ---|> DataWrapper
ConfigEntryWrapper.doGet @(override,private) ::= fn(){	return config.getValue(key);	};

//! ---|> DataWrapper
ConfigEntryWrapper.doSet @(override,private) ::= fn(newValue){	config.setValue(key,newValue);	};

// ------------------------------------------
// (internal) SimpleValueWrapper ---|> DataWrapper
DataWrapper.SimpleValueWrapper ::= new Type(DataWrapper);
var SimpleValueWrapper = DataWrapper.SimpleValueWrapper;

//! ctor
SimpleValueWrapper._constructor ::= fn(_value){
	initCurrentValue(_value,false);
};
//! ---|> DataWrapper
SimpleValueWrapper.doGet @(override,private) ::= fn(){	return currentValue;	};

//! ---|> DataWrapper
SimpleValueWrapper.doSet @(override,private) ::= fn(newValue){ currentValue = newValue; };

// ------------------------------------------
// (internal) FnDataWrapper ---|> DataWrapper
DataWrapper.FnDataWrapper ::= new Type(DataWrapper);
var FnDataWrapper = DataWrapper.FnDataWrapper;

//! ctor
FnDataWrapper._constructor ::= fn(_getter,_setter,Bool _refreshOnGet){
	this.doGet @(override,private) := _getter;
	this.doSet @(override,private) := _setter ? _setter : fn(data){ }; // ignore
	initCurrentValue(doGet(),_refreshOnGet);
};
// ----------------------------------------------------------------------------------------------------
// DataWrapperContainer   !!!!!!!EXPERIMENTAL!!!!!!!!!!!

GLOBALS.DataWrapperContainer := new Type;
DataWrapperContainer._printableName @(override) ::= $DataWrapperContainer;

DataWrapperContainer.dataWrappers @(init,private) := Map;

//! ---o
DataWrapperContainer.onDataChanged @(init) := MultiProcedure; 

/*! (ctor) */
DataWrapperContainer._constructor ::= fn([void,Map] source=void){
    if(source)
        this.merge(source);
};

DataWrapperContainer.assign ::= fn(Map _values,warnOnUnknownKey = true){
	foreach(_values as var key,var value)
		this.setValue(key,value,warnOnUnknownKey);
	return this;
};
	
DataWrapperContainer.clear ::= fn(){
	foreach(this.dataWrappers as var dataWrapper)
		dataWrapper.onDataChanged.filter(this->fn(fun){		return !(fun---|>UserFunction && fun.getBoundParams()[0]==this);	});
	this.dataWrappers.clear();
	return this;
};

DataWrapperContainer.count ::=			fn(){	dataWrappers.count();	};

//! Call to remove all cycling dependencies with the contained DataWrappers
DataWrapperContainer.destroy ::= fn(){
	this.clear();
	this.dataWrappers = void; // prevent further usage.
	return this;
};
DataWrapperContainer.empty ::=			fn(){	this.dataWrappers.empty();	};
DataWrapperContainer.getValue ::= fn(key,defaultValue = void){	
	var dataWrapper = this.dataWrappers[key];
	return dataWrapper ? dataWrapper() : defaultValue;
};
DataWrapperContainer.getDataWrapper ::= fn(key){	return this.dataWrappers[key];	};
DataWrapperContainer.getDataWrappers ::= fn(){	return this.dataWrappers.clone();	};

DataWrapperContainer.getValues ::= fn(){
	var m = new Map;
	foreach(this.dataWrappers as var key,var dataWrapper)
		m[key] = dataWrapper();
	return m;
};
DataWrapperContainer.containsKey ::= fn(key){
	return this.dataWrappers.containsKey(key);
};
DataWrapperContainer.merge ::= fn(Map _dataWrappers){
	foreach(_dataWrappers as var key,var dataWrapper)
		this.addDataWrapper(key,dataWrapper);
	return this;
};

/*! Add a new Datawrapper with the given key.
	\note calles onDataChanged(key, valueOfTheDataWrapper)	*/
DataWrapperContainer.addDataWrapper ::= fn(key, DataWrapper dataWrapper){
	if(this.dataWrappers[key])
		this.unset(key);
	this.dataWrappers[key] = dataWrapper;
	// it is important that the first parameter bound is this object as it is used to identify the function on removal.
	dataWrapper.onDataChanged += (fn(container,key,value){
		container.onDataChanged(key,value);
	}).bindFirstParams(this,key);
	this.onDataChanged(key,dataWrapper());
	return this;
};

DataWrapperContainer.setValue ::= fn(key,value,warnOnUnknownKey = true){
	var dataWrapper = this.dataWrappers[key];
	if(dataWrapper){
		dataWrapper(value);
	}else{
		if(warnOnUnknownKey)
			Runtime.warn("DataWrapperContainer.setValue(...) unknown entry '"+key+"'.");
	}
	return this;
};

DataWrapperContainer.unset ::= fn(key){
	var dataWrapper = this.dataWrappers[key];
	if(dataWrapper){
		dataWrapper.onDataChanged.filter(this->fn(fun){
			return !(fun---|>UserFunction && fun.getBoundParams()[0]==this);
		});
		this.dataWrappers.unset(key);
	}
	return this;
};

DataWrapperContainer._get ::= DataWrapperContainer.getValue;
DataWrapperContainer._set ::= fn(key,value){
	this.setValue(key,value);
	return value;
};

DataWrapperContainer.getIterator ::= fn(){
	var mapIterator = this.dataWrappers.getIterator();

	var it = new ExtObject;
	it.end := mapIterator->mapIterator.end;
	it.next := mapIterator->mapIterator.next;
	it.key := mapIterator->mapIterator.key;
	it.value := mapIterator->fn(){
		var v = this.value();
		return v ? v() : void;
	};
	return it;

};


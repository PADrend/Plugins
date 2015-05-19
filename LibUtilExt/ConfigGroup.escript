/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*! A configGroup is a subset of config entries from a config (a Std.JSONDataStore or similar) that can be changed independently from the
	underlying config. The changes can be applied to the underlying config by calling .save().
	
	var mainConfig = new Std.JSONDataStore; // some config 
		
	var specialConfig = new (Std.module('LibUtilExt/ConfigGroup'))(mainConfig,"Foo"); // subgroup "Foo"
	var entry = Std.DataWrapper.createFromEntry(specialConfig,"v1","myDefaultValue1"); // entry with name "Foo.v1"
	// change entry value
	specialConfig.save(); // apply the value of the entry to the mainConfig.
	
*/
var T = new Type;

T._printableName @(override) ::= $ConfigGroup;

//! (ctor)
T._constructor ::= fn( ){};

T.data @(private,init) := Map;
T.baseConfig @(private) := void;
T.prefix @(private) := void;

//! (ctor) base config can be a Map or a Std.JSONDataStore
T._constructor ::= fn(baseConfig,String prefix=""){
	this.baseConfig = baseConfig;
	this.prefix = prefix.empty() ? "" : prefix+".";
};


/*!	Get a config-value.
	If the value is not set, the default value is returned and memorized.	*/
T.get ::= fn( String key, defaultValue = void){
	if( this.data.containsKey(key) ){
		return this.data[key];
	}else{
		var value = this.baseConfig.get(this.prefix + key,defaultValue);
		this.data[key] = value;
		return value;
	}
};

//! Apply configuration to baseConfig.
T.save ::= fn(_filename = void){
	foreach( this.data as var key, var value)
		this.baseConfig[this.prefix+key] = value;
};


T.set ::= fn(String key, value){
	this.data[key] = value;
};

T._get ::= T.get;
T._set ::= fn(key,value){
	this.set(key,value);
	return value;
};

return T;

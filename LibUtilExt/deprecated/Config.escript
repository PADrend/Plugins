/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2008-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2009 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[PADrend] Util/Config.escript
 **
 ** Configuration management for storing JSON-expressable data.
 ** 
 **/

var ConfigManager = new Type;

GLOBALS.ConfigManager := ConfigManager;
ConfigManager._printableName @(override) ::= $ConfigManager;

ConfigManager._data @(private,init) := Map;
ConfigManager._filename @(private) := "";
ConfigManager._autoSave @(private) := void;

//! (ctor)
ConfigManager._constructor ::= fn(Bool autoSave = false){
    this._autoSave = autoSave;
};


ConfigManager.getFilename ::= fn(){
	return this._filename;
};

/*!	Get a config-value. 
	If the value is not set, the default value is returned and memorized.	*/
ConfigManager.getValue ::= fn( key, defaultValue = void){
	var fullKey = key.toString();
	var group = this._data;
	
	// Key is subgroup key
	if(key.contains(".")){
		var groupNames = key.split(".");
		key = groupNames.popBack();
		foreach(groupNames as var groupName){
			var newGroup = group[groupName];
			if(! (newGroup---|>Map) ){
				if( void!==defaultValue )
					setValue(fullKey,defaultValue);
				return defaultValue;
			}
			group = newGroup;
		}
	}
		
	var value = parseJSON(toJSON(group[key])); // deep copy
    if(void===value){
        if(void!==defaultValue)
            setValue(fullKey,defaultValue);
        return defaultValue;
    }
    return value;
};

/*! Load a json-formatted config file and store the filename.
	\return true on success */
ConfigManager.init ::= fn( filename, warnOnFailure = true ){
    this._filename = filename;
    try{
        var s = IO.fileGetContents(filename);
        var c = parseJSON(s);
        if(c---|>Map){
            this._data = c;
        }
        else{
            this._data = new Map;
        }
    }catch(e){
    	if(warnOnFailure)
			Runtime.warn("Could not load config-file("+filename+"): "+e);
        return false;
    }	
    return true;
};

//! Save configuration to file. 
ConfigManager.save ::= fn( filename = void){
    if(!filename){
        filename = this._filename;
    }
    var s = toJSON(this._data);
    if(s.length()>0){
        IO.filePutContents(filename,s);
    }
};

//! Set a short info-string for a config entry
ConfigManager.setInfo ::= fn( key, value){
	this.setValue(key+" (INFO)",value);
};


/*! Store a copy of the value with the given key.
	If the key contains dots (.), the left side is interpreted as a subgroup. 
	If the value is void, the entry is removed.
	\example 
		setValue( "Foo.bar.a1" , 2 );
		---> { "Foo" : { "bar : { "a1" : 2 } } }
	\note if autoSave is true, the config file is saved immediately
	*/
ConfigManager.setValue ::= fn( key, value){
	if(void===value){
		unsetValue(key);
		return;
	}
	var group = this._data;
	if(key.contains(".")){
		var groupNames = key.split(".");
		key = groupNames.popBack();
		foreach(groupNames as var groupName){
			var newGroup = group[groupName];
			if(! (newGroup---|>Map) ){
				newGroup = new Map;
				group[groupName] = newGroup;
			}
			group = newGroup;
		}
	}
	var newJSON = toJSON(value);
	if(toJSON(group[key]) != newJSON){ // data changed?
		group[key]=parseJSON(newJSON);// deep clone
		if(_autoSave)
			save();
	}
};

ConfigManager.unsetValue ::= fn(key){
	var group = this._data;
	
	// Key is subgroup key
	var groupNames = key.split(".");
	key = groupNames.popBack();
	foreach(groupNames as var groupName){
		group = group[groupName];
		if(! (group---|>Map) )
			return;
	}
	
	group.unset(key);
	if(_autoSave)
		save();
};
ConfigManager.unset ::= ConfigManager.unsetValue;
// -----------------

// system' main config manager
GLOBALS.systemConfig := new ConfigManager;

// compatibility interface
GLOBALS.getConfigValue := systemConfig->systemConfig.getValue;
GLOBALS.loadConfig := systemConfig->systemConfig.init;
GLOBALS.saveConfig  := systemConfig->systemConfig.save;
GLOBALS.setConfigInfo := systemConfig->systemConfig.setInfo;
GLOBALS.setConfigValue := systemConfig->systemConfig.setValue;


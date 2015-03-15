/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	plugins/LibGuiExt/PresetManager.escript
 ** 2012-06 Claudius
 **/
 
 /*!
	A PresetManager manages different values for a group of settings (=an ExtObject or Map having several Std.DataWrapper-members or entries) and creates a corresponding GUI.
	The presets are stored by a ConfigManager.
	
	Example for a GUI:
	
		Preset |_default_______|[>] * [+] [X]
				|				|	|	|	|
				|				|	|	|	Delete current preset
				|				|	|	Save current preset
				|				|	Unchanged changes
				|				Select from list of all presets
				Name of active preset

	\code
		// create a settings-object having two entries
		var settings = new ExtObject({
			$value1 : Std.DataWrapper.createFromValue( "" ).setOptions([ "a","b"]),
			$value2 : Std.DataWrapper.createFromValue( 42 )
		});
		var presetManager = new PresetManager( myConfigManager, 'MyPlugin', settings );
		
		// create the configuration gui
		presetManager.createGUI( myGUIPanel );
		
		// create gui elements for the entries 
		myGUIPanel += {	GUI.TYPE : GUI.TYPE_TEXT,		GUI.LABEL : "value1",		GUI.DATA_WRAPPER : settings.value1 };
		myGUIPanel += {	GUI.TYPE : GUI.TYPE_NUMBER,		GUI.LABEL : "value2",		GUI.DATA_WRAPPER : settings.value2 };
	};
 
 */

var T = new Type;
T._printableName ::= $T;

T.config @(private) := void;
T.keyBase @(private) := void;
T.settings @(private) := void;
T.activePreset @(private) := void;
T.configChanged @(private) := void;

//! (ctro)
T._constructor ::= fn(Std.JSONDataStore _config,String _keyBase,[ExtObject,Map] _settings){
	config = _config;
	keyBase = _keyBase+'.';
	
	settings = _settings.isA(Map) ? _settings.clone() : _settings._getAttributes();

	activePreset = Std.DataWrapper.createFromEntry( config, keyBase + 'activePreset', "default" );
	configChanged = Std.DataWrapper.createFromValue( false );
	
	// whenever a setting changes, set configChanged to true
	foreach(settings as var dataWrapper)
		dataWrapper.onDataChanged += configChanged -> fn(d){	this(true);	};

	// Possible default values for activePreset are the names of the available presets
	activePreset.setOptionsProvider(this->fn(){
		var options = [];
		foreach( config.getValue(keyBase + 'presets',new Map()) as var name,var data )
			options += name;
		return options;
	});
	// If the active presetName changes, update the settings using the corresponding preset.
	activePreset.onDataChanged += this -> fn(presetName){
		var preset = config.getValue(keyBase + 'presets.'+presetName,new Map());
		if(!preset.empty()){
			foreach(settings as var key,var dataWrapper)
				dataWrapper( preset.get(key, dataWrapper.getOptions().front() ) );
			configChanged(false);
		}else{
			configChanged(true);
		}
	};
	activePreset.forceRefresh(); // init data
};

T.createGUI ::= fn(GUI.Container container){
	container+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Preset",
		GUI.DATA_WRAPPER : activePreset,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -80 ,15 ],
	};
	container+={
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "",
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , 20 ,15 ],
		GUI.DATA_WRAPPER : configChanged
	};
	container+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "+",
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , 20 ,15 ],
		GUI.ON_CLICK : this->storeActivePreset,
		GUI.TOOLTIP : "Save current settings as preset."
	};
	container+={
		GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
		GUI.LABEL : "X",
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , 20 ,15 ],
		GUI.ON_CLICK : this->removeActivePreset,
		GUI.TOOLTIP : "Delete the current preset."
	};
};

T.getPresetNames ::= fn(){	return activePreset.getOptions();	};

T.removeActivePreset ::= fn(newPreset="default"){
	var presets = config.getValue(keyBase + 'presets').clone();
	presets.unset( activePreset() );
	config.setValue(keyBase + 'presets',presets);
	activePreset(newPreset);
};

T.selectPreset ::= fn(String presetName){	activePreset(presetName);	};
T.storeActivePreset ::= fn(){	
	var m = new Map;
	foreach(settings as var key,var dataWrapper )
		m[key] = dataWrapper();
	config.setValue(keyBase + 'presets.'+activePreset(),m);
	configChanged(false);
};

return T;
// ------------------------------------------------------------------

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
 **	[PADrend] LibGUIExt/ComponentRegistry.escript
 **/
// -----------
// Component registry

/*! Register a parameterless function that is called whenever a provider is added
	or removed for the given componentId. */
GUI.GUI_Manager.addComponentProviderListener ::= fn(String componentId,handler){
	if(!this.isSet($_registeredComponentsListeners))
		this._registeredComponentsListeners @(private) := new Map;
	if(!this._registeredComponentsListeners[componentId])
		this._registeredComponentsListeners[componentId] = new Std.MultiProcedure;
	this._registeredComponentsListeners[componentId] += handler;
};

/*!	Returns an array of filtered elements(=component descriptions) for the given componentId.*/
GUI.GUI_Manager.createRegisteredComponentEntries_filtered ::= fn(String componentId,filter, context...){
	var providers = this._getComponentProviderRegistry()[componentId];
	if(!providers)
		return [];
	
	//! optionally filter the provider entries
	if(filter)
		providers = filter(providers.clone());
	
	var entries = [];
	foreach(providers as var provider){
		if(provider.isA(Array)){ // list of entries
			entries.append(provider);
		}else if(provider.isA(Map)){ // single entry
			entries+=provider;
		}else{ // function creating entries
			var a = provider(context...);
			if(a.isA(Array))
				entries.append(a);
			else
				entries += a;
		}
	}
	return entries;
};
/*!	Returns an array of elements(=component descriptions) for the given componentId.*/
GUI.GUI_Manager.createRegisteredComponentEntries ::= fn(String componentId,context...){
	return createRegisteredComponentEntries_filtered(componentId,void,context...);
};

GUI.GUI_Manager.getRegisteredComponentProviders ::= fn(String id ){
	var p = this._getComponentProviderRegistry();
	return (p && p[id]) ? p[id].clone() : new Map;
};

//! (internal) May only be accessed externally for debugging.
GUI.GUI_Manager._getComponentProviderRegistry ::= fn( ){
	if(!this.isSet($_componentProviderRegistry))
		this._componentProviderRegistry @(private) := new Map;
	return this._componentProviderRegistry;
};
GUI.GUI_Manager.hasRegisteredComponentProvider ::= fn(String id ){
	var p = this._getComponentProviderRegistry();
	return (p && p[id]) ? true : false;
};

/*! Register a function for creating gui components(e.g. menu or toolbar entries).
	\param componentId The identifier of the group of components; if the entries provided by the provider
			correspond to a group of entries and not a whole menu, add a
			group name after the menuId separated by a '.'. 
			The groups are ordered by their name.
	\param providerOrEntries 
			1. A function returning an array of menu entries.
			The function may get a context parameter -- then it may only be called
			using a proper context object.
			2. A static array containing the entries' descriptions.
	\note If the same combination of menuId and groupId is used again, only the last
		providerOrEntries is used. If no groupId is provided, the providers are appended.
		
	\example 
		// menu with group and provider
		gui.register("MyPlugin_SomeMenuName.group1",fn(){
					return [ "*Group 1*","some actions..." ]; });

		// static menu with group
		gui.register("MyPlugin_SomeMenuName.group2", 
					[ "*Group 2*","some actions..." ] );

		// menu without group
		gui.register("MyPlugin_SomeOthersMenuName",fn(){
					return [ "action1","action2" ]; });

		// context menu
		gui.register("MyPlugin_SomeContextMenu",fn(myObject){
					return [ "action for "+myObject.name ]; });

		// open a registered menu
		gui.openMenu( new Geometry.Vec2(100,100), "MyPlugin_SomeMenuName" );

		// open a registered context menu
		gui.openMenu( new Geometry.Vec2(100,100), "MyPlugin_SomeContextMenu", myObject );
*/
GUI.GUI_Manager.registerComponentProvider ::= fn(String componentId,providerOrEntries){
	var group;
	if(componentId.contains('.')){
		var pos = componentId.rFind('.');
		group = componentId.substr(pos+1);
		componentId = componentId.substr(0,pos);
	}else{
		if(!thisFn.isSet($groupNr))
			thisFn.groupNr := 0;
		group = "__"+ (++thisFn.groupNr);
	}
	var reg = _getComponentProviderRegistry();
	if(!reg[componentId]){
		reg[componentId] = new Map;
	}
	if(reg[componentId][group])
		Runtime.warn("Overwriting existing component provider '"+componentId+"."+group+"'");
	reg[componentId][group] = providerOrEntries;
	
	// notify listeners
	if(this.isSet($_registeredComponentsListeners) && _registeredComponentsListeners[componentId])
		this._registeredComponentsListeners[componentId]();
	return this;
};
GUI.GUI_Manager.register ::= GUI.GUI_Manager.registerComponentProvider; // alias

/*! Remove a registered component provider or subgroup. */
GUI.GUI_Manager.unregisterComponentProvider ::= fn(String componentId){
	var reg = _getComponentProviderRegistry();

	if(componentId.contains('.')){
		var pos = componentId.rFind('.');
		var group = componentId.substr(pos+1);
		componentId = componentId.substr(0,pos);
		if(reg[componentId])
			reg[componentId].unset(group);
	}else{
		reg.unset(componentId);
	}
	// notify listeners
	if(this.isSet($_registeredComponentsListeners) && _registeredComponentsListeners[componentId])
		this._registeredComponentsListeners[componentId]();
	return this;
};

// ------------------------------------

return true;
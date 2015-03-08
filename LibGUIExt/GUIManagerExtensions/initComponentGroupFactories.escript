/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[LibGUIExt] Factory_ComponentGroup.escript
 **/

module('../FactoryConstants');

/*!	Create an Array of components from a given ...
	 ... A components description
		GUI.TYPE		GUI.TYPE_COMPONENTS  normal components
						GUI.TYPE_MENU_ENTRIES components inside a menu
		GUI.PROVIDER	Id, Array or callable provider creating entries
		GUI.WIDTH		(optional) component's width
		GUI.FILTER		(optional) filter function fn(Map componentProviders) called before creating the components.
		GUI.CONTEXT		(optional) context object passed to the component providers
			or
		GUI.CONTEXT_ARRAY	(optional) context objects passed to the component providers
	 ... Array of descriptions,
	 ... registered String identifier \see ComponentRegistry
	 ... a callable provider. 
*/
GUI.GUI_Manager.createComponents ::= fn( mixed ){
	return this._createComponents( mixed );
};

GUI.GUI_Manager._createComponents @(private) ::= fn( mixed,entryWidth=false,insideMenu=false, filter=void, context... ){
	if(mixed---|>Map){ // ignore the other parameters
		var descr = mixed;
		var type = descr.get(GUI.TYPE,GUI.TYPE_COMPONENTS);
		var provider = descr.get(GUI.PROVIDER,"No Component provider given!");
		var width = descr.get(GUI.WIDTH,false);
		
		var contextArray;
		if(void!=descr.get(GUI.CONTEXT))
			contextArray = [descr.get(GUI.CONTEXT)];
		else if(descr.get(GUI.CONTEXT_ARRAY))
			contextArray = descr.get(GUI.CONTEXT_ARRAY);
		
		if(type == GUI.TYPE_MENU_ENTRIES){
			return (void==contextArray) ? this._createComponents(provider,width,true, descr[GUI.FILTER]) : this._createComponents(provider,width,true, descr[GUI.FILTER],contextArray...);
		}else if(type == GUI.TYPE_COMPONENTS){
			return (void==contextArray) ? this._createComponents(provider,width,false,descr[GUI.FILTER]) : this._createComponents(provider,width,false,descr[GUI.FILTER],contextArray...);
		}
		Runtime.warn("GUI.GUI_Manager.createComponents: Unknown Components-Type '"+type+"'");
		return [];
	}else{
		var entries;
		
		if(mixed.isA(Array)){
			entries = mixed;
		}else if(mixed.isA(String)){ // registered components provider
			//! \see ComponentRegistry
			entries = this.createRegisteredComponentEntries_filtered(mixed, filter,context...);
			assert(entries.isA(Array));
		}else if(mixed.isA(GUI.Component)){
			entries = [mixed];
		}else {
			Traits.requireTrait(mixed,Traits.CallableTrait);
			entries = mixed(context...);
			assert(entries.isA(Array));
		}
		
		var result = [];
		foreach(entries as var c)
			result += this.createComponent(c,entryWidth,insideMenu);
		return result;
	}
};

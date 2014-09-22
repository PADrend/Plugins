/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2008-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
//!  Plugin

static T = new Type;
	
T._printableName @(override) ::= $Plugin;

T._pluginProperties @(private) := void;
T.extensionPoints @(private,init) := Map; // name -> ExtensionPoint: The Plugin's own extension points.

T.NAME ::= 'name';
T.DESCRIPTION ::= 'description';
T.CONTRIBUTORS ::= 'contributors';
T.LICENSE ::= 'license';
T.VERSION ::= 'version';
T.AUTHORS ::= 'authors';
T.OWNER ::= 'owner';
T.REQUIRES ::= 'requires';
T.EXTENSION_POINTS ::= 'extensionPoints';
T.BASE_FOLDER ::= 'baseFolder';
T.PLUGIN_FILE ::= 'pluginFile';

/*! Properties:
		NAME 			: name of the plugin,
		DESCRIPTION 	: a short description of the plugin

	Optional:
		VERSION 	: (Number) version of the plugin (e.g. 2.7),
		AUTHORS 	: (String) main author(s) of the plugin (e.g. "Hans Hase & Petra Hummel")
		OWNER 		: (String) who is responsible for that plugin and is allowed to make changes (can be "All")
		CONTRIBUTORS: (String) If someone adds a minor part to the plugin, he/she can be added to this list.
		LICENSE 	: (String) e.g. "Mozilla Public License, v. 2.0", PublicDomain or PROPRIETARY

		REQUIRES 	: Array of other plugins that are needed for this plugin
	Experimental:
		EXTENSION_POINTS : Array of extension points' names provided by this plugin
*/
T._constructor ::= fn( Map properties){
	_pluginProperties = properties.clone();
};
T.addExtensionPoint		::= fn(name,ExtensionPoint ep){	extensionPoints[name] = ep;	};
T.getBaseFolder			::= fn(){	return this._pluginProperties[T.BASE_FOLDER];	};
T.getDescription		::= fn(){	return this._pluginProperties[T.DESCRIPTION];	};
T.getExtensionPoints	::= fn(){	return this._pluginProperties[T.EXTENSION_POINTS];	};
T.getName 				::=	fn(){	return this._pluginProperties[T.NAME];	};
T.getPluginProperties 	::= fn(){	return this._pluginProperties;	};
T.getVersion 			::= fn(){	return this._pluginProperties[T.VERSION];	};
T.getPluginProperty		::= fn(key){	return this._pluginProperties[key];	};
T.setPluginProperty		::= fn(key,value){	this._pluginProperties[key] = value;	};

//!	---o
T.init := fn(){	return true;	};

Std.info += [T,fn(plugin,Array result){
	result += "------";
	result += "This plugin has the following properties:";
	foreach(plugin.getPluginProperties() as var key,var value ){
		result += " '"+key+"' :\t"+toJSON(value,false);
	}
}];


// -------------------------------------------------

/*! Marks a Plugin-object as reloadable.
	Adds the following methods:
	 + onRemovePlugin	a MultiProcedure called when the plugin is removed.	*/
Util.ReloadablePluginTrait := new Traits.GenericTrait('Util.ReloadablePluginTrait');
{
	var t = Util.ReloadablePluginTrait;
	t.attributes.onRemovePlugin @(init) := MultiProcedure;
	t.onInit += fn(T plugin){};
}

Util.Plugin := T;


GLOBALS.Plugin := T; // global alias



return T;

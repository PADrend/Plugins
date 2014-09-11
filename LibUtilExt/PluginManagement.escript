/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2008-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[LibUtilExt] PluginManagement.escript
 ** Plugin management
 **/
 
loadOnce(__DIR__+"/Extension.escript");
 if(EScript.VERSION < 607){ // deprecated
	loadOnce(__DIR__+"/deprecated/EScript_Utils.escript");
	loadOnce(__DIR__+"/deprecated/EScript_info.escript");
 }

// -------------------------------------------------
// --- Plugin


Util.Plugin := new Type;


GLOBALS.Plugin := Util.Plugin; // global alias
{
	var T = Util.Plugin;
		
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
	T.getBaseFolder			::= fn(){	return this._pluginProperties[Plugin.BASE_FOLDER];	};
	T.getDescription		::= fn(){	return this._pluginProperties[Plugin.DESCRIPTION];	};
	T.getExtensionPoints	::= fn(){	return this._pluginProperties[Plugin.EXTENSION_POINTS];	};
	T.getName 				::=	fn(){	return this._pluginProperties[Plugin.NAME];	};
	T.getPluginProperties 	::= fn(){	return this._pluginProperties;	};
	T.getVersion 			::= fn(){	return this._pluginProperties[Plugin.VERSION];	};
	T.getPluginProperty		::= fn(key){	return this._pluginProperties[key];	};
	T.setPluginProperty		::= fn(key,value){	this._pluginProperties[key] = value;	};

	//!	---o
	T.init := fn(){	return true;	};

	info += [T,fn(plugin,Array result){
		result += "------";
		result += "This plugin has the following properties:";
		foreach(plugin.getPluginProperties() as var key,var value ){
			result += " '"+key+"' :\t"+toJSON(value,false);
		}
	}];
}

// -------------------------------------------------

/*! Marks a Plugin-object as reloadable.
	Adds the following methods:
	 + onRemovePlugin	a MultiProcedure called when the plugin is removed.	*/
Util.ReloadablePluginTrait := new Traits.GenericTrait('Util.ReloadablePluginTrait');
{
	var t = Util.ReloadablePluginTrait;
	t.attributes.onRemovePlugin @(init) := MultiProcedure;
	t.onInit += fn(Util.Plugin plugin){};
}


// -------------------------------------------------
// --- Plugin Management
static _pluginRegistry = new Map;

/*! (public) Load plugins.
	 - If a plugin name instead of a filename is given, "searchPath/PluginName/Plugin.escript" is assumed.
	 - The file has to return a Plugin - Object.
	 - Plugins in the "required"-attribute of a plugin are automatically added to the list of loaded plugins.
	 - The init() function of the new Plugins is executed.	*/
Util.loadPlugins @(public) := fn( Array filenames, showNotification = true, Array searchPaths = [__DIR__+"/../"] ){
	var loadedPlugins = new Map;

	// 1. load plugin scripts
	{
		var todo = filenames.clone();
		while(!todo.empty()){
			var pluginName = todo.popFront(); // guess the plugin's name from the filename (temporary)
			
			// already loaded?
			// \todo This is not bullet proof as the pluginName at this point is only guessed from the plugin's file.
			//       A proper solution should check for the real path name...
			if(queryPlugin(pluginName)){
				Runtime.log(Runtime.LOG_ERROR,"Plugin '"+pluginName+"' has already been loaded. Skipping...");
				continue;
			}
			
			var filename = Util.locatePlugin(pluginName,searchPaths);

			if(!filename){
				Runtime.log(Runtime.LOG_ERROR,"Could not find plugin file: '"+pluginName+"'");
				continue;
			}
			var plugin;
			try{
				plugin = load(filename);
				if(! (plugin ---|> Plugin)){
					Runtime.log(Runtime.LOG_ERROR,"loadPlugin('"+filename+"') :\t No Plugin-Object returned.");
					continue;
				}
			}catch(e){
				Runtime.log(Runtime.LOG_ERROR,"Error while loading Plugin '"+filename+"':\n"+e);
				continue;
			}
			// get the plugin's real name 
			pluginName = plugin.getName(); 
			plugin.setPluginProperty(Plugin.BASE_FOLDER, IO.condensePath(IO.dirname(filename)));
			plugin.setPluginProperty(Plugin.PLUGIN_FILE, filename);

			var requiredPlugins = plugin.getPluginProperty( Plugin.REQUIRES );
			if(requiredPlugins){
				var failure = false;
				foreach(requiredPlugins as var p){
					if(queryPlugin(p) || todo.contains(p)){
						continue;
					}
					var requiredPluginFilename = Util.locatePlugin(p,searchPaths);
					if(requiredPluginFilename){
						todo.pushBack(requiredPluginFilename);
					}else{
						Runtime.log(Runtime.LOG_ERROR,"Could not find Plugin '"+p+"' required by '"+plugin.getName()+"'");
						failure = true;
						continue;
					}
				}
				if(failure)
					continue;
			}
			loadedPlugins[pluginName] = plugin;
		}
	}

	{	// 2. create extension points
		foreach(loadedPlugins as var pluginName, var plugin){
			try{
				var extPoints = plugin.getExtensionPoints();
				if(extPoints){
					foreach(extPoints as var mixed){
						var name = mixed;
						var flags = 0;
						if(mixed---|>Array){
							name = mixed[0];
							flags = mixed[1];
						}
						plugin.addExtensionPoint(name,ExtensionPoint.create(name,flags));
					}
				}
			}catch(e){
				Runtime.log(Runtime.LOG_ERROR,"Error while creating extension points for Plugin '"+pluginName+"':\n"+e);
			}
		}
	}

	// 3. sort plugins by requirements
	var orderedPlugins = [];
	{
		var todo = [];
		foreach(loadedPlugins as var p)	
			todo += p;

		var progress = true;
		while( progress ){
			progress = false;
			var newTodo =[];
			foreach(todo as var plugin){
				var ok = true;
				var requiredPlugins = plugin.getPluginProperty( Plugin.REQUIRES );
				if(requiredPlugins){
					foreach(requiredPlugins as var reqPluginName){
						if(!queryPlugin(reqPluginName)){
							ok = false;
							break;
						}
					}
				}
				if(ok){
					orderedPlugins += plugin;
					progress = true;
					_pluginRegistry[plugin.getName()] = plugin;
				}else {
					newTodo += plugin;
				}
			}
			todo.swap(newTodo);
		}
		if(!todo.empty()){
			var pluginsWithOpenRequirements = [];
			foreach(todo as var p)
				pluginsWithOpenRequirements+=p.getName();
			Runtime.log(Runtime.LOG_ERROR,"Could not init all plugins, probably because of a cyclic dependency: "+pluginsWidthOpenRequirements.implode(","));
		}
	}

	// 4. init  plugins
	foreach(orderedPlugins as var plugin){
		var pluginName = plugin.getName();
		try{
			if(showNotification)
				out("Initializing ",pluginName,"...\n");

			var success = plugin.init();
			if(!success && showNotification){
				outln( " - failed" );
			}else if (!success){
				outln(("Initializing ["+pluginName+"]").fillUp(40," "),"failed");
			}else{
				var listeners = onPluginListener[pluginName];
				if(listeners){
					listeners( plugin );
					listeners.clear();
				}
			}
		}catch(e){
			Runtime.log(Runtime.LOG_ERROR,"Error while initializing Plugin '"+pluginName+"':\n"+e);
		}
	}
};

//! (internal)
Util.locatePlugin := fn(filename,Array searchPaths){
	if(filename.endsWith(".escript") && IO.isFile(filename)) {
		return filename;
	}
	foreach( searchPaths as var searchPath){
		if( IO.isFile(searchPath+filename+"/Plugin.escript"))
			return searchPath+filename+"/Plugin.escript";
		if( IO.isFile(searchPath+filename+".escript"))
			return searchPath+filename+".escript";
	}
	return false;
	
};

Util.reloadPlugin := fn(Util.Plugin plugin){
	Traits.requireTrait(plugin,Util.ReloadablePluginTrait);					//!	\see Util.ReloadablePluginTrait
	plugin.onRemovePlugin();												//!	\see Util.ReloadablePluginTrait
	var name = plugin.getName();
	var filename = plugin.getPluginProperty(Plugin.PLUGIN_FILE);
	_pluginRegistry[name] = void;
	Util.loadPlugins([filename],true);
};

//! Return the required plugin or throw an exception.
Util.requirePlugin @(public) := fn(name,minVersion = void) {
	var p = _pluginRegistry[name];
	if (!p) {
		Runtime.log(Runtime.LOG_ERROR,"Reqired Plugin '"+name+"' was not found!");
		return void;
	}
	if (!(minVersion===void) && p.getVersion()<minVersion) {
		Runtime.log(Runtime.LOG_ERROR,"Reqired Plugin '"+name+"' too old! "+minVersion+":"+v);
		return void;
	}
	return p;
};

//! (public)
Util.queryPlugin @(public) := fn(name,minVersion = void) {
	var p = _pluginRegistry[name];
	if (!p || (!(minVersion===void) && p.getVersion()<minVersion) ) {
		return false;
	}
	return p;
};

//! (public)
Util.getPluginRegistry @(public) := fn() {
	return _pluginRegistry;
};
static onPluginListener = new Map;
Util.onPlugin @(public) :=  fn( String pluginName, callback ){
	var p = Util.queryPlugin(pluginName);
	if( p ){
		callback( p );
	}else{
		if( !onPluginListener[pluginName] ) 
			onPluginListener[pluginName] = new Std.MultiProcedure;
		onPluginListener[pluginName] += callback;
	}
};

//----------------------

GLOBALS.loadPlugins := Util.loadPlugins;
GLOBALS.requirePlugin := Util.requirePlugin;
GLOBALS.queryPlugin := Util.queryPlugin;

return Util;

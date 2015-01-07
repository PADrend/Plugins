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
//! Global Plugin registry
 
static ExtensionPoint = module('./ExtensionPoint');
static ExtensionRegistry = module('./GlobalExtensionRegistry');
static Plugin = module('./PluginType');

static _pluginRegistry = new Map;
static onPluginListener = new Map;

static N = new Namespace;

//! Should be set to the List of EScript-module search paths. This allows for guessing the  plugin's theoretical module id (modules don't have module ids).
N.modulePathPrefixes := [];

/*! (public) Load plugins.
	 - If a plugin name instead of a filename is given, "searchPath/PluginName/Plugin.escript" is assumed.
	 - The file has to return a Plugin - Object.
	 - Plugins in the "required"-attribute of a plugin are automatically added to the list of loaded plugins.
	 - The init() function of the new Plugins is executed.	*/
N.loadPlugins := fn( Array filenames, showNotification = true, Array searchPaths = [__DIR__+"/../"] ){
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
			
			var filename = N.locatePlugin(pluginName,searchPaths);

			if(!filename){
				Runtime.log(Runtime.LOG_ERROR,"Could not find plugin file: '"+pluginName+"'");
				continue;
			}
			var guessedModuleName; // the guessed module name is used to inject a module(...) command into the plugin file, that allows using relatvie module names.
			{
				var filePath = IO.condensePath(filename);
				foreach(N.modulePathPrefixes as var sp){
					if(filePath.beginsWith(sp)){
						guessedModuleName = filePath.substr(sp.length());
						break;
					}
				}else{
					guessedModuleName = filePath;
				}
				if(guessedModuleName.endsWith(".escript"))
					guessedModuleName = guessedModuleName.substr(0,-".escript".length());
//				outln("guessedModuleName: ",guessedModuleName);
			}
			
			var plugin;
			try{
				plugin = load(filename,{$module : Std.require.createLoader(guessedModuleName)});
				if(!plugin.isA(Plugin)){
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
					var requiredPluginFilename = N.locatePlugin(p,searchPaths);
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
						plugin.addExtensionPoint(name, ExtensionRegistry.createExtensionPoint(name,flags));
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
			Runtime.log(Runtime.LOG_ERROR,"Could not init all plugins, probably because of a cyclic dependency: "+pluginsWithOpenRequirements.implode(","));
		}
	}

	// 4. init  plugins
	foreach(orderedPlugins as var plugin){
		var pluginName = plugin.getName();
		try{
			if(showNotification)
				outln("Initializing ",pluginName,"...");

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
N.locatePlugin := fn(filename,Array searchPaths){
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

N.reloadPlugin := fn(Plugin plugin){
	Traits.requireTrait(plugin,Util.ReloadablePluginTrait);					//!	\see Util.ReloadablePluginTrait
	plugin.onRemovePlugin();												//!	\see Util.ReloadablePluginTrait
	var name = plugin.getName();
	var filename = plugin.getPluginProperty(Plugin.PLUGIN_FILE);
	_pluginRegistry[name] = void;
	N.loadPlugins([filename],true);
};

//! Return the required plugin or throw an exception.
N.requirePlugin @(public) := fn(name,minVersion = void) {
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
N.queryPlugin @(public) := fn(name,minVersion = void) {
	var p = _pluginRegistry[name];
	if (!p || (!(minVersion===void) && p.getVersion()<minVersion) ) {
		return false;
	}
	return p;
};

//! (public)
N.getPluginRegistry @(public) := fn() {
	return _pluginRegistry;
};

N.onPlugin @(public) :=  fn( String pluginName, callback ){
	var p = N.queryPlugin(pluginName);
	if( p ){
		callback( p );
	}else{
		if( !onPluginListener[pluginName] ) 
			onPluginListener[pluginName] = new Std.MultiProcedure;
		onPluginListener[pluginName] += callback;
	}
};

//----------------------
Util.loadPlugins := N.loadPlugins;		//! \deprecated alias
Util.locatePlugin := N.locatePlugin;	//! \deprecated alias
Util.reloadPlugin := N.reloadPlugin;	//! \deprecated alias
Util.requirePlugin := N.requirePlugin;	//! \deprecated alias
Util.queryPlugin := N.queryPlugin;		//! \deprecated alias
Util.getPluginRegistry := N.getPluginRegistry;	//! \deprecated alias
Util.onPlugin := N.onPlugin;			//! \deprecated alias

GLOBALS.loadPlugins := N.loadPlugins;	//! \deprecated alias
GLOBALS.requirePlugin := N.requirePlugin;	//! \deprecated alias
GLOBALS.queryPlugin := N.queryPlugin;	//! \deprecated alias

return N;

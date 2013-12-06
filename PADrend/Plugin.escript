/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 David Maicher
 * Copyright (C) 2009-2012 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2012 Sascha Brandt
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:PADrend] PADrend/Plugin.escript
 **
 **/

/***
 **   PADrend ---|> Plugin
 **/
GLOBALS.PADrend := new Plugin({
		Plugin.NAME : 'PADrend',
		Plugin.DESCRIPTION : 'Main application',
		Plugin.VERSION : 0.6,
		Plugin.AUTHORS : "Claudius, Ralf & Benjamin",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['LibUtilExt'],
		Plugin.EXTENSION_POINTS : [

			// -------------------------------------
			// Misc extension points

			/* [ext:PADrend_Init
			 * Called before the main loop starts.
			 *
			 * @result  void
			 */
			['PADrend_Init',ExtensionPoint.ONE_TIME],

			/* [ext:Exit]
			 * Called after initialization (the eventLoop is executed here)
			 * @result  void
			 */
			'PADrend_Start',
			
			/* [ext:PADrend_Exit]
			 * Called before program is closed.
			 * Can be used to free handles, close network connections....
			 * @result  void
			 */
			'PADrend_Exit',
				
			/* [ext:PADrend_Message]
			 * Called by PADrend.message
			 * @param   Message as String
			 * @result  void
			 */
			'PADrend_Message'

		]
});

// -------------------

// options and parameters

PADrend.dataPath @(private) := void; // dataWrapper
PADrend.userPath @(private) := void; // dataWrapper
PADrend.scenePath @(private) := void; // dataWrapper
PADrend.pluginFolders := void; // dataWrapper

// objects
PADrend.frameStatistics := void;

PADrend.configCache := void;

PADrend.syncVars @(public) := void;	// DataWrapperContainer

PADrend.getDataPath := fn(){	return this.dataPath();	};
PADrend.getUserPath := fn(){	return this.userPath();	};
PADrend.getScenePath := fn(){	return this.scenePath();	};

/*! Returns program running time in seconds. If Network support
	is enabled, this time is synchronized between all instances. */
PADrend.getSyncClock := Util.Timer.now;

/**
 * Plugin initialization.
 * ---|> Plugin
 */
PADrend.init := fn(){
    var start = clock();
    
	{	// basic initializations
		registerExtension('PADrend_Message',fn(s){	out("[[--   ",s,"   --]]\n"); });
	
		this.syncVars = new DataWrapperContainer;
		
		if(systemConfig.getValue('PADrend.enableInfoOutput', false)) {
        	Util.enableInfo();
		} else {
			Util.disableInfo();
		}
	
		// Paths
        this.userPath = DataWrapper.createFromConfig(systemConfig,'PADrend.Paths.user',"./");
        this.dataPath = DataWrapper.createFromConfig(systemConfig,'PADrend.Paths.data',"data/");
        this.scenePath = DataWrapper.createFromConfig(systemConfig,'PADrend.Paths.scene',dataPath()+"scene/");

		// assure paths end with "/"
		foreach([this.userPath,this.dataPath,this.scenePath] as var p){
			if(!p().endsWith("/"))
				p( p()+"/" );
		}
	
		// configCache to store persistent data like file histories
		this.configCache = new ConfigManager( true );
		this.configCache.init( systemConfig.getValue('PADrend.configCacheFile',this.userPath()+"config.tmp"),false);
  
        showWaitingScreen.fancy = systemConfig.getValue('PADrend.fancyWaitScreen',false);
	}
	
    {	// PADrend modules

		PADrend.message("Loading PADrend modules...\n");
       
		// Load all modules which are not explicitly disabled.
		var configuredModules = systemConfig.getValue('PADrend.modules',new Map());
		var modulesToLoad=[];
        foreach( {
					"CommandHandling" : true,
					"EventLoop" : true,
					"GUI" : true,
					"Navigation" : true,
					"NodeInteraction" : true,
					"RemoteControl" : true,
					"SceneManagement" : true,
					"Serialization" : true,
					"SplashScreen" : true,
					"SystemUI" : true,
					"UITools" : true
				} as var moduleName, var d){
			if(configuredModules[moduleName] || void==configuredModules[moduleName]){
				modulesToLoad += "PADrend/"+moduleName;
			}
		}
        loadPlugins(modulesToLoad,true,[this.getBaseFolder()+"/../"]);
    }
    
    // init network
	if(Util.isSet($Network)){
		out("Init network system".fillUp(40));
		if(Util.Network.init()){
			Network = Util.Network;
			out( "ok.\n");
		}else{
			out("failed.\n");
		}
	}
	
    {	// Plugins
        PADrend.message("Loading Plugins...\n");
        
		var enabledPluginNames=[];
        foreach( systemConfig.getValue('PADrend.plugins',{
					"Effects" : true,
					"NodeEditor" : true,
					"SceneEditor" : true,
					"Tests" : true,
					"Tools" : true
				}) as var pluginName,var enabled){
			if(enabled)
				enabledPluginNames += pluginName;
		}
		this.pluginFolders = DataWrapper.createFromConfig(systemConfig,'PADrend.Paths.plugins',[
													IO.condensePath(__DIR__+"/../../extPlugins/"),
													IO.condensePath(__DIR__+"/../")]);
		loadPlugins(enabledPluginNames,true, this.pluginFolders() );
    }
    
    
    PADrend.message("Initializing PADrend... (",clock()-start,"s)\n");

	// [ext:PADrend_Init]
    executeExtensions('PADrend_Init');
	PADrend.message("PADrend started in ",(clock()-start).round(0.01)," sec.\n");

	// Execute optional autorun script
	var scriptFile = systemConfig.getValue('PADrend.autorunScript', "");
	if(scriptFile != "") {
		out("Automatic execution of script \"" + scriptFile +"\"...\n");
		try {
			load(scriptFile);
		} catch(e) {
			Runtime.log(Runtime.LOG_ERROR,e);
		}
	}
	// [ext:PADrend_Start] Normally this executes the main event loop.
	executeExtensions('PADrend_Start');
	
	initShutdown();
	return true;
};

PADrend.message := fn(p...){
	var s = p.implode("").trim();
	executeExtensions('PADrend_Message',s);
};

/*! (static) Render the given sceneGraph with the given camera and flags.
	\note If the clearColor is false, the rendering buffer is not cleared before rendering */
PADrend.renderScene := fn( MinSG.Node _rootNode, [MinSG.AbstractCameraNode,void] _camera, Number _renderingFlags, [Util.Color4f,false] _clearColor ){
	renderingContext.setImmediateMode(false);
	// force a reset of the opengl state - this can eventually be removed if the renderingContext is at no position
	// interfered by wrongly placed glPush- and glPopAttribs.
	renderingContext.applyChanges(true);
	// \note The camera has to be enabled before the screen is cleared because it also defines the viewport to clear
	if(_camera) {
		frameContext.setCamera(_camera);
	}
	if(_clearColor) {
		renderingContext.clearScreen(_clearColor);
	}
	frameContext.displayNode(_rootNode,_renderingFlags);
	renderingContext.setImmediateMode(true);
};

PADrend.about := fn(){
	var arr = [];
	arr += "*Maintainers*";
	arr += "Benjamin Eikel <benjamin@eikel.org>";
	arr += "Claudius Jaehn <claudius@uni-paderborn.de>";
	arr += "Ralf Petring <ralf@petring.net>";
	arr += "----";
	arr += "*Contributors*";
	arr += "Mouns R. Husan Almarrani";
	arr += "Sascha Brandt";
	arr += "Robert Gmyr";
	arr += "Paul Justus";
	arr += "Jonas Knoll";
	arr += "Lukas Kopecki";
	arr += "Jan Krems";
	arr += "David Maicher";
	arr += "----";
	arr += "*Plugins*";
		
	foreach(Util.getPluginRegistry() as var plugin) {
		arr += "*" + plugin.getName() + " (version "+ plugin.getVersion() + ")*";
		if( plugin.getPluginProperty(Plugin.AUTHORS) )
			arr +=	"Authors: " + plugin.getPluginProperty(Plugin.AUTHORS);
		if( plugin.getPluginProperty(Plugin.OWNER) )
			arr +=	"Owner: " + plugin.getPluginProperty(Plugin.OWNER);
		if( plugin.getPluginProperty(Plugin.CONTRIBUTORS) )
			arr +=	"Contributors: " + plugin.getPluginProperty(Plugin.CONTRIBUTORS);
		if( plugin.getPluginProperty(Plugin.LICENSE) )
			arr +=	"License: " + plugin.getPluginProperty(Plugin.LICENSE);
		arr += plugin.getDescription();
		arr +="";
	}
	return arr;
	
};

// ---------------------------------------------
// Process lifecycle
PADrend.initShutdown @(private) := fn(){
	message("Shutting down...");
	// [ext:PADrend_Exit] Cleanup...
	executeExtensions('PADrend_Exit');
};
PADrend.quit := fn(){
	initShutdown();
	exit(0);
};
PADrend.restart := fn(){
	initShutdown();
	message("Restarting PADrend... ("+args.implode(" ")+")");
	exec(args[0], args);
};

return PADrend;
// ------------------------------------------------------------------------------

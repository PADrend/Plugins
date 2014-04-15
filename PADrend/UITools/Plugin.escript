/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:PADrend] PADrend/UITools/Plugin.escript
 **/

/*!	A UITool represents one specific user interface tool -- from which globally
	only one can be active at a time. This plugin keeps track of all registered 
	tools and the currently active tool.
	\example

	// Register a new tool:
	PADrend.registerUITool('MyTool')
			.registerActivationListener( myTool->myTool.activate )
			.registerDeactivationListener( myTool->myTool.deactivate );

	// Add a button to a toolbar that changes its switching state according to 
	// the tool:
	gui.registerComponentProvider('PADrend_ToolsToolbar.myTool',{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.ICON : "#myToolIcon",
		GUI.WIDTH : 15,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('MyTool');	},
		GUI.ON_INIT : fn(...){
			var swithFun = fn(b){
				if(isDestroyed())
					return $REMOVE;
				setSwitch(b);
			};
			PADrend.accessUIToolConfigurator('MyTool')
				.registerActivationListener([true]=>this->swithFun)
				.registerDeactivationListener([false]=>this->swithFun);
		}
	});
*/


//!	---|> Plugin
var plugin = new Plugin({
		Plugin.NAME : 'PADrend/UITools',
		Plugin.DESCRIPTION : "User interface tools.",
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend','PADrend/EventLoop'],
		Plugin.EXTENSION_POINTS : []
});

// -------------------

/**
 * Plugin initialization.
 * ---|> Plugin
 */
plugin.init := fn(){
	loadOnce(__DIR__+"/UIToolManager.escript");
	
	PADrend.uiToolsManager := new PADrend.UITools.UIToolManager;
	
	// for debug only
	PADrend.uiToolsManager.onActiveToolChanged += fn(tool){
		if(tool)
			PADrend.message("New UITool: ",tool);
		else
			PADrend.message("UITool disabled.");
	};
	
	registerExtension('PADrend_KeyPressed', fn(evt){
		if(PADrend.uiToolsManager.getActiveTool() && evt.key == Util.UI.KEY_ESCAPE){
			PADrend.deactivateUITool();
			return true;
		}
		return false;
	},Extension.HIGH_PRIORITY);
	
	return true;
};
// ------------------

//! Access the configurator for the given tool.
PADrend.accessUIToolConfigurator := fn(tool){	return uiToolsManager.accessToolConfigurator(tool);	};

/*! Deactivate the current tool.
	\note This may be called during the activation of a tool (e.g. if the tool
		can not be activated). After the remaining activation process is finished the 
		deactivation process is then started afterwards (to leave everything in a clean state).	*/
PADrend.deactivateUITool := fn(){	uiToolsManager.deactivateTool();	};

//! Register a new tool.
PADrend.registerUITool := fn(tool){	return uiToolsManager.registerTool(tool);	};

//! Activate the given tool.
PADrend.setActiveUITool := fn(tool){	uiToolsManager.setActiveTool(tool);	};

return plugin;
// ------------------------------------------------------------------------------

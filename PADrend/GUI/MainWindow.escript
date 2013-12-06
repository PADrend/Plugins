/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[PADrend] PADrend/GUI_Windows.escript
 **/

//! ---|> Plugin
var plugin = new Plugin({
		Plugin.NAME : 'PADrend/GUI/MainWindow',
		Plugin.DESCRIPTION : "PADrend's main window.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend/GUI'],
		Plugin.EXTENSION_POINTS : []
});


//! ---|> Plugin
plugin.init @(override) := fn(){

	// toggle main window on [F1]
	registerExtension( 'PADrend_KeyPressed',this->fn(evt){
		if (evt.key == Util.UI.KEY_F1) { // F1
			if(!gui.windows['Main']){
				gui.windows['Main'] = this.createMainWindow();
			}else{
				gui.windows['Main'].toggleVisibility();
			}
			return true;
		}
		return false;
	},Extension.LOW_PRIORITY); // use low priority to allow the toolbar listener to catch the event before.
	
	registerExtension( 'PADrend_Init',this->fn(){
		gui.registerComponentProvider('PADrend_MainToolbar.25_openMainWindow',{
			GUI.TYPE		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"->",
			GUI.ICON		:	"#WindowSmall",
			GUI.ICON_COLOR	:	GUI.BLACK,
			GUI.ON_CLICK	:	this->fn() { 
					if(!gui.windows['Main']){
						gui.windows['Main'] = this.createMainWindow();
					}else{
						gui.windows['Main'].toggleVisibility();
					}
				},
			GUI.TOOLTIP		:	"Show/Hide Main Window [F1]"
		});
	});
	return true;
};

 //! Creates the main window containing the tabs
plugin.createMainWindow := fn(){

    var width=500;
    var height=450;
    var window=gui.createWindow(width,height,"Main");
    window.setPosition(5,40);
    window.setLogo(gui.getIcon('#PADrendLogoSmall'));
    var pos=0;
    window.tPanel:=gui.createTabbedPanel(width,height,GUI.AUTO_MAXIMIZE);
    window.add(window.tPanel);

	registerExtension('PADrend_OnAvgFPSUpdated',window->fn(fps){
		this.setTitle("Main "+fps+"fps");
	});

    //      __________
    //  ___/   About  \_______________________________________________________________
    // /                                                                              \

	gui.registerComponentProvider('PADrend_MainWindowTabs.90_About',fn(){
		var page = gui.createPanel();
		foreach(PADrend.about() as var entry){
			page+=entry;
			page++;
		}
		
//		page += "*Maintainers*";
//		page++;
//		page += "Benjamin Eikel <benjamin@eikel.org>";
//		page++;
//		page += "Claudius Jaehn <claudius@uni-paderborn.de>";
//		page++;
//		page += "Ralf Petring <ralf@petring.net>";
//		
//		page.nextRow(5);
//		page += GUI.H_DELIMITER;
//		page.nextRow(5);
//		
//		page += "*Contributors*";
//		page++;
//		page += "Sascha Brandt";
//		page++;
//		page += "Robert Gmyr";
//		page++;
//		page += "Paul Justus";
//		page++;
//		page += "Jonas Knoll";
//		page++;
//		page += "Lukas Kopecki";
//		page++;
//		page += "Jan Krems";
//		page++;
//		page += "David Maicher";
//		
//		page.nextRow(5);
//		page += GUI.H_DELIMITER;
//		page.nextRow(5);
//		
//		page += "*Plugins*";
//		page++;
//		foreach(Util.getPluginRegistry() as var plugin) {
//			page += {
//				GUI.TYPE	:	GUI.TYPE_LABEL,
//				GUI.LABEL	:	plugin.getName() + " (version " + plugin.getVersion() + ")",
//				GUI.FONT	:	GUI.FONT_ID_HEADING,
//				GUI.TOOLTIP : "Folder: " + plugin.getBaseFolder(),
//			};
//			page++;
//			if( plugin.getPluginProperty(Plugin.AUTHORS) ){
//				page +=	"Authors: " + plugin.getPluginProperty(Plugin.AUTHORS);
//				page++;
//			}
//			if( plugin.getPluginProperty(Plugin.OWNER) ){
//				page +=	"Owner: " + plugin.getPluginProperty(Plugin.OWNER);
//				page++;
//			}			
//			if( plugin.getPluginProperty(Plugin.CONTRIBUTORS) ){
//				page +=	"Contributors: " + plugin.getPluginProperty(Plugin.CONTRIBUTORS);
//				page++;
//			}
//			if( plugin.getPluginProperty(Plugin.LICENSE) ){
//				page +=	"License: " + plugin.getPluginProperty(Plugin.LICENSE);
//				page++;
//			}
//			
//			page += plugin.getDescription();
//			page.nextRow(15);
//		}
//		
		return {
			GUI.TYPE : GUI.TYPE_TAB,
			GUI.LABEL : "About",
			GUI.TAB_CONTENT : page
		};
	});
    // \______________________________________________________________________________/


    //      __________
    //  ___/   ...    \_______________________________________________________________
    // /                                                                              \
    {
        window.tPanel.addTabs('PADrend_MainWindowTabs');
    }
    // \______________________________________________________________________________/
 
 
	window.tPanel.setActiveTabIndex(0);
 
//    window.setEnabled(visible);
    return window;
};


return plugin;
// ------------------------------------------------------------------

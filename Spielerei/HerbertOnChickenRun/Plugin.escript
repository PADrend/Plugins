/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Lukas Kopecki
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var HoCRPlugin = new Plugin({
                        Plugin.NAME : 'Spielerei/HerbertOnChickenRun',
                        Plugin.DESCRIPTION : "Skeletal Animation example game",
                        Plugin.VERSION : 1.0,
                        Plugin.REQUIRES : [],
                        Plugin.AUTHORS : "Lukas Kopecki",
                        Plugin.OWNER : "All",
                        Plugin.EXTENSION_POINTS : [ ]
                        });

HoCRPlugin.chickenHandler := void;

//! ---|> Plugin
HoCRPlugin.init:=fn(){    
	{ // Register ExtensionPointHandler:
		registerExtension('PADrend_Init',this->fn(){
			gui.registerComponentProvider('Spielerei.hoCR',[{
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "HoCR",
				GUI.MENU : this->fn(){
					var chickenHandler = this.chickenHandler;
					var entries =[];
					entries += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "start",
						GUI.ON_CLICK : this->fn(){
										loadOnce(__DIR__+"/ChickenHandler.escript");
										var scene = new MinSG.ListNode();
										PADrend.selectScene(scene);
							
										this.chickenHandler = new ChickenHandler(scene, 10);
										}
					};
					entries += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "restart",
						GUI.ON_CLICK : this->fn(){
							out("Implement Me, iam so alone!\n");
						}
					};
					return entries;
				}
			}]);
		});
        registerExtension('PADrend_AfterRendering',this->this.ex_AfterRendering);
    }
    return true;
};



HoCRPlugin.ex_AfterRendering := fn(...)
{
    if(this.chickenHandler)
        this.chickenHandler.loop();
};


// ---------------------------------------------------------
return HoCRPlugin;

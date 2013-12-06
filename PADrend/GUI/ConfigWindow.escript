/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2008-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2007-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010-2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[PADrend] PADrend/GUI/ConfigWindow.escript
 **/

//! ---|> Plugin
var plugin = new Plugin({
		Plugin.NAME : 'PADrend/GUI/ConfigWindow',
		Plugin.DESCRIPTION : "Additional config window.",
		Plugin.VERSION : 2.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend/GUI'],
		Plugin.EXTENSION_POINTS : []
});

plugin.window := void;

//! ---|> Plugin
plugin.init @(override) := fn(){

	//! add menu entry to config menu. \see MainToolbar.escript
	registerExtension( 'PADrend_Init',this->fn(){
		// additional settings group
		gui.registerComponentProvider('PADrend_ConfigMenu.40_additionalSettings',[
			'----',
			{
				GUI.LABEL		:	"Additional settings ...",
				GUI.ON_CLICK	:	this->fn(){
					if(! this.window ){
						window = PADrend.createConfigWindow(10,240);
					}else{
						window.toggleVisibility();
					}
				}
			}
		]);
	});
	
	return true;
};

PADrend.createConfigWindow:=fn(posX,posY){
    var width=260;
    var height=350;
    var window=gui.createWindow(width,height,'Parameter');
    window.setPosition(posX,posY);
    window.tPanel:=gui.createTabbedPanel(width,height,GUI.AUTO_MAXIMIZE);
    window.tPanel.setPosition(0,10);
    window.add(window.tPanel);

    //      ____________
    //  ___/  Observer  \_____________________________________________________________
    // /                                                                              \
    
    gui.registerComponentProvider('PADrend_ConfigWindowTabs.20_Observer',this->fn(){
        var page=gui.createPanel();
        var dolly = PADrend.getDolly();

        if(dolly.getObserverPosition()){
				
        	var pos=dolly.getObserverPosition();
		
			page += {
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.LABEL : "Observer X",
				GUI.RANGE : [-2,2],
				GUI.RANGE_STEPS : 400,
				GUI.DATA_VALUE : dolly.getObserverPosition()[0],
				GUI.ON_DATA_CHANGED : fn(data){	
					var dolly = PADrend.getDolly();
					var p = dolly.getObserverPosition();
					p[0]=data;
					dolly.setObserverPosition(p);	
				}
			};
			page++;
				
			page += {
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.LABEL : "Observer Y",
				GUI.RANGE : [-2,2],
				GUI.RANGE_STEPS : 200,
				GUI.DATA_VALUE : dolly.getObserverPosition()[1],
				GUI.ON_DATA_CHANGED : fn(data){	
					var dolly = PADrend.getDolly();
					var p = dolly.getObserverPosition();
					p[1]=data;
					dolly.setObserverPosition(p);	
				}
			};
			page++;
			
			page += {
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.LABEL : "Observer Z",
				GUI.RANGE : [-2,2],
				GUI.RANGE_STEPS : 400,
				GUI.DATA_VALUE : dolly.getObserverPosition()[2],
				GUI.ON_DATA_CHANGED : fn(data){
					var dolly = PADrend.getDolly();
					var p = dolly.getObserverPosition();
					var old = p[2];
					p[2]=data;
					dolly.setObserverPosition(p);	
					dolly.moveLocal(new Geometry.Vec3(0,0,(data-old)*5));
				}
			};
			page++;
        }
		return {
			GUI.TYPE : GUI.TYPE_TAB,
			GUI.TAB_CONTENT : page,
			GUI.LABEL : "Observer"
		};

    });
    // \______________________________________________________________________________/

   
    //      __________
    //  ___/   ...    \_______________________________________________________________
    // /                                                                              \
    {
		window.tPanel.addTabs('PADrend_ConfigWindowTabs');
    }
    // \______________________________________________________________________________/

    return window;
};

return plugin;
// ------------------------------------------------------------------

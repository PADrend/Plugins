/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2015 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Test/Tests_GUI.escript
 **/
static gui;

var plugin = new Plugin({
		Plugin.NAME : 'Tests/Tests_GUI',
		Plugin.DESCRIPTION : 'For testing new gui features...',
		Plugin.VERSION : 0.2,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [ 'Tests' ],
		Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) :=fn(){
	module.on('PADrend/gui', this->fn(_gui){
		gui = _gui;
		gui.register('Tests_TestsMenu.gui',[
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "GUI Tests",
				GUI.ON_CLICK : fn(){	load(__DIR__+"/showGUIExamples.escript",{$gui:gui});	}
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "GUI memory monitoring",
				GUI.ON_CLICK : showMemoryWindow,
				GUI.TOOLTIP : "All newly created Components are monitored for their destruction."
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Print GUI registry",
				GUI.ON_CLICK : fn(){
//						print_r(gui._getComponentProviderRegistry());
					// print only the groups and not the component themselves 
					var m = new Map;
					foreach(gui._getComponentProviderRegistry() as var groupName,var group){
						m[groupName] = new Map;
						foreach(group as var entryName,var entry)
							m[groupName][entryName] =  entry.toDbgString();
					}
					print_r(m);
				},
				GUI.TOOLTIP : "Print the registered component provider groups to the console."
			}
		]);
	});
	return true;
};


static showMemoryWindow = fn(){

	var memoryWindow = gui.createWindow(320,200,"GUI memory monitor");
	memoryWindow.setPosition(200,20);

	var panel = gui.createPanel(1,1,GUI.AUTO_MAXIMIZE|GUI.AUTO_LAYOUT);
	memoryWindow+=panel;
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Enable/Reset",
		GUI.ON_CLICK : fn(){
			gui._destructionMonitor = new Util.DestructionMonitor();
		}
	};
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Disable",
		GUI.ON_CLICK : fn(){
			gui._destructionMonitor = void;
		}
	};
	panel += GUI.NEXT_ROW;


	panel += "Pending components: ";

	var l = gui.create({
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.LABEL : "......",
		GUI.FONT : GUI.FONT_ID_LARGE
	});
	panel += l;

	Util.registerExtension('PADrend_AfterFrame',[l]=>fn(l){
		if(l.isDestroyed())
			return $REMOVE;
		l.setText( gui._destructionMonitor ? gui._destructionMonitor.getPendingMarkersCount() :"[disabled]" );
	});

	panel += GUI.NEXT_ROW;
	panel += " ";
	panel += GUI.NEXT_ROW;

	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Extract released markers",
		GUI.ON_CLICK : fn(){
			print_r(gui._destructionMonitor.extractMarkers());
		}
	};
	panel += GUI.NEXT_ROW;

	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "getPendingMarkersNames()",
		GUI.ON_CLICK : fn(){
			print_r(gui._destructionMonitor.getPendingMarkersNames());
		}
	};
};


// ---------------------------------------------------------
return plugin;

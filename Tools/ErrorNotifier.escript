/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tools_ErrorNotifier] Tools/ErrorNotifier.escript
 **/


/***
 **   NodeEditorPlugin ---|> Plugin
 **/
var plugin = new Plugin({
		Plugin.NAME : 'Tools_ErrorNotifier',
		Plugin.DESCRIPTION : "Show a notification if an error or a warning occurs.",
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend','PADrend/GUI','PADrend/EventLoop'],
		Plugin.EXTENSION_POINTS : [ ]
});

/*! ---|> Plugin
	Plugin initialization.	*/
plugin.init @(override) := fn() {

	{ // Register ExtensionPointHandler:
		if(systemConfig.getValue('Tools.ErrorNotifier.enabled',true))
			registerExtension('PADrend_AfterFrame',this->this.ex_AfterFrame);
	}
	return true;
};


//!	[ext:PADrend_AfterFrame]
plugin.ex_AfterFrame := fn(...) {

	var observedLogs = [
		[Runtime.LOG_WARNING,"warning", "#WarningSmall"],
		[Runtime.LOG_ERROR,"error", "#ErrorSmall"]
	];

	// --------------------

	var window = gui.create({
		GUI.TYPE : GUI.TYPE_WINDOW,
		GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_CENTER|GUI.ALIGN_X_CENTER|
							GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM, 0,0],
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , 90 ,33 ],
		GUI.FLAGS :  GUI.HIDDEN_WINDOW, //GUI.NO_CLOSE_BUTTON |
	});
	var panel  = gui.create({
		GUI.TYPE : GUI.TYPE_PANEL,
		GUI.FLAGS : GUI.AUTO_LAYOUT | GUI.AUTO_MAXIMIZE,
		GUI.PANEL_MARGIN : 0
	});
	window += panel;
	window.setEnabled(false);

	var observers = [];
	foreach(observedLogs as var level,var props){
		var observer = new ExtObject({
			$level : props[0],
			$icon : props[2],
			$button : gui.create({
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : " ",
				GUI.ON_CLICK : (fn(level){	Runtime.resetLogCounter(level);	}).bindLastParams(props[0]),
				GUI.WIDTH: 40,
				GUI.HEIGHT : 17,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.TOOLTIP : "Number of recent "+props[1]+" log messages.\nClick to reset.\nSee the console output for the message output!"
			}),
			$value : 0,
			$dueTime : 0
		});
		observer.button.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_BUTTON_SHAPE,
			gui._createRectShape(new Util.Color4ub(20,20,20,80),new Util.Color4ub(20,20,20,0),true)));

		panel += observer.button;
		observers+=observer;
	}

	var duration = systemConfig.getValue('Tools.ErrorNotifier.duration',10);
	while(true){
		foreach(observers as var observer){
			var value = Runtime.getLogCounter(observer.level);
			if(value!=observer.value){
				observer.value = value;
				observer.dueTime = clock()+duration;
				observer.button.destroyContents();
				if(value>0){
					observer.button+=gui.create({
						GUI.TYPE : GUI.TYPE_LABEL,
						GUI.LABEL : " "+value,
						GUI.POSITION : [16,3],
						GUI.COLOR : GUI.WHITE
					});
					observer.button+=gui.create({
						GUI.TYPE : GUI.TYPE_ICON,
						GUI.ICON : observer.icon,
						GUI.ICON_COLOR : GUI.WHITE
					});
					observer.button.setFlag(GUI.FLAT_BUTTON,false);
					window.restore();
					window.setEnabled(true);
				}else{
					observer.button.setFlag(GUI.FLAT_BUTTON,true);
				}

				PADrend.planTask(duration+0.1,(fn(observers,window){
					var now = clock();
					var allZero = true;
					foreach(observers as var observer){
						if(observer.value!=0)
							allZero = false;
						if(observer.dueTime>now)
							return;
					}
					if(allZero){
						window.setEnabled(false);
					}
					window.minimize();
				}).bindLastParams(observers,window));
			}
		}
		yield;
	}

	return Extension.REMOVE_EXTENSION;
};


return plugin;
// ------------------------------------------------------------------------------

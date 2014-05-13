/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * 
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var plugin = new Plugin({
		Plugin.NAME : 'Tools/QuickScript',
		Plugin.DESCRIPTION : "Scripting window.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius Jaehn",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) := fn(){
	registerExtension('PADrend_Init', this->fn(){
		gui.registerComponentProvider('Tools_DebugWindowTabs.scriptWidnow',	createTab);
	});
	return true;
};

static createTab = fn(){
	var container = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.SIZE :GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT : GUI.LAYOUT_FLOW
	});
	
	var filename = "./script.tmp";
	var content = "out('Hello World!');";
	if(IO.isFile(filename))
		content = IO.loadTextFile(filename);
		
	var text = new DataWrapper(content);
	text.onDataChanged += [filename]=>fn( filename,str ){
		IO.saveTextFile(filename,str);
	};
	
	var input = gui.create({
		GUI.TYPE : GUI.TYPE_MULTILINE_TEXT,
		GUI.DATA_WRAPPER : text,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_FILL_ABS, 0, GUI.DIM_LINE_HEIGHT]

	});
	container += input;
	container++;
	container+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Execute",
		GUI.ON_CLICK : [text] => fn(text){
			var t = text();
			outln("-"*40,"\nEvaluating: \n",t,"\n","-"*20);
			eval(t);
			outln("\n","-"*40);
		}
	};

	var tab = gui.create({
		GUI.TYPE : GUI.TYPE_TAB,
		GUI.TAB_CONTENT : container,
		GUI.LABEL : "Script",
	});
	return tab;
};

return plugin;
// ------------------------------------------------------------------------------

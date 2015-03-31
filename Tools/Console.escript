/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2009 Jan Krems
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var plugin = new Plugin({
		Plugin.NAME : 'Tools_Console',
		Plugin.DESCRIPTION : "Console window for scripting. Opened with [^] key.",
		Plugin.VERSION : 1.1,
		Plugin.AUTHORS : "Claudius Jaehn",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend/EventLoop'],
		Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) := fn(){
	module.on('PADrend/gui',this->fn(gui){
		gui.register('Tools_DebugWindowTabs.console',	[gui]=>this->createTab);
	});
	return true;
};



plugin.createTab := fn(gui){
	var windowContainer = gui.create({
		GUI.TYPE			:	GUI.TYPE_CONTAINER,
		GUI.SIZE			:	GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT			:	GUI.LAYOUT_FLOW
	});

	var output = gui.create({
		GUI.TYPE			:	GUI.TYPE_PANEL,
		GUI.SIZE			:	[GUI.WIDTH_REL | GUI.HEIGHT_FILL_ABS, 1.0, 25]
	});
	windowContainer += output;
	windowContainer++;

	windowContainer += "----";
	windowContainer++;

	var inputComponent = gui.createTextfield(300, 15, "");
	inputComponent.setExtLayout(
				GUI.POS_X_ABS | GUI.REFERENCE_X_LEFT | GUI.ALIGN_X_LEFT |
				GUI.POS_Y_ABS | GUI.REFERENCE_Y_BOTTOM | GUI.ALIGN_Y_BOTTOM |
				GUI.WIDTH_ABS | GUI.HEIGHT_ABS,
				new Geometry.Vec2(5, 10), new Geometry.Vec2(-83, 15));
	windowContainer += inputComponent;

	var getFocus = [inputComponent] => fn(inputComponent){
		gui.setActiveComponent(inputComponent);
		inputComponent.select();
		inputComponent.activate();
	};
	
	windowContainer += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"execute",
		GUI.ON_CLICK			:	[getFocus, inputComponent, output] => fn(getFocus, inputComponent, outputComponent) {
										var outBackup=out;
										var tmp=new ExtObject;
										tmp.result:="";
										GLOBALS.out:=tmp->fn(p...){
											this.result+=p.implode();
										};
										var s=inputComponent.getText();
										if(s!="")
											inputComponent.addOption(s);
										inputComponent.setCurrentOptionIndex(0);
										inputComponent.setText("");

										getFocus();

										outputComponent+=" > "+s;
										outputComponent.nextRow();

										// execute!
										var result=void;
										try{
											result=eval(s);
										}catch(e){
											var l=gui.create(e.toString());
											l.setColor( new Util.Color4f(0.7,0.0,0.0,1.0) );
											l.setTooltip("Error");
											outputComponent+=l;
											outputComponent.nextRow();
										}
										if( tmp.result!=""){
											var l=gui.create(tmp.result);
											l.setColor( new Util.Color4f(0.0,0.0,0.7,1.0) );
											l.setTooltip("Output");
											outputComponent+=l;
											outputComponent.nextRow();
										}
										if(void!=result) {
											var l=gui.create(result.toString());
											l.setColor( new Util.Color4f(0.0,0.7,0.0,1.0) );
											l.setTooltip("Result");
											outputComponent+=l;
											outputComponent.nextRow();
										}
										GLOBALS.out=outBackup;
									},
		GUI.WIDTH				:	50
	};
	windowContainer += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"X",
		GUI.TOOLTIP				:	"Clear",
		GUI.ON_CLICK			:	[inputComponent,output] => fn(inputComponent, outputComponent) {
										outputComponent.clear();
										inputComponent.clearOptions();
									},
		GUI.WIDTH				:	16
	};
	
	var tab = gui.create({
		GUI.TYPE : GUI.TYPE_TAB,
		GUI.TAB_CONTENT : windowContainer,
		GUI.LABEL : "Console",
	});
	tab.onOpen := getFocus;
	return tab;
};

return plugin;
// ------------------------------------------------------------------------------

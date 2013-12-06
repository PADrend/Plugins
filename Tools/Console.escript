/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2009 Jan Krems
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tools_Console] Tools/Console.escript
 ** 2009-07-20
 **/
var plugin = new Plugin({
		Plugin.NAME : 'Tools_Console',
		Plugin.DESCRIPTION : "Console window for scripting. Opened with [^] key.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius Jaehn",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend/EventLoop'],
		Plugin.EXTENSION_POINTS : []
});

/**
* Plugin initialization.
* ---|> Plugin
*/
plugin.init=fn(){
	{ // Register ExtensionPointHandler:
		registerExtension('PADrend_Init',this->fn(){
			gui.registerComponentProvider('PADrend_PluginsMenu.console',[{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Console",
				GUI.ON_CLICK : fn(plugin) {
					plugin.toggleWindow();
					this.setSwitch(GLOBALS.gui.windows['Console'].isVisible());
				}.bindFirstParams(this)
			}]);
		});
		registerExtension('PADrend_KeyPressed',this->this.ex_KeyPressed);
	}

	return true;
};

//!	[ext:PADrend_KeyPressed]
plugin.ex_KeyPressed := fn(evt) {
	if((evt.key == Util.UI.KEY_CIRCUMFLEX || evt.key == Util.UI.KEY_GRAVE) && 
			!PADrend.getEventContext().isCtrlPressed()) {
		toggleWindow();
		return true;
	}
	return false;
};

plugin.toggleWindow:=fn(){
	if(! GLOBALS.gui.windows['Console'] ){
		GLOBALS.gui.windows['Console'] = this.createWindow();
	}else{
		GLOBALS.gui.windows['Console'].toggleVisibility();
	}
	this.getFocus();
};

plugin.getFocus:=fn(){
	gui.setActiveComponent(this.inputComponent);
	this.inputComponent.select();
	this.inputComponent.activate();
};

plugin.createWindow := fn(){

	var window = gui.createWindow(450, 400, "Console");
	window.setPosition(330, 240);

	var windowContainer = gui.create({
		GUI.TYPE			:	GUI.TYPE_CONTAINER,
		GUI.SIZE			:	GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT			:	GUI.LAYOUT_FLOW
	});
	window += windowContainer;

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
	this.inputComponent := inputComponent;

	windowContainer += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"execute",
		GUI.ON_CLICK			:	(fn(plugin, inputComponent, outputComponent) {
										var outBackup=out;
										var tmp=new ExtObject();
										tmp.result:="";
										GLOBALS.out:=tmp->fn(p...){
											this.result+=p.implode();
										};
										var s=inputComponent.getText();
										if(s!="")
											inputComponent.addOption(s);
										inputComponent.setCurrentOptionIndex(0);
										inputComponent.setText("");

										plugin.getFocus();

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
									}).bindLastParams(this, inputComponent, output),
		GUI.WIDTH				:	50
	};
	windowContainer += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"X",
		GUI.TOOLTIP				:	"Clear",
		GUI.ON_CLICK			:	(fn(inputComponent, outputComponent) {
										outputComponent.clear();
										inputComponent.clearOptions();
									}).bindLastParams(inputComponent, output),
		GUI.WIDTH				:	16
	};

	return window;
};

return plugin;
// ------------------------------------------------------------------------------

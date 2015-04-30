/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var plugin = new Plugin({
		Plugin.NAME : 'QP-MMI/SlidePresenter',
		Plugin.DESCRIPTION : "Show slides. (EXPERIMENTAL)",
		Plugin.VERSION : 1.1,
		Plugin.AUTHORS : "Claudius Jähn",
		Plugin.OWNER : "Claudius Jähn",
		Plugin.LICENSE	: "Mozilla Public License, v. 2.0",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

Std.Traits.addTrait(plugin,Util.ReloadablePluginTrait);	//!	\see Util.ReloadablePluginTrait


plugin.init @(override) := fn() {
	Std._unregisterModule('SlidePresenter/SlidePresenter');

	Util.registerExtension('PADrend_Init',initGUI);
	Util.registerExtension('PADrend_Init',["Gamepad_1"]=>connectToGamepad);
	Util.registerExtension('PADrend_Init',initRPC);

	return true;
};
static getFolderWrapper = fn(){
	@(once) static folder = Std.DataWrapper.createFromConfig(PADrend.configCache,"Slides.folder","./screens/");
	return folder;	
};

static initRPC = fn(){
	static rpc = Util.requirePlugin( 'PADrend/RemoteControl' );
	rpc.registerFunction('SlidePresenter.close',fn(){	getPresenter().close();	});
	rpc.registerFunction('SlidePresenter.getSlideNr',fn(){	return getPresenter().getSlideNrWrapper()();	});
	rpc.registerFunction('SlidePresenter.getSlideCount',fn(){	return getPresenter().getSlideCount();	});
	rpc.registerFunction('SlidePresenter.goTo',fn(s){    getPresenter().goTo(s.toNumber()); });
	rpc.registerFunction('SlidePresenter.goToNext',fn(){	getPresenter().goToNext();	});
	rpc.registerFunction('SlidePresenter.goToPrev',fn(){	getPresenter().goToPrev();	});
	rpc.registerFunction('SlidePresenter.isOpen',fn(){	return getPresenter().isOpen();	});
	rpc.registerFunction('SlidePresenter.show',fn(){	getPresenter().show();	});
	rpc.registerFunction('SlidePresenter.setFolder',fn(String f){	getFolderWrapper()(f);	});
};


static getPresenter = fn(){
	static presenter;
	@(once){
		presenter = new (Std.module('SlidePresenter/SlidePresenter'))(
													Std.DataWrapper.createFromConfig(PADrend.configCache,"Slides.wRect",[100,100,320,200]),
													getFolderWrapper(),
													Std.DataWrapper.createFromConfig(PADrend.configCache,"Slides.fullscreen",false),
													Std.DataWrapper.createFromConfig(PADrend.configCache,"Slides.stretch",false));
	}
	return presenter;
};

static connectToGamepad = fn(String deviceName){
	var device = PADrend.HID.getDevice(deviceName);
	if(!device){
		Runtime.warn("SyncGUI.addDevice(...) No Device found: '"+deviceName+"'");
		return;
	}

	//! \see HID_Traits.ControllerButtonTrait
	Std.Traits.requireTrait( device, Std.module('LibUtilExt/HID_Traits').ControllerButtonTrait);

	//! \see HID_Traits.ControllerButtonTrait
	device.onButton += fn(button,pressed){
		if(pressed){
			switch(button){
				case 1:
					getPresenter().isOpen() ? getPresenter().close() : getPresenter().show();
					return true;
				case 2:
					getPresenter().goToNext();
					return true;
				case 0:
					getPresenter().goToPrev();
					return true;
				case 3:
					getPresenter().slideAction();
					return true;

			}
		}
//		outln(button,pressed);
		return false;
	};
};



static initGUI = fn(){
	gui.register('PADrend_PluginsMenu.slides',[
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Slide presenter",
			GUI.ON_CLICK : fn(){	getPresenter().show();	}
		}
	]);

	gui.register('SyncGUI_Main.10slides', [
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Slides",
			GUI.MENU : fn(){
				var entries = [];
				entries += {
					GUI.TYPE : GUI.TYPE_RANGE,
					GUI.RANGE : [1,getPresenter().getSlideCount()] ,
					GUI.LABEL : "Select slide nr",
					GUI.RANGE_STEP_SIZE : 1,
					GUI.DATA_WRAPPER : getPresenter().getSlideNrWrapper()
				};
				entries += {
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Close slides",
					GUI.ON_CLICK : fn(){	getPresenter().close();		}
				};
				getPresenter().getSlideNrWrapper().forceRefresh();
				return entries;
			}
		},
		'----'
	]);
};

// -------------------
return plugin;
// ------------------------------------------------------------------------------

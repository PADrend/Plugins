/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:PADrend] PADrend/SplashScreen/Plugin.escript
 **/

var plugin = new Plugin({
		Plugin.NAME : 'PADrend/SplashScreen',
		Plugin.DESCRIPTION : "PADrend SplashScreen.",
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Benjamin & Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend'],
		Plugin.EXTENSION_POINTS : []
});

static splashScreen = void;

plugin.init @(override) := fn(){
	if(systemConfig.getValue('PADrend.SplashScreen.enabled', true)){
		if(getOS() == 'WINDOWS') {
			Runtime.warn("SplashScreen on windows is broken (until further notice). Save config to disable it.");
			systemConfig.setValue('PADrend.SplashScreen.enabled', false);
			return true;
		}
		
		var logoPath = __DIR__+"/../resources/SplashScreen/Logo.png";
		if(getOS() == 'WINDOWS') {
			logoPath = __DIR__+"/../resources/SplashScreen/Logo_alpha.png";
		}
		splashScreen = new Util.UI.SplashScreen("PADrend",systemConfig.getValue('PADrend.SplashScreen.image', logoPath) );

		registerExtension('PADrend_Message',this->ext_Message);
		registerExtension('PADrend_Init',this->ex_Init);
	
	}
	
	return true;
};


//! [ext:PADrend_Init]
plugin.ex_Init := fn(...){
	PADrend.planTask( systemConfig.getValue('PADrend.SplashScreen.duration', 0.5); ,this->fn(){
		// we are done!
		splashScreen.showMessage("Finished.");
		splashScreen.destroy();
		splashScreen = void;
//		out("splashscreen closed\n");
	});
};

//! [ext:PADrend_Message]
plugin.ext_Message := fn(s){
	if(!splashScreen){ // window already destroyed?
		return Extension.REMOVE_EXTENSION;
	}
	splashScreen.showMessage(s);
	return Extension.CONTINUE;
};

return plugin;
// ------------------------------------------------------------------------------

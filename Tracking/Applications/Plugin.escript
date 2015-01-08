/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010 Robert Gmyr
 * Copyright (C) 2010,2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 ** Tracking applications.
 **/


var plugin = new Plugin({
		Plugin.NAME : 'Tracking/Applications',
		Plugin.DESCRIPTION :  "Some tracking applications.",
		Plugin.VERSION :  2.0,
		Plugin.AUTHORS : "Gmyr, Claudius Jaehn",
		Plugin.OWNER : "Claudius Jaehn",
		Plugin.LICENSE : "PROPRIETARY",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});


plugin.init @(override) := fn(){

//	this.applications := [];
//	applications += "ObserverPositionTracking";
//	applications += "FlystickCrossHairs";
//	applications += "FlystickNavigation";
//	applications += "FlystickPicking";
//	applications += "FlystickLaserPointer";
//	applications += "Calibration";

//	var tempApplications = [];

//	applications = tempApplications;


	registerExtension('PADrend_Init',fn(){

		foreach([
				"HeadTracking",
				"HeadCalibration",
				"FlystickCrossHairs",
				"LaserPointer",
				"Navigation",
				"Flashlight",
				"Graffiti",
				"SelecterTraking"
				] as var application)
			module( "./"+ application);

	});

	return true;
};
//
//plugin.ex_AfterFrame := fn(...){
//    var data = void;
//
//    // let applications handle data
//    foreach(applications as var application)
//        application.handleData();
//};

return plugin;
// ------------------------------------------------------------------------------

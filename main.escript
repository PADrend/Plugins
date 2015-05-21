/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2008-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2007-2012,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Lukas Kopecki
 * Copyright (C) 2009 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
GLOBALS._processResult := true;

Runtime.enableLogCounting();

addSearchPath(__DIR__); // add "plugins/" to the search path for load and loadOnce.

load("LibEStd/init.escript");
Std.addModuleSearchPath(__DIR__); // add "plugins/" to the search path for Std.require

// extract --config= from command line
var configFile = "config.json";
foreach(args as var arg){
	if(arg.substr(0,9)=="--config=")
		configFile = arg.substr(9);
}
if(!IO.isFile(configFile)){
	outln("Creating new config file: "+configFile);
	IO.saveTextFile(configFile,"");
}

// system' main config manager
GLOBALS.systemConfig := new Std.JSONDataStore(true);
systemConfig.init(configFile);
systemConfig.setInfo('System.mainScript',"Main script file (default: PADrend/PADrend.escript)");
load(systemConfig.getValue('System.mainScript',"PADrend/PADrend.escript"));

if( _processResult.isA(Exception) )
	throw _processResult;
else
	exit(_processResult);

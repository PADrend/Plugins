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

var Version = new Namespace;

Version.VERSION := 10200; // major * 10000 + minor * 100 + release
Version.VERSION_STRING := "PADrend 1.2.0";
Version.VERSION_FULL_STRING := Version.VERSION_STRING + " -- Platform for Algorithm Development and rendering (PADrend.de)";

var build = "";
var file = args[0];
if(file&&!file.empty()&&IO.isFile(file)){
	try{ // try to get executable's modification time
		build += "year-mon-mday hours:minutes.seconds".replaceAll(getDate(IO.fileMTime(file)))+" | ";
	}catch(e){ // fail silently
	}
}
build += "" + (SIZE_OF_PTR==8?64:32) +" bit | " + BUILD_TYPE;
Version.BUILD := build;

return Version;
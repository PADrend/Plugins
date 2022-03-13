/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2008-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2007-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 David Maicher
 * Copyright (C) 2009 Jan Krems
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var Version = Std.module('PADrend/Version');
 // header 
outln("-"*79);
outln(Version.VERSION_FULL_STRING);
outln("-"*79);
outln("Build:\t", Version.BUILD );
out("Libs:");
foreach( Util.getLibVersionStrings() as var lib,var version)
	outln("\t",version);
outln("-"*79);

if(EScript.VERSION<607)
	throw "Incompatible EScript version!";

// ------------------

{
	outln("Loading Util scripts...");
	
	Std.module('LibUtilExt/initMiscUtils');
	Std.module('LibGeometryExt/initGeometryUtils');
	Std.module('LibRenderingExt/initRenderingUtils');	
	Std.module('LibMinSGExt/initMinSGUtils');
	Std.module('LibMinSGExt/initNodeExtensions');

}
{ // Declare some global variables

	// universal globals
	GLOBALS.Network:=void; // alias for Util.Network, if network support is available

	// PADrend dependent variables (\todo move to PADrend members)
	GLOBALS.device := void;
	GLOBALS.frameContext := void;
	GLOBALS.renderingContext := void;
	GLOBALS.camera := void;
}
{ // load and execute PADrend
	Std.module('LibUtilExt/GlobalPluginRegistry').loadPlugins( ["PADrend"],true,[__DIR__+"/../"] );
}

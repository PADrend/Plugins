/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2008-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2007-2013 Claudius Jähn <claudius@uni-paderborn.de>
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
/****
 **	[PADrend] PADrend/PADrend.escript
 **/

out("-"*79,"\n");
out("PADrend 1.0.0 (Platform for Algorithm Development and rendering)\n\n");
out("http://www.padrend.de/\n");
out("Libs:\t",EScript.VERSION_STRING,"\n\t",MinSG.VERSION, "\n");
out("Build:\t", (SIZE_OF_PTR==8?64:32)," bit ", BUILD_TYPE ,"\n");
out("\n","-"*79,"\n");

// ------------------

{
	out(("Loading Util scripts...").fillUp(40));
	
	if(EScript.VERSION<607){
		loadOnce ("LibUtilExt/deprecated/DataWrapper.escript");
		loadOnce ("LibUtilExt/deprecated/PriorityQueue.escript");
		loadOnce ("LibUtilExt/deprecated/EScript_Utils.escript");
		loadOnce ("LibUtilExt/deprecated/CommonTraits.escript");
	}
	
	loadOnce ("LibUtilExt/PluginManagement.escript");
	loadOnce ("LibUtilExt/deprecated/Listener.escript");
	loadOnce ("LibUtilExt/Misc_Utils.escript");

	loadOnce ("LibMinSGExt/Geometry_Utils.escript");
	Std.require('LibMinSGExt/RendRayCaster');
	Std.require('LibMinSGExt/MinSG_Utils');
	loadOnce ("LibMinSGExt/NodeExtensions.escript");
	loadOnce ("LibMinSGExt/NodeTraits.escript");
	loadOnce ("LibMinSGExt/Rendering_Utils.escript");	
	loadOnce ("LibMinSGExt/SemanticObject.escript");	
	loadOnce ("LibMinSGExt/MeshBuilderExtensions.escript");	

	outln("ok.");
}
{ // Declare some global variables

	// universal globals
	GLOBALS.Network:=void; // alias for Util.Network, if network support is available

	// PADrend dependent variables (\todo move to PADrend members)
	GLOBALS.frameContext := void;
	GLOBALS.renderingContext := void;
	GLOBALS.camera := void;
}
{ // load and execute PADrend
	loadPlugins( ["PADrend"],true,[__DIR__+"/../"] );
}

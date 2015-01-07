/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2009 Jan Krems
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:AutoMeshCreation] AutoMeshCreation/Plugin.escript
 ** 2009-07-20
 **/

var plugin = new Plugin({
		Plugin.NAME : 'AutoMeshCreation',
		Plugin.DESCRIPTION : "Functions for building meshes.",
		Plugin.VERSION : 1.3,
		Plugin.AUTHORS : "Jan Krems, Claudius Jaehn",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) := fn(){
    loadOnce(__DIR__+"/Extruder.escript");
	loadOnce(__DIR__+"/Primitives.escript");
	loadOnce(__DIR__+"/TreeGen.escript");
    return true;
};

return plugin;

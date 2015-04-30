/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2014 Claudius Jähn <claudius@uni-paderborn.de>

 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var plugin = new Plugin({
			Plugin.NAME : "ObjectTraits",
			Plugin.VERSION : "1.1",
			Plugin.DESCRIPTION : "Collection of traits for (semantic) objects.\n Includes a registry for such traits and configuration interfaces.",
			Plugin.AUTHORS : "Claudius",
			Plugin.LICENSE	: "Mozilla Public License, v. 2.0",
			Plugin.OWNER : "All",
			Plugin.REQUIRES : []
});

plugin.init @(override) := fn(){
	Std.module('ObjectTraits/ObjectTraitRegistry').scanTraitsInFolder( __DIR__ );
	return true;
};

return plugin;

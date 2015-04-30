/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Mouns R. Husan Almarrani
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var plugin = new Plugin({
	Plugin.NAME : 'Physics',
	Plugin.DESCRIPTION : "Physics",
	Plugin.VERSION : 1.1,
	Plugin.REQUIRES : [ 'ObjectTraits' ],
	Plugin.AUTHORS : "Mouns,Claudius",
	Plugin.OWNER : "Claudius, Mouns",
	Plugin.EXTENSION_POINTS : [ ]
});


plugin.init @(override) := fn() {
	Std.module('ObjectTraits/ObjectTraitRegistry').scanTraitsInFolder( __DIR__+"/ObjectTraits" );
	
	Util.registerExtension('NodeEditor_QueryAvailableStates',fn(availableStates) {
		availableStates["[ext] PhysicsDebugRenderer"] = fn(){return new (module('./PhysicsDebugRendererState')); };
	});

	return true;
};

return plugin;

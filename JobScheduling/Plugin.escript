/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] JobScheduling/Plugin.escript
 **
 ** Plugin for distributing jobs over multiple instances.
 ** Execute JobScheduling.plugin.test() for an example.
 **/
 

static plugin = new Plugin({
		Plugin.NAME : 'JobScheduling',
		Plugin.DESCRIPTION : 'Distributed job scheduling using MultiView.',
		Plugin.VERSION : 0.2,
		Plugin.AUTHORS : "Claudius Jaehn",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend/EventLoop','PADrend/CommandHandling'],
		Plugin.EXTENSION_POINTS : [ ]
});

plugin.init @(override) := fn() {
	GLOBALS.JobScheduling := Std.module('JobScheduling/JobScheduling');
	return true;
};

return plugin;
// ------------------------------------------------------------------------------

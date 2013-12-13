/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var plugin = new Plugin({
	Plugin.NAME			:	"LibRenderingExt",
	Plugin.VERSION		:	"1.0",
	Plugin.DESCRIPTION	:	"Additional resources and functions to extend the Rendering library.",
	Plugin.AUTHORS		:	"Benjamin Eikel",
	Plugin.OWNER		:	"All",
	Plugin.LICENSE		:	"Mozilla Public License, v. 2.0"
});

plugin.init @(override) := fn() {
	return true;
};

return plugin;

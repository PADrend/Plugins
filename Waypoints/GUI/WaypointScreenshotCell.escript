/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Jan Krems
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
**	[Plugin:Waypoints/WaypointEditor] Waypoints/WaypointEditorCell.escript
**
** Cell displaying infos about a waypoint, with the ability to make changes and
** fly to the waypoint
**/

WaypointsPlugin.createWaypointScreenshotCell := fn(MinSG.Waypoint waypoint) {
	var cell = gui.create({
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"",
		GUI.TOOLTIP				:	WaypointsPlugin.getWaypointDescription(waypoint),
		GUI.ON_CLICK			:	(fn(MinSG.Waypoint waypoint) {
											WaypointsPlugin.flyTo(waypoint.getTime());
									}).bindFirstParams(waypoint),
		GUI.SIZE				:	[GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 120, 90]
	});

	if(waypoint.isSet($shotIcon)) {
		cell += {
			GUI.TYPE				:	GUI.TYPE_ICON,
			GUI.ICON				:	gui.createIcon(waypoint.shotIcon.getImageData(), waypoint.shotIcon.getImageRect()),
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_FILL_ABS, 4, 4],
			GUI.POSITION			:	GUI.POSITION_CENTER_XY
		};
	}

	cell += {
		GUI.TYPE				:	GUI.TYPE_LABEL,
		GUI.LABEL				:	waypoint.getTime(),
		GUI.COLOR				:	GUI.BLACK,
		GUI.POSITION			:	[
										GUI.POS_X_ABS | GUI.REFERENCE_X_LEFT | GUI.ALIGN_X_LEFT |
										GUI.POS_Y_ABS | GUI.REFERENCE_Y_TOP | GUI.ALIGN_Y_TOP,
										5, 5
									]
	};
	cell += {
		GUI.TYPE				:	GUI.TYPE_LABEL,
		GUI.LABEL				:	waypoint.getTime(),
		GUI.COLOR				:	GUI.WHITE,
		GUI.POSITION			:	[
										GUI.POS_X_ABS | GUI.REFERENCE_X_RIGHT | GUI.ALIGN_X_RIGHT |
										GUI.POS_Y_ABS | GUI.REFERENCE_Y_BOTTOM | GUI.ALIGN_Y_BOTTOM,
										5, 5
									]
	};

	return cell;
};

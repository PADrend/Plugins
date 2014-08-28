/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
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

//! ---|> CellBuilder
WaypointsPlugin.createWaypointCell := fn(MinSG.Waypoint waypoint, listView) {
	var cell = gui.create({
		GUI.TYPE				:	GUI.TYPE_CONTAINER,
		GUI.LAYOUT				:	GUI.LAYOUT_FLOW,
		GUI.SIZE				:	GUI.SIZE_MAXIMIZE
	});

	cell.txtDesc := gui.create({
		GUI.TYPE				:	GUI.TYPE_LABEL,
		GUI.LABEL				:	"",
		GUI.TOOLTIP				:	"Description",
		GUI.TEXT_ALIGNMENT		:	GUI.TEXT_ALIGN_MIDDLE,
		GUI.SIZE				:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.3, 33]
	});
	cell.edtDesc := gui.create({
		GUI.TYPE				:	GUI.TYPE_TEXT,
		GUI.LABEL				:	"Description",
		GUI.SIZE				:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.3, 33]
	});

	cell.txtTime := gui.create({
		GUI.TYPE				:	GUI.TYPE_LABEL,
		GUI.LABEL				:	"",
		GUI.TOOLTIP				:	"Time",
		GUI.TEXT_ALIGNMENT		:	GUI.TEXT_ALIGN_MIDDLE,
		GUI.SIZE				:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.2, 33]
	});
	cell.edtTime := gui.create({
		GUI.TYPE				:	GUI.TYPE_NUMBER,
		GUI.LABEL				:	"Time",
		GUI.SIZE				:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.2, 33]
	});

	cell.createEditGUI := [waypoint] => fn(MinSG.Waypoint waypoint) {
		this.clear();

		this.add(this.iconArea);
		this.add(this.edtTime);
		this.add(this.edtDesc);
		this.add(this.btnSetPos);
		this.add(this.btnCancel);
		this.add(this.btnSave);

		this.btnSetPos.setSwitch(false);
		this.btnSetPos.newSRT := void;
		this.btnSetPos.oldSRT := waypoint.getRelTransformationSRT();

		this.update();
	};

	cell.createViewGUI := fn() {
		this.clear();

		this.add(this.iconArea);
		this.add(this.txtTime);
		this.add(this.txtDesc);
		this.add(this.btnFlyTo);
		this.add(this.btnEdit);

		this.update();
	};

	cell.btnSave := gui.create({
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Save",
		GUI.TOOLTIP				:	"Save changes",
		GUI.ON_CLICK			:	[cell,waypoint] => fn(cell, waypoint) {
										waypoint.setRelTransformation(cell.btnSetPos.oldSRT);
										WaypointsPlugin.changeWaypoint(waypoint,
											cell.edtTime.getData(),
											cell.edtDesc.getData(),
											cell.btnSetPos.newSRT
										);
										cell.createViewGUI();
									},
		GUI.SIZE				:	[GUI.HEIGHT_ABS, 0, 33]
	});
	cell.btnCancel := gui.create({
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Cancel",
		GUI.TOOLTIP				:	"Cancel edit",
		GUI.ON_CLICK			:	[cell,waypoint] => fn(cell, waypoint) {
										waypoint.setRelTransformation(cell.btnSetPos.oldSRT);
										cell.createViewGUI();
									},
		GUI.SIZE				:	[GUI.HEIGHT_ABS, 0, 33]
	});

	cell.btnEdit := gui.create({
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.ICON				:	__DIR__ + "/../resources/Edit32.png",
		GUI.LABEL				:	"",
		GUI.TOOLTIP				:	"Edit waypoint",
		GUI.FLAGS				:	GUI.FLAT_BUTTON,
		GUI.ON_CLICK			:	cell -> cell.createEditGUI
	});

	cell.btnFlyTo := gui.create({
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.ICON				:	__DIR__ + "/../resources/Goto32.png",
		GUI.LABEL				:	"",
		GUI.TOOLTIP				:	"Fly to waypoint",
		GUI.FLAGS				:	GUI.FLAT_BUTTON,
		GUI.ON_CLICK			:	[waypoint,listView] => fn(MinSG.Waypoint waypoint, listView) {
										WaypointsPlugin.flyTo(waypoint.getTime());
										listView.setData(waypoint);
									}
	});

	cell.btnSetPos := gui.create({
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.ICON				:	__DIR__ + "/../resources/Position32.png",
		GUI.LABEL				:	"",
		GUI.TOOLTIP				:	"Set waypoint's SRT to current camera's SRT",
		GUI.FLAGS				:	GUI.FLAT_BUTTON,
		GUI.ON_CLICK			:	[waypoint] => fn(MinSG.Waypoint waypoint) {
										this.newSRT = PADrend.getDolly().getRelTransformationSRT();
										waypoint.setRelTransformation(this.newSRT);
									}
	});
	cell.btnSetPos.newSRT := void;
	cell.btnSetPos.oldSRT := void;

	cell.iconArea := gui.create({
		GUI.TYPE				:	GUI.TYPE_CONTAINER,
		GUI.SIZE				:	[GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 44, 33]
	});
	cell.update := [waypoint] => fn(MinSG.Waypoint waypoint) {
		this.iconArea.clear();

		if(waypoint != void){
			// update gui
			var tmp=WaypointsPlugin.getWaypointDescription(waypoint);
			this.edtDesc.setData(tmp);
			this.txtDesc.setText(tmp);

			tmp=waypoint.getTime();
			this.edtTime.setData(tmp);
			this.txtTime.setText(tmp);

			if(waypoint.isSet($shotIcon)) {
				iconArea += {
					GUI.TYPE				:	GUI.TYPE_ICON,
					GUI.ICON				:	gui.createIcon(waypoint.shotIcon.getImageData(), waypoint.shotIcon.getImageRect()),
					GUI.SIZE				:	[GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 44, 33]
				};
			}
		} else {
			// hide gui, show error
			this.edtDesc.setData("!!!! ERROR !!!!");
			this.txtDesc.setText("!!!! ERROR !!!!");
		}
	};

	cell.createViewGUI();

	return cell;
};

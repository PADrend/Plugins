/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*
 *	[Plugin:Tools_CameraWindow] Tools/Camera/Plugin.escript
 *	2011-10-16	Benjamin Eikel	Creation.
 */

GLOBALS.CameraWindowPlugin := new Plugin({
			Plugin.NAME : "CameraWindowPlugin",
			Plugin.VERSION : "1.0",
			Plugin.DESCRIPTION : "User interface to manage camera settings.",
			Plugin.AUTHORS : "Benjamin Eikel",
			Plugin.OWNER : "Benjamin Eikel",
			Plugin.REQUIRES : ['PADrend', 'PADrend/GUI'],
			Plugin.EXTENSION_POINTS : [
				/**
				 * Notification when the set of cameras has been changed.
				 * 
				 * @param	none
				 * @result	Void
				 */
				'CameraWindowPlugin_CamerasChanged',

				/**
				 * Notification when the configuration of a camera has been changed.
				 * 
				 * @param	MinSG.AbstractCameraNode	Current camera that has been changed
				 * @result	Void
				 */
				'CameraWindowPlugin_CameraConfigurationChanged'
			]
});

load(__DIR__ + "/ConfigPanel.escript");
load(__DIR__ + "/OptionPanel.escript");
load(__DIR__ + "/Window.escript");

CameraWindowPlugin.init @(override) := fn() {
	{
		registerExtension('PADrend_Init', this->ex_Init);
		if(queryPlugin('NodeEditor')) {
			NodeEditor.registerConfigPanelProvider(MinSG.AbstractCameraNode, fn(MinSG.AbstractCameraNode node, panel){
				panel += CameraWindowPlugin.createConfigPanel(node);
				panel++;
				panel += CameraWindowPlugin.createOptionPanel(node);
			});
		}
	}

	return true;
};

//! [ext:PADrend_Init]
CameraWindowPlugin.ex_Init := fn() {
	
	gui.register('Tools_ToolsMenu.cameraSettings',[
		{
			GUI.LABEL			:	"Cameras ...",
			GUI.TOOLTIP			:	"Open a window to manage camera settings.",
			GUI.ON_CLICK		:	CameraWindowPlugin.createWindow
		}
	]);

	gui.register('PADrend_ConfigMenu.35_cameraSettings',[
		'----',
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Camera",
			GUI.MENU_WIDTH : 150,
			GUI.MENU : fn(){
				var entries = [];
				entries += "*Camera*";
				entries += CameraWindowPlugin.createNearPlaneSlider(PADrend.getActiveCamera(), false);
				entries += CameraWindowPlugin.createFarPlaneSlider(PADrend.getActiveCamera(), false);
				entries += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "Set as default",
						GUI.ON_CLICK : fn() {
							systemConfig.setValue('PADrend.Camera.near', PADrend.getActiveCamera().getNearPlane());
							systemConfig.setValue('PADrend.Camera.far', PADrend.getActiveCamera().getFarPlane());
							PADrend.message("Settings stored.");	
						}
				};
				entries += "----";
				entries += {
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Config window",
					GUI.TOOLTIP : "Open a window to manage camera settings.",
					GUI.ON_CLICK : CameraWindowPlugin.createWindow
				};
				return entries;
			}
		}
	]);
};

return CameraWindowPlugin;

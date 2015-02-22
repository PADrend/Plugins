/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
 


var resourceFolder = __DIR__+"/../resources";

gui.loadIconFile( resourceFolder+"/Icons/PADrendDefault.json");

GUI.OPTIONS_MENU_MARKER @(override) := {
	GUI.TYPE : GUI.TYPE_ICON,
	GUI.ICON : '#DownSmall',
	GUI.ICON_COLOR : new Util.Color4ub(0x30,0x30,0x30,0xff)
};

// init fonts
gui.registerFonts({
//		GUI.FONT_ID_DEFAULT : 		resourceFolder+"/Fonts/DejaVu_Sans_Codensed_12.png",
	GUI.FONT_ID_DEFAULT : 		resourceFolder+"/Fonts/DejaVu_Sans_Codensed_12.fnt",
//		GUI.FONT_ID_DEFAULT : 		GUI.BitmapFont.createFont(resourceFolder+"/Fonts/BAUHS93.ttf",12, " !\"#$%&'()*+,-./0123456789:;<=>?@ ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"),
//		GUI.FONT_ID_DEFAULT : 		GUI.BitmapFont.createFont(resourceFolder+"/Fonts/BAUHS93.ttf",20, " !\"#$%&'()*+,-./0123456789:;<=>?@ ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"),
	GUI.FONT_ID_HEADING : 		resourceFolder+"/Fonts/DejaVu_Sans_14.fnt",
	GUI.FONT_ID_LARGE : 		resourceFolder+"/Fonts/DejaVu_Sans_Codensed_18.fnt",
	GUI.FONT_ID_TOOLTIP : 		resourceFolder+"/Fonts/DejaVu_Sans_10.fnt",
	GUI.FONT_ID_WINDOW_TITLE : 	resourceFolder+"/Fonts/DejaVu_Sans_12.fnt",
	GUI.FONT_ID_XLARGE : 		resourceFolder+"/Fonts/DejaVu_Sans_32_outline_aa.fnt",
	GUI.FONT_ID_HUGE : 			resourceFolder+"/Fonts/DejaVu_Sans_64_outline_aa.fnt",
});



gui.registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_DEFAULT, Util.loadBitmap(resourceFolder+"/MouseCursors/3dSceneCursor.png"), 0, 0);
gui.registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_TEXTFIELD, Util.loadBitmap(resourceFolder+"/MouseCursors/TextfieldCursor.png"), 8, 8);
gui.registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_RESIZEDIAGONAL, Util.loadBitmap(resourceFolder+"/MouseCursors/resizeCursor.png"), 9, 9);

var NS = new Namespace;

NS.TOOLBAR_ICON_COLOR := new Util.Color4f(0.0,0,0,0.9);
NS.TOOLBAR_BG_SHAPE := new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
											gui._createRectShape(new Util.Color4f(0.3,0.3,0.3,0.5),new Util.Color4ub(0,0,0,0),true));
	

return NS;


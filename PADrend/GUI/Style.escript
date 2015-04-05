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
	GUI.FONT_ID_DEFAULT : 		resourceFolder+"/Fonts/DejaVu_Sans_Codensed_12.fnt",
//		GUI.FONT_ID_DEFAULT : 		resourceFolder+"/Fonts/DejaVu_Sans_Codensed_12.png",
//		GUI.FONT_ID_DEFAULT : 		GUI.BitmapFont.createFont(resourceFolder+"/Fonts/BAUHS93.ttf",12, " !\"#$%&'()*+,-./0123456789:;<=>?@ ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"),
//		GUI.FONT_ID_DEFAULT : 		GUI.BitmapFont.createFont(resourceFolder+"/Fonts/BAUHS93.ttf",20, " !\"#$%&'()*+,-./0123456789:;<=>?@ ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"),
//		GUI.FONT_ID_DEFAULT : 		GUI.BitmapFont.createFont("Arial.ttf",20, " !\"#$%&'()*+,-./0123456789:;<=>?@ ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"),
	GUI.FONT_ID_HEADING : 		resourceFolder+"/Fonts/DejaVu_Sans_14.fnt",
	GUI.FONT_ID_LARGE : 		resourceFolder+"/Fonts/DejaVu_Sans_Codensed_18.fnt",
	GUI.FONT_ID_TOOLTIP : 		resourceFolder+"/Fonts/DejaVu_Sans_10.fnt",
	GUI.FONT_ID_WINDOW_TITLE : 	resourceFolder+"/Fonts/DejaVu_Sans_12.fnt",
	GUI.FONT_ID_XLARGE : 		resourceFolder+"/Fonts/DejaVu_Sans_32_outline_aa.fnt",
	GUI.FONT_ID_HUGE : 			resourceFolder+"/Fonts/DejaVu_Sans_64_outline_aa.fnt",
});



var color_accent1 = new Util.Color4ub(0,58,128,255);
var color_accent2 = new Util.Color4ub(255,221,0,255);
var color_toolbarBackground = new Util.Color4ub(120,120,120,192);
var color_menuBackground = new Util.Color4ub(100,100,100,230);
var color_strongShadow = new Util.Color4ub(0,0,0,0x80);
var color_shadow = new Util.Color4ub(0,0,0,0x50);

//const Util::Color4ub Colors::COMPONENT_COLOR_1(0xA0,0xA0,0xA0,0x30);
//const Util::Color4ub Colors::COMPONENT_COLOR_2(0xF8,0xF8,0xF8,0x90);
var color_component1 = new Util.Color4ub(0xA0,0xA0,0xA0,0xF0);
var color_component2 = new Util.Color4ub(0xF8,0xF8,0xF8,0xF0);

var NS = new Namespace;

NS.TOOLBAR_ICON_COLOR := new Util.Color4f(0.0,0,0,1.0);


NS.TOOLBAR_ACTIVE_BUTTON_PROPERTIES := [	new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR, GUI.BLACK),
											new GUI.ShapeProperty(GUI.PROPERTY_BUTTON_SHAPE,
											gui._createRectShape(color_accent2, GUI.NO_COLOR,true))];
											
NS.resourceFolder := resourceFolder;
											
NS.CURSOR_DEFAULT := Util.loadBitmap(resourceFolder+"/MouseCursors/3dSceneCursor.png");

gui.registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_DEFAULT, NS.CURSOR_DEFAULT, 0, 0);
gui.registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_TEXTFIELD, Util.loadBitmap(resourceFolder+"/MouseCursors/TextfieldCursor.png"), 8, 8);
gui.registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_RESIZEDIAGONAL, Util.loadBitmap(resourceFolder+"/MouseCursors/resizeCursor.png"), 9, 9);

gui.registerPreset('header',{
	GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS,-20,15],
	GUI.FONT : GUI.FONT_ID_HEADING
});

gui.registerPreset('menu',{
	GUI.PROPERTIES : [
			new GUI.ColorProperty(GUI.PROPERTY_TEXT_COLOR, GUI.WHITE),
			new GUI.ColorProperty(GUI.PROPERTY_BUTTON_HOVERED_TEXT_COLOR, color_accent1 ),
			new GUI.ShapeProperty(GUI.PROPERTY_BUTTON_HOVERED_SHAPE, gui._createRectShape( color_accent2,color_accent2,true ) ),
			new GUI.ShapeProperty(GUI.PROPERTY_BUTTON_SHAPE, gui.getNullShape() ),
			new GUI.ShapeProperty(GUI.PROPERTY_MENU_SHAPE, gui._createRectShape( color_menuBackground,GUI.NO_COLOR,true) ),
			new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR, GUI.WHITE ),
	],
	GUI.MENU_WIDTH : 150,
});

gui.registerPreset('menu/header',{
	GUI.FLAGS : GUI.BACKGROUND,
	GUI.TEXT_ALIGNMENT : GUI.TEXT_ALIGN_CENTER | GUI.TEXT_ALIGN_MIDDLE,
	GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS,3,15],
	GUI.PROPERTIES  : [ new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
											gui._createRectShape( color_accent1,color_accent1,true)) ]
});

gui.registerPreset('toolbar',{
	GUI.FLAGS : GUI.BACKGROUND,
	GUI.LAYOUT : (new GUI.FlowLayouter).setMargin(0).setPadding(3).enableAutoBreak(),
	GUI.PROPERTIES : [
			new GUI.ShapeProperty(GUI.PROPERTY_BUTTON_SHAPE,GUI.NULL_SHAPE),
			new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
											gui._createRectShape(color_toolbarBackground,GUI.NO_COLOR,true))
	]
});
gui.registerPreset('toolbar/toolIcon',{
		GUI.PROPERTIES : [	new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR, NS.TOOLBAR_ICON_COLOR)	],
		GUI.HOVER_PROPERTIES : [ [new GUI.ShapeProperty(GUI.PROPERTY_BUTTON_SHAPE,
											gui._createRectShape(color_accent1,GUI.NO_COLOR,true)),1,false] ]
});
//// temp:
//gui.registerPreset('toolIcon',{
//		GUI.PROPERTIES : [	new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR, NS.TOOLBAR_ICON_COLOR)	],
//		GUI.HOVER_PROPERTIES : [ [new GUI.ShapeProperty(GUI.PROPERTY_BUTTON_SHAPE,
//											gui._createRectShape(color_accent1,GUI.NO_COLOR,true)),1,false] ]
//});

gui.registerPreset('menu/toolIcon',{
		GUI.PROPERTIES : [	new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR,GUI.WHITE)	],
		GUI.HOVER_PROPERTIES : [ [new GUI.ShapeProperty(GUI.PROPERTY_BUTTON_SHAPE,
											gui._createRectShape(color_accent2,GUI.NO_COLOR,true)),1,false] ]
});

gui.setDefaultShape(GUI.PROPERTY_WINDOW_ACTIVE_SHAPE,gui._createRectShape(new Util.Color4ub(0xE8,0xE8,0xE8,250),GUI.NO_COLOR,true));
gui.setDefaultShape(GUI.PROPERTY_WINDOW_PASSIVE_SHAPE,gui._createRectShape(new Util.Color4ub(0xE8,0xE8,0xE8,230),GUI.NO_COLOR,true));
gui.setDefaultShape(GUI.PROPERTY_WINDOW_ACTIVE_OUTER_SHAPE,gui._createOuterRectShadowShape(-2,4,-2,4,color_shadow));

//gui.setDefaultShape(GUI.PROPERTY_TAB_HEADER_ACTIVE_SHAPE,gui._createOuterRectShadowShape(1,0,6,6,color_shadow));
//gui.setDefaultColor(GUI.PROPERTY_TAB_HEADER_PASSIVE_TEXT_COLOR, GUI.WHITE);
//gui.setDefaultColor(GUI.PROPERTY_TAB_HEADER_ACTIVE_TEXT_COLOR, GUI.WHITE);
gui.setDefaultColor(GUI.PROPERTY_TAB_HEADER_ACTIVE_TEXT_COLOR, GUI.BLACK);
//gui.setDefaultShape(GUI.PROPERTY_TAB_HEADER_ACTIVE_SHAPE,gui._createRectShape(color_accent1,GUI.NO_COLOR,true));
gui.setDefaultShape(GUI.PROPERTY_TAB_HEADER_ACTIVE_SHAPE,gui._createRectShape(color_component2,GUI.NO_COLOR,true));
gui.setDefaultShape(GUI.PROPERTY_TAB_HEADER_PASSIVE_SHAPE,gui._createOuterRectShadowShape(0,0,1,1,color_shadow));



return NS;


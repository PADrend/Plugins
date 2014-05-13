/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Lukas Kopecki
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:PADrend] PADrend/GUI/Plugin.escript
 **
 **/


//! ---|> Plugin
var plugin = new Plugin({
		Plugin.NAME : 'PADrend/GUI',
		Plugin.DESCRIPTION : "Main application\'s GUI.",
		Plugin.VERSION : 0.6,
		Plugin.AUTHORS : "Claudius, Ralf & Benjamin",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend','PADrend/SceneManagement','PADrend/EventLoop','PADrend/SystemUI','LibGUIExt'],
		Plugin.EXTENSION_POINTS : [	]
});

// -------------------


/**
 * Plugin initialization.
 * ---|> Plugin
 */
plugin.init @(override) := fn(){
	//  Init global GUI Manager
	GUI.init(PADrend.SystemUI.getWindow(), PADrend.getEventContext());
	
	registerExtension('PADrend_Init',			this->initGUIResources,Extension.HIGH_PRIORITY+1);
	registerExtension('PADrend_AfterRendering', fn(...){ renderGUI(); }, Extension.LOW_PRIORITY*2);
	registerExtension('PADrend_UIEvent', 		fn(evt){ return gui.handleEvent(evt); });

	
	// right click menu
	if(systemConfig.getValue( 'PADrend.GUI.rightClickMenu',true)){
		registerExtension( 'PADrend_UIEvent',this->fn(evt){
			if(evt.type==Util.UI.EVENT_MOUSE_BUTTON && evt.button == Util.UI.MOUSE_BUTTON_RIGHT && evt.pressed && !PADrend.getEventContext().isCtrlPressed()){
				gui.openMenu(new Geometry.Vec2(evt.x,evt.y),'PADrend_SceneToolMenu');
			}
			return false;
		});
	}

	loadPlugins([
			__DIR__+"/MainToolbar.escript",
			__DIR__+"/MainWindow.escript",
			__DIR__+"/ToolsToolbar.escript" ],true);

	return true;
};


static MODE_DISABLED = false;
static MODE_NORMAL = 0;
static MODE_LAZY = 1;
static MODE_DUAL = 2;
static MODE_DUAL_COMPESSED = 3;

static guiMode = new DataWrapper(MODE_NORMAL);

plugin.guiMode :=  guiMode;

static gui_FBO;
static gui_Texture;
static initGUI_FBO = fn(){
	gui_FBO = new Rendering.FBO;

    renderingContext.pushAndSetFBO(gui_FBO);
    gui_Texture = Rendering.createStdTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight(),true);
    gui_FBO.attachColorTexture(renderingContext,gui_Texture);
    out(gui_FBO.getStatusMessage(renderingContext),"\n");

    renderingContext.popFBO();
};


static renderGUI = fn(){
	switch(guiMode()){
		case MODE_NORMAL:
			gui.display();
			break;
		case MODE_LAZY:{
			@(once) initGUI_FBO();
			gui.enableLazyRendering();
			renderingContext.pushAndSetFBO(gui_FBO);
			gui.display();
			renderingContext.popFBO();
			
			var blending=new Rendering.BlendingParameters;
			blending.enable();
			blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE_MINUS_SRC_ALPHA);
			renderingContext.pushAndSetBlending(blending);
			
			Rendering.drawTextureToScreen(renderingContext,
							new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()) ,
							gui_Texture,new Geometry.Rect(0,0,1,1));
			
			renderingContext.popBlending();
			gui.disableLazyRendering();
			break;
		}
		case MODE_DUAL:{
			@(once) initGUI_FBO();
			renderingContext.pushAndSetFBO(gui_FBO);
			renderingContext.clearScreen(new Util.Color4f(0,0,0,0));
			gui.display();
			renderingContext.popFBO();
			
			var blending=new Rendering.BlendingParameters;
			blending.enable();
			blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE_MINUS_SRC_ALPHA);
			renderingContext.pushAndSetBlending(blending);
			
			Rendering.drawTextureToScreen(renderingContext,
							new Geometry.Rect(0,0,renderingContext.getWindowWidth()*0.5,renderingContext.getWindowHeight()) ,
							gui_Texture,new Geometry.Rect(0,0,0.5,1));
			
			Rendering.drawTextureToScreen(renderingContext,
							new Geometry.Rect(renderingContext.getWindowWidth()*0.5,0,renderingContext.getWindowWidth()*0.5,renderingContext.getWindowHeight()) ,
							gui_Texture,new Geometry.Rect(0,0,0.5,1));
			
			renderingContext.popBlending();
			break;
		}
		case MODE_DUAL_COMPESSED:{
			@(once) initGUI_FBO();
			renderingContext.pushAndSetFBO(gui_FBO);
			renderingContext.clearScreen(new Util.Color4f(0,0,0,0));
			gui.display();
			renderingContext.popFBO();
			
			var blending=new Rendering.BlendingParameters;
			blending.enable();
			blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE_MINUS_SRC_ALPHA);
			renderingContext.pushAndSetBlending(blending);
			
			Rendering.drawTextureToScreen(renderingContext,
							new Geometry.Rect(0,0,renderingContext.getWindowWidth()*0.5,renderingContext.getWindowHeight()) ,
							gui_Texture,new Geometry.Rect(0,0,1,1));
			
			Rendering.drawTextureToScreen(renderingContext,
							new Geometry.Rect(renderingContext.getWindowWidth()*0.5,0,renderingContext.getWindowWidth()*0.5,renderingContext.getWindowHeight()) ,
							gui_Texture,new Geometry.Rect(0,0,1,1));
			
			renderingContext.popBlending();
			break;
		}
		case MODE_DISABLED:{
			break;
		}
		default:
			@(once) Runtime.warn("@(once) Invalid gui mode:"+guiMode());
	}
};
//Util.requirePlugin('PADrend/GUI').guiMode(2);


//! [ext:PADrend_Init]
plugin.initGUIResources := fn(){
	
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
	
	GUI.FileDialog.folderCacheProvider = PADrend.configCache;
};

 
return plugin;
// ------------------------------------------------------------------------------

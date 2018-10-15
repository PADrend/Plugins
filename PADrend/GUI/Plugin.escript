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

var plugin = new Plugin({
		Plugin.NAME : 'PADrend/GUI',
		Plugin.DESCRIPTION : "Main application\'s GUI.",
		Plugin.VERSION : 0.6,
		Plugin.AUTHORS : "Claudius, Ralf & Benjamin",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend','PADrend/SceneManagement','PADrend/EventLoop','PADrend/SystemUI'],
		Plugin.EXTENSION_POINTS : [	]
});

// -------------------
static gui;

plugin.init @(override) := fn(){
	//  Init global GUI Manager
	gui = new (module('LibGUIExt/GUI_ManagerExt'))( PADrend.getEventContext() );
	gui.setWindow( PADrend.SystemUI.getWindow() );
	gui.initDefaultFonts();  // see FontHandling.escript
	
	GLOBALS.gui := gui; //! \deprecated
	gui.windows := new Map; //! \deprecated
		
	Util.registerExtension('PADrend_Init',			fn(){
		module('LibGUIExt/FileDialog').folderCacheProvider = PADrend.configCache;
		module('./Style'); // init style
	},Extension.HIGH_PRIORITY+1);

	Util.registerExtension('PADrend_AfterRendering', fn(...){ renderGUI(); }, Extension.LOW_PRIORITY*2);
	
	Util.registerExtension('PADrend_Init', fn(){
		// register position converters: screen pos <-> gui pos
		gui.screenPosToGUIPos @(override) := [gui.screenPosToGUIPos] => fn(originalFun, pos){
			if(guiMode()==MODE_DUAL_COMPESSED){
				pos = new Geometry.Vec2(pos);
				pos.x( (pos.x()*2) % renderingContext.getWindowWidth() );
			}else if(guiMode()==MODE_DUAL){
				pos = new Geometry.Vec2(pos);
				pos.x( pos.x() % (renderingContext.getWindowWidth()*0.5) );
			}
			return originalFun(pos);
		};
		gui.guiPosToScreenPos @(override) := [gui.guiPosToScreenPos] => fn(originalFun, pos){
			if(guiMode()==MODE_DUAL_COMPESSED){
				pos = new Geometry.Vec2(pos);
				pos.x( pos.x()*0.5 );
			}
			return originalFun(pos);
		};
	});

	// init gui components
	Util.registerExtension('PADrend_Init', fn(){
//		module._registerModule('PADrend/gui',load('PADrend/gui.escript',{$__injectedGUIObject:GLOBALS.gui}));
		// workaround for bug in _registerModule.
		GLOBALS.__injectedGUIObject := gui;
		module('PADrend/gui');
	});
	
	// main gui event handler: pass ui-events to gui
	Util.registerExtension('PADrend_UIEvent', fn(evt){
		if(evt.isSet($x) && evt.isSet($y)){ //mouse event -> convert screen pos into gui pos
			var pos = gui.screenPosToGUIPos( [evt.x,evt.y] );
			evt = evt.clone();
			evt.x = pos.x();
			evt.y = pos.y();
		}
		return gui.handleEvent(evt); 
	});
	
	
	// right click menu
	if(systemConfig.getValue( 'PADrend.GUI.rightClickMenu',true)){
		Util.registerExtension( 'PADrend_UIEvent',this->fn(evt){
			if(evt.type==Util.UI.EVENT_MOUSE_BUTTON && evt.button == Util.UI.MOUSE_BUTTON_RIGHT && evt.pressed && !PADrend.getEventContext().isCtrlPressed()){
				gui.closeAllMenus();
				gui.openMenu(gui.screenPosToGUIPos( [evt.x,evt.y] ),'PADrend_SceneToolMenu');
			}
			return false;
		});
	}

	Util.loadPlugins([
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
    outln(gui_FBO.getStatusMessage(renderingContext));

    renderingContext.popFBO();
};

static doDisplayGUI = fn() {
	gui.display();
	// gui might mess with current state, so we need to reapply all state
	renderingContext.pushShader();
	renderingContext.popShader();
	renderingContext.applyChanges(true);
};

static renderGUI = fn(){
	switch(guiMode()){
		case MODE_NORMAL:
			doDisplayGUI();
			break;
		case MODE_LAZY:{
			@(once) initGUI_FBO();
			gui.enableLazyRendering();
			renderingContext.pushAndSetFBO(gui_FBO);
			doDisplayGUI();
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
			renderingContext.pushViewport();
			renderingContext.setViewport(0,0,renderingContext.getWindowWidth()*0.5,renderingContext.getWindowHeight());
			doDisplayGUI();
			renderingContext.popViewport();
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
			doDisplayGUI();
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

 
return plugin;
// ------------------------------------------------------------------------------

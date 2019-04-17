/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:PADrend] PADrend/SystemUI/Plugin.escript
 **
 **/

PADrend.SystemUI := new Plugin({
		Plugin.NAME : 'PADrend/SystemUI',
		Plugin.DESCRIPTION : "Application window with openGL support and frame-/rendering-context.",
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius, Ralf & Benjamin",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend'],
		Plugin.EXTENSION_POINTS : []
});

// -------------------

static window;
static eventContext;
static eventQueue;

PADrend.SystemUI.init @(override) := fn(){

	var windowSize = systemConfig.getValue('PADrend.window.size',[800,600]);

	{   // Create OpenGL Window

		PADrend.message("Creating Window...");
		
		var properties = Util.UI.Window.createPropertyObject();
		
		//! The window should not have a border.
		properties.borderless				= systemConfig.getValue('PADrend.window.noFrame', false);
		//! Create a rendering context with debugging support.
		properties.debug					= systemConfig.getValue('PADrend.Rendering.GLDebugOutput', false);
		//! Create a rendering context with a compatibility profile.
		properties.compatibilityProfile 	= systemConfig.getValue('PADrend.Rendering.GLCompabilityProfile', false); 
		//! Create a fullscreen window.
		properties.fullscreen				= systemConfig.getValue('PADrend.window.fullscreen', false);
		//! Should the window should be resizable?
		properties.resizable				= false;

		//! if config:window_multisampling is not false, multisampling is enabled with given number samples
		//! value: false,2,3,4,5,6..
		properties.multisamples				= systemConfig.getValue('PADrend.window.multisampling', false); 
		properties.multisampled				= properties.multisamples && properties.multisamples>0;
		
		//! if config:window_pos is not false, the window is positioned at given position [x,y]
		var windowPos = systemConfig.getValue('PADrend.window.pos', false);
		properties.positioned				= true & windowPos;
		properties.posX						= windowPos ? windowPos[0] : 0;
		properties.posY						= windowPos ? windowPos[1] : 0;

		//! The size of the client area of the window.
		properties.clientAreaWidth			=	windowSize[0];
		properties.clientAreaHeight			=	windowSize[1];

		//! The title string
		var title = systemConfig.getValue('PADrend.window.caption',"PADrend");
		if(systemConfig.getValue('PADrend.window.captionsuffix',false)) 
			title += " - " + (SIZE_OF_PTR==8?"64":"32") + " bit " + BUILD_TYPE;
		properties.title					= title;

		window = new Util.UI.Window(properties);
		if(!window) {
			exit;
		}
		// on windows, it is better to use the default icon as it supports alpha blending.
		if(!getOS().find("WINDOWS")){
			window.setIcon(__DIR__ + "/../resources/Icons/PADrendLogo32.png");
		}

		if(systemConfig.getValue('PADrend.window.warnIfVSync', false)) {
			if(window.getSwapInterval() > 0) {
				Runtime.warn("VSync is on. Buffer swaps are synchronized to VBlank. This might\n"
					+ "decrease performance. Set configuration option \"PADrend.window.warnIfVSync\"\n"
					+ "to \"false\" to deactivate this warning.");
			}
		}

		eventContext = new Util.UI.EventContext;
		eventQueue = eventContext.getEventQueue();
		eventQueue.registerWindow(window);
	}

	// ------------------
	{
		out("Creating Rendering Context".fillUp(40));
		Rendering.RenderingContext.initGLState();
		
		GLOBALS.frameContext = new MinSG.FrameContext();
		
		PADrend.frameStatistics = frameContext.getStatistics();
		
		GLOBALS.renderingContext = frameContext.getRenderingContext();
		renderingContext.setWindowClientArea(0, 0, windowSize[0], windowSize[1]);
		this.onWindowResized += fn(Number width,Number height){
			renderingContext.setWindowClientArea(0, 0, width, height);
		};
		
		showWaitingScreen(false);

		outln("ok.");
		
	}
	Rendering.outputGLInformation();
	if(systemConfig.getValue('PADrend.Rendering.GLDebugOutput', false)) {
		Rendering.enableDebugOutput();
	}

	{ // Replace default font
		var fontFile = Std.DataWrapper.createFromEntry(systemConfig, 'PADrend.renderingFont.fileName', "");
		var fontSize = Std.DataWrapper.createFromEntry(systemConfig, 'PADrend.renderingFont.size', 24);
		var replaceDefaultFont = [fontFile, fontSize] => fn(DataWrapper fontFile, DataWrapper fontSize, ...) {
			if(!fontFile().empty() && fontSize() > 0) {
				if(Util.isFile(fontFile())) {
					var textRenderer = new Rendering.TextRenderer(fontFile(), fontSize());
					frameContext.setTextRenderer(textRenderer);
				} else {
					Runtime.warn("Configured font file \"" + fontFile() + "\" does not exist.");
				}
			}
		};
		fontFile.onDataChanged += replaceDefaultFont;
		fontSize.onDataChanged += replaceDefaultFont;
		replaceDefaultFont();

		registerExtension('PADrend_Init', [fontFile, fontSize] => fn(DataWrapper fontFile, DataWrapper fontSize, ...) {
			gui.register('PADrend_MiscConfigMenu.renderingFont', [
				"----",
				{
					GUI.TYPE			:	GUI.TYPE_BUTTON,
					GUI.LABEL			:	"Font file: " + fontFile(),
					GUI.TOOLTIP			:	"Font that is used as the default rendering font.",
					GUI.ON_CLICK		:	[fontFile] => fn(DataWrapper fontFile) {
												gui.openDialog({
													GUI.TYPE		:	GUI.TYPE_FILE_DIALOG,
													GUI.LABEL		:	"Select font file",
													GUI.FILENAME	:	fontFile(),
													GUI.ON_ACCEPT	:	[fontFile] => fn(DataWrapper fontFile, String fileName) {
																			fontFile(fileName);
																		}
												});
											}
				},
				{
					GUI.TYPE			:	GUI.TYPE_RANGE,
					GUI.LABEL			:	"Font size",
					GUI.TOOLTIP			:	"Size in pixels of the default rendering font.",
					GUI.RANGE			:	[6, 100],
					GUI.RANGE_STEP_SIZE	:	1,
					GUI.DATA_WRAPPER	:	fontSize
				}
			]);
		});
	}
	// window config menu
	registerExtension('PADrend_Init', fn(){
		gui.register('PADrend_ConfigMenu.30_WindowConfig',['----',{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "System Window",
			GUI.MENU : 'PADrend_SystemUI_WindowConfigMenu',
			GUI.MENU_WIDTH : 150
		}]);
		
		gui.register('PADrend_SystemUI_WindowConfigMenu.10_main',fn(){
			var borderless = Std.DataWrapper.createFromEntry( systemConfig, 'PADrend.window.noFrame' );
			var size = Std.DataWrapper.createFromFunctions(
				fn(){ 		return toJSON(systemConfig.getValue('PADrend.window.size'),false); },
				fn(txt){	systemConfig.setValue('PADrend.window.size', parseJSON(txt)); 	}
			);
			var position = Std.DataWrapper.createFromFunctions(
				fn(){ 		return toJSON(systemConfig.getValue('PADrend.window.pos'),false); },
				fn(txt){	systemConfig.setValue('PADrend.window.pos', parseJSON(txt)); 	}
			);
			var tt =  "Save config and restart required!";
			return [
				"*System window*",
				{
					GUI.TYPE : 	GUI.TYPE_TEXT,
					GUI.LABEL : "Size",
					GUI.DATA_WRAPPER : size,
					GUI.TOOLTIP : tt,
					GUI.OPTIONS : [ "[800,600]","[1024,768]","[1280,1024]","[1280,740]","[1280,740]","[1366,768]","[1440,900]","[1920,1080]","[1920,1200]","[2560,1440]","[3840,1080]","[3840,2160]" ]
				},
				{
					GUI.TYPE : 	GUI.TYPE_TEXT,
					GUI.LABEL : "Position",
					GUI.DATA_WRAPPER : position,
					GUI.TOOLTIP : tt,
					GUI.OPTIONS : [ "false", "[0,0]" ]
				},
				{
					GUI.TYPE : 	GUI.TYPE_BOOL,
					GUI.LABEL : "borderless",
					GUI.DATA_WRAPPER : borderless,
					GUI.TOOLTIP : tt
				},
				
			];
		});
	});
	return true;
};

PADrend.SystemUI.getEventContext := fn() {
	return eventContext;
};

PADrend.SystemUI.getEventQueue := fn() {
	return eventQueue;
};

PADrend.SystemUI.getWindow := fn() {
	return window;
};


/*! Notified when the application window is resized.
	- Can be extended externally
	- Must be triggered externally by the main event handler. */
PADrend.SystemUI.onWindowResized := new Std.MultiProcedure; // fn(width,height){...}

PADrend.SystemUI.swapBuffers := fn() {
	window.swapBuffers();
};

PADrend.SystemUI.hideCursor := fn() {
	window.hideCursor();
};

PADrend.SystemUI.showCursor := fn() {
	window.showCursor();
};

PADrend.SystemUI.warpCursor := fn(Number x, Number y) {
	window.warpCursor(x, y);
};

PADrend.SystemUI.checkForKey := fn(){
	eventQueue.process();
	while(eventQueue.getNumEventsAvailable() > 0) {
		var evt = eventQueue.popEvent();
		if(evt.type==Util.UI.EVENT_KEYBOARD && evt.pressed)
			return evt.key;
	}	
	return false;
};

// --------------------
// Aliases

PADrend.getEventContext := PADrend.SystemUI -> PADrend.SystemUI.getEventContext;
PADrend.getEventQueue := PADrend.SystemUI -> PADrend.SystemUI.getEventQueue;


// --------------------


return PADrend.SystemUI;
// ------------------------------------------------------------------------------


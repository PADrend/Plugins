/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2018 Sascha Brandt <sascha@brandt.graphics>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static plugin = new Plugin({
		Plugin.NAME : 'PADrend/EventLoop',
		Plugin.DESCRIPTION : "PADrend's main event loop",
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius, Ralf & Benjamin",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend'],
		Plugin.EXTENSION_POINTS : [
		
			/* [ext:PADrend_KeyPressed]
			 * @param   Util.UI.Event
			 * @result  true iff consumed
			 *
			 * The extensions are executed for key presses on the keyboard.
			 * The event describing the key press is given as parameter.
			 * @note Extensions for this extension point are not executed for key releases.
			 */
			['PADrend_KeyPressed',ExtensionPoint.CHAINED],

			/* [ext:PADrend_UIEvent]
			 * @param   Util.UI.Event
			 * @result  true iff consumed
			 *
			 * The extensions are executed for user interface events.
			 * The event description is given as parameter.
			 * For example, the events can be caused by a mouse move, mouse button, keyboard, or joystick.
			 */
			['PADrend_UIEvent',ExtensionPoint.CHAINED],

			/* [ext:PADrend_BeforeRendering]
			 * @param   [RenderingPass*]
			 * Called before the rendering passes are executed. The only thing you probably want to do here is to 
			 * modify or create rendering passes. 
			 * \note When you are not implementing multiple rendering passes or want to perform fullscreen effects, 
			 *		this is NOT the right extension point for you! Have a look at 'PADrend_AfterFrame' instead.
			 *
			 */
			'PADrend_BeforeRendering',
			
			/* [ext:PADrend_BeforeRenderingPass]
			 * @param   RenderingPass
			 * Called before each rendering pass is executed. Here is e.g. the place to push FBO's for postprocessing effects.
			 */
			'PADrend_BeforeRenderingPass',
			
			/* [ext:PADrend_AfterRenderingPass]
			 * @param   RenderingPass
			 * Called after each rendering pass is executed. Here is e.g. the place to pop your FBO's or to annotate the final image.
			 */
			'PADrend_AfterRenderingPass',

			/* [ext:PADrend_AfterRendering]
			 * @param   camera (MinSG.AbstractCamera)
			 * @result  void
			 */
			'PADrend_AfterRendering',

			/* [ext:PADrend_AfterFrame]
			 * Called before the rendering buffer is swapped. Extensions should not modifiy the rendering buffer here, but can 
			 * exploit the time until the rendering is finished for various other tasks. E.g. :
			 * - Update the Camera
			 * - Update gui data
			 * - Execute commands
			 *
			 * @param   void
			 */
			'PADrend_AfterFrame',

			/* [ext:PADrend_OnAvgFPSUpdated]
			 * In regular intervals (normally every 0.5sec), the average fps is recalculated and passed to interested 
			 * listeners registered to this extension point.
			 *
			 * @param   the current average frame rate
			 */
			'PADrend_OnAvgFPSUpdated'
		]
});

// -------------------

static config = new (module('LibUtilExt/ConfigGroup'))(systemConfig,'PADrend.Rendering');
static setting_bgColor; 
{
	var bgColor_config = Std.DataWrapper.createFromEntry(config,'bgColor',[0.5,0.5,0.5,1.0]);
	setting_bgColor = new Std.DataWrapper( new Util.Color4f(bgColor_config()...) );
	setting_bgColor.onDataChanged += [bgColor_config]=>fn(bgColor_config,Util.Color4f c){	bgColor_config( [c.r(),c.g(),c.b(),c.a()] );	};
}
static setting_doClearScreen = new Std.DataWrapper(true);
static setting_glErrorChecking = Std.DataWrapper.createFromEntry(config,'GLErrorChecking',false);
static setting_renderingFlags =  Std.DataWrapper.createFromEntry(config,'flags',MinSG.FRUSTUM_CULLING);
static setting_waitForGlFinish = Std.DataWrapper.createFromEntry(config,'waitForGlFinish',true);
static setting_glDebugOutput = Std.DataWrapper.createFromEntry(config,'GLDebugOutput',false);
static setting_renderingLayers = Std.DataWrapper.createFromEntry(config,'renderingLayers',1);

static active = true;
static activeCamera; 
static taskScheduler;
static camerasUsedForLastFrame = [];
static defaultShader;

plugin.init @(override) := fn(){
	PADrend.RenderingPass := Std.module( 'PADrend/EventLoop/RenderingPass' ); //alias

	// activate normal camera by default
	Util.registerExtension('PADrend_Init', this->fn(){
		setting_glDebugOutput.onDataChanged += fn(b){
			if(b) {
				Rendering.enableDebugOutput();
			} else {
				Rendering.disableDebugOutput();
			}
		};
		setting_glDebugOutput.forceRefresh();
		this.setActiveCamera(GLOBALS.camera);	
	},Extension.HIGH_PRIORITY+1);

	//  Task scheduler
	// The task sheduler is called with a timeslot of 0.1 sec after every frame
	taskScheduler = new (Std.module('LibUtilExt/TaskScheduler'));
	Util.registerExtension('PADrend_AfterRendering',	fn(...){	taskScheduler.execute(0.1); } );
	
	// Behaviour manager
	if(MinSG.isSet($BehaviourManager)){
		Util.registerExtension('PADrend_AfterRendering',	fn(...){
			try{
				PADrend.getSceneManager().getBehaviourManager().executeBehaviours( PADrend.getSyncClock() );
			}catch(e){
				Runtime.warn(e);
			}
		});
	}
	
	{ // FPS counter
		var fpsCounter = new ExtObject;
		fpsCounter.start := Util.Timer.now();
		fpsCounter.fCounter := 0;
	
		Util.registerExtension('PADrend_AfterRendering', fpsCounter->fn(...){
			++fCounter;
			var now = Util.Timer.now();

			if ( now>start+0.5 ) {
				executeExtensions('PADrend_OnAvgFPSUpdated',fCounter/(now-start));
				start = now;
				fCounter = 0;
			}
		});
						
	}

	// experimental!!!!	
	// set global time uniform
	Util.registerExtension('PADrend_AfterRendering', fn(...){
			renderingContext.setGlobalUniform("sg_time",Rendering.Uniform.FLOAT,[PADrend.getSyncClock()]);
	});
	
	Util.registerExtension('PADrend_Start',this->fn(){
		while(active){
			outln("Starting EventLoop...");
			try{
				while(active)
					this.singleFrame();
			}catch(e){
				Runtime.log(Runtime.LOG_ERROR,e);
			active = false;
				continue;
			}
		}
	});
	
	// initialize fallback shader
	Util.registerExtension('PADrend_Init', fn(...) {
		if(!systemConfig.getValue('PADrend.Rendering.GLCompabilityProfile', false)) {
			// add default shader to root node if compability mode is disabled
			var shaderState = new MinSG.ShaderState;
			shaderState.getStateAttributeWrapper(MinSG.ShaderState.STATE_ATTR_SHADER_NAME)("universal3_default.shader");
			shaderState.recreateShader( PADrend.SceneManagement.getDefaultSceneManager() );
			defaultShader = shaderState.getShader();
		}
	}, Extension.LOW_PRIORITY-10000);
	return true;
};
// ------------------


plugin.getActiveCamera := 				fn(){	return activeCamera;	};
plugin.getBGColor := 					fn(){	return setting_bgColor();	};
plugin.getCamerasUsedForLastFrame :=	fn(){	return camerasUsedForLastFrame;	};
plugin.getRenderingFlags :=				fn(){	return setting_renderingFlags();	};
plugin.getRenderingLayers := 			fn(){	return setting_renderingLayers();	};

plugin.setActiveCamera :=				fn(MinSG.AbstractCameraNode newCamera){	activeCamera = newCamera;	};

plugin.setBGColor := fn(p...){
	setting_bgColor(new Util.Color4f(p...));
};

plugin.setRenderingFlags :=		fn(Number f){	setting_renderingFlags(f);	};
plugin.setRenderingLayers :=	fn(Number l){	setting_renderingLayers(l);	};


plugin.planTask := fn(mixed_TimeOrCallback,callback=void){
	if(callback)
		taskScheduler.plan(mixed_TimeOrCallback,callback);
	else 
		taskScheduler.plan(0,mixed_TimeOrCallback);
};

plugin.singleFrame := fn() {

	if(defaultShader)
		renderingContext.setShader(defaultShader);

	// create "default" rendering pass
	var renderingPasses = [ 
			new (Std.module('PADrend/EventLoop/RenderingPass'))("default",PADrend.getRootNode(),activeCamera, setting_renderingFlags(), 
																setting_doClearScreen() ? setting_bgColor() : false,setting_renderingLayers()) 
	];
	Util.executeExtensions('PADrend_BeforeRendering',renderingPasses);
	
	// -------------------
	// ---- Render Scene
	frameContext.beginFrame();

	var usedCameras = [];
	// execute all rendering passes in the given order
	while(!renderingPasses.empty()){
		var renderingPass = renderingPasses.popFront();
		usedCameras += renderingPass.getCamera();
		Util.executeExtensions('PADrend_BeforeRenderingPass',renderingPass);
		renderingPass.execute();
		Util.executeExtensions('PADrend_AfterRenderingPass',renderingPass);		
	}

	// restore default camera (in case e.g. the viewport has been changed);
	frameContext.setCamera(PADrend.getActiveCamera());
	frameContext.endFrame(setting_waitForGlFinish());

	Util.executeExtensions('PADrend_AfterRendering',getActiveCamera());

	camerasUsedForLastFrame.swap( usedCameras );
	
	// -------------------
	// ---- Handle User Inputs
	PADrend.getEventQueue().process();
	while(PADrend.getEventQueue().getNumEventsAvailable() > 0) {
		var evt = PADrend.getEventQueue().popEvent();
		try {
			// [ext:PADrend_UIEvent]
			if ( Util.executeExtensions('PADrend_UIEvent',evt) ){
			}else if (evt.type==Util.UI.EVENT_KEYBOARD && evt.pressed) {
				// [ext:PADrend_KeyPressed]
				if(Util.executeExtensions('PADrend_KeyPressed',evt)) {
				} else if( (evt.key==Util.UI.KEY_F4 && PADrend.getEventContext().isAltPressed()) || // [ALT] + [F4]
						(evt.key == Util.UI.KEY_Q && PADrend.getEventContext().isCtrlPressed()) ) { // [CTRL] + [q]{ 
					plugin.stop();
				}
			} else if (evt.type == Util.UI.EVENT_RESIZE) {
				Util.requirePlugin('PADrend/SystemUI').onWindowResized( evt.width, evt.height);
			} else if (evt.type == Util.UI.EVENT_QUIT) {
				plugin.stop();
			}
		} catch(exception) {
			Runtime.warn(exception);
		}
	}

	// Extensions (defined in PADrend/Plugin.escript)
	// - execute behaviourManager
	// - execute tastScheduler
	// - update fpsCounter
	// - execute cameraMover (in PADrend/Navigation
	Util.executeExtensions('PADrend_AfterFrame');
	
	
	// -------------------
	// ---- Swap Buffers
	PADrend.SystemUI.swapBuffers();
	
	// -------------------
	// ---- Check for GL error
	Rendering.enableGLErrorChecking();
	Rendering.checkGLError();
	if(!setting_glErrorChecking()) 
		Rendering.disableGLErrorChecking();
};

plugin.stop := fn(){
	active = false;
	PADrend.message("Stopping event loop...");
};

plugin.storeSettings := fn(){
	config.save();
};

// --------------------
// Aliases

// public data wrappers
plugin.setting_bgColor := setting_bgColor;
plugin.setting_doClearScreen := setting_doClearScreen;
plugin.setting_glDebugOutput := setting_glDebugOutput;
plugin.setting_glErrorChecking := setting_glErrorChecking;
plugin.setting_renderingFlags := setting_renderingFlags;
plugin.setting_renderingLayers := setting_renderingLayers;
plugin.setting_waitForGlFinish := setting_waitForGlFinish;

PADrend.EventLoop := plugin;
PADrend.getActiveCamera := 		plugin -> plugin.getActiveCamera;
PADrend.getBGColor := 			plugin -> plugin.getBGColor;
PADrend.getRenderingFlags :=	plugin -> plugin.getRenderingFlags;
PADrend.getRenderingLayers := 	plugin -> plugin.getRenderingLayers;
PADrend.setActiveCamera := 		plugin -> plugin.setActiveCamera;
PADrend.setBGColor := 			plugin -> plugin.setBGColor;
PADrend.setRenderingFlags :=	plugin -> plugin.setRenderingFlags;
PADrend.setRenderingLayers :=	plugin -> plugin.setRenderingLayers;
PADrend.planTask :=				plugin -> plugin.planTask;

return plugin;
// ------------------------------------------------------------------------------

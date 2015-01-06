/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
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


PADrend.EventLoop := plugin;
// -------------------

static active = true;
static activeCamera = void; 
plugin.bgColor := void; 
plugin.doClearScreen := true;
static glErrorChecking = DataWrapper.createFromConfig(systemConfig,'PADrend.Rendering.GLErrorChecking',false);
static renderingFlags = 0;
plugin.taskScheduler := void;
plugin.waitForGlFinish := void;
static camerasUsedForLastFrame = [];

static renderingLayers = 1;

plugin.init @(override) := fn(){
	PADrend.RenderingPass := Std.require( 'PADrend/EventLoop/RenderingPass' ); //alias

	registerExtension('PADrend_Init',this->ex_Init,Extension.HIGH_PRIORITY+1);
	registerExtension('PADrend_Start',this->ex_Start);


	//  Task scheduler
	// The task sheduler is called with a timeslot of 0.1 sec after every frame
	this.taskScheduler := new (Std.require('LibUtilExt/TaskScheduler'));
	registerExtension('PADrend_AfterRendering',	this->fn(...){	taskScheduler.execute(0.1); } );
	
	// Behaviour manager
	if(MinSG.isSet($BehaviourManager)){
		registerExtension('PADrend_AfterRendering',	this->fn(...){
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
	
		registerExtension('PADrend_AfterRendering', fpsCounter->fn(...){
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
	registerExtension('PADrend_AfterRendering', fn(...){
			renderingContext.setGlobalUniform("sg_time",Rendering.Uniform.FLOAT,[PADrend.getSyncClock()]);
	});
		
	return true;
};
// ------------------


//! [ext:PADrend_Init]
plugin.ex_Init := fn(){
   //  set rendering parameters
	renderingFlags = systemConfig.getValue('PADrend.Rendering.flags',MinSG.FRUSTUM_CULLING);
	this.waitForGlFinish = systemConfig.getValue('PADrend.Rendering.waitForGlFinish',true);

	//  set bgColor
	this.bgColor = new Util.Color4f( systemConfig.getValue('PADrend.Rendering.bgColor',[0.5,0.5,0.5,1.0]) );

	// activate normal camera by default
	this.setActiveCamera(GLOBALS.camera);
};
//! [ext:PADrend_Start]
plugin.ex_Start := fn(){
   while(active){
        out("Starting EventLoop...\n");
        try{
        	while(active)
				this.singleFrame();
        }catch(e){
            Runtime.log(Runtime.LOG_ERROR,e);
            continue;
        }
	}

};
plugin.getActiveCamera := 				fn(){	return activeCamera;	};
plugin.getBGColor := 					fn(){	return this.bgColor;	};
plugin.getCamerasUsedForLastFrame :=	fn(){	return camerasUsedForLastFrame;	};
plugin.getRenderingFlags :=				fn(){	return renderingFlags;	};
plugin.getRenderingLayers := 			fn(){	return renderingLayers;	};

plugin.setActiveCamera :=				fn(MinSG.AbstractCameraNode newCamera){	activeCamera = newCamera;	};

plugin.setBGColor := fn(Util.Color4f newColor){
	systemConfig.setValue('PADrend.Rendering.bgColor',[newColor.r(),newColor.g(),newColor.b(),newColor.a()]);
	this.bgColor = newColor;
};

plugin.setRenderingFlags :=		fn(Number f){	renderingFlags = f;	};
plugin.setRenderingLayers :=	fn(Number l){	renderingLayers = l;	};


plugin.planTask := fn(time,fun){
	this.taskScheduler.plan(time,fun);
};

plugin.singleFrame := fn() {

	// create "default" rendering pass
	var renderingPasses = [ new (Std.require('PADrend/EventLoop/RenderingPass'))("default",PADrend.getRootNode(),activeCamera, renderingFlags, this.doClearScreen ? this.bgColor : false,renderingLayers) ];
	executeExtensions('PADrend_BeforeRendering',renderingPasses);
	
	// -------------------
	// ---- Render Scene
	frameContext.beginFrame();

	var usedCameras = [];
	// execute all rendering passes in the given order
	while(!renderingPasses.empty()){
		var renderingPass = renderingPasses.popFront();
		usedCameras += renderingPass.getCamera();
		executeExtensions('PADrend_BeforeRenderingPass',renderingPass);
		renderingPass.execute();
		executeExtensions('PADrend_AfterRenderingPass',renderingPass);		
	}

	// restore default camera (in case e.g. the viewport has been changed);
	frameContext.setCamera(PADrend.getActiveCamera());

	frameContext.endFrame(this.waitForGlFinish);

	executeExtensions('PADrend_AfterRendering',getActiveCamera());

	camerasUsedForLastFrame.swap( usedCameras );
	
	// -------------------
	// ---- Handle User Inputs
	PADrend.getEventQueue().process();
	while(PADrend.getEventQueue().getNumEventsAvailable() > 0) {
		var evt = PADrend.getEventQueue().popEvent();
		try {
			// [ext:PADrend_UIEvent]
			if ( executeExtensions('PADrend_UIEvent',evt) ){
			}else if (evt.type==Util.UI.EVENT_KEYBOARD && evt.pressed) {
				// [ext:PADrend_KeyPressed]
				if(executeExtensions('PADrend_KeyPressed',evt)) {
				} else if( (evt.key==Util.UI.KEY_F4 && PADrend.getEventContext().isAltPressed()) || // [ALT] + [F4]
						(evt.key == Util.UI.KEY_Q && PADrend.getEventContext().isCtrlPressed()) ) { // [CTRL] + [q]{ 
					plugin.stop();
				}
			} else if (evt.type == Util.UI.EVENT_RESIZE) {
				renderingContext.setWindowClientArea(0, 0, evt.width, evt.height);
				static Listener = Std.require('LibUtilExt/deprecated/Listener');
				Listener.notify(Listener.TYPE_APP_WINDOW_SIZE_CHANGED, [evt.width, evt.height]);
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
	executeExtensions('PADrend_AfterFrame');
	
	
	// -------------------
	// ---- Swap Buffers
	PADrend.SystemUI.swapBuffers();
	
	// -------------------
	// ---- Check for GL error
	Rendering.enableGLErrorChecking();
	Rendering.checkGLError();
	if(!glErrorChecking()) 
		Rendering.disableGLErrorChecking();
};

plugin.stop := fn(){
	active = false;
	PADrend.message("Stopping event loop...");
};

// --------------------
// Aliases


plugin.glErrorChecking := glErrorChecking;

PADrend.getActiveCamera := 		plugin -> plugin.getActiveCamera;
PADrend.getBGColor := 			plugin -> plugin.getBGColor;
PADrend.getRenderingFlags :=	plugin -> plugin.getRenderingFlags;
PADrend.getRenderingLayers := 	plugin -> plugin.getRenderingLayers;
PADrend.setActiveCamera := 		plugin -> plugin.setActiveCamera;
PADrend.setBGColor := 			plugin -> plugin.setBGColor;
PADrend.setRenderingFlags :=	plugin -> plugin.setRenderingFlags;
PADrend.setRenderingLayers :=	plugin -> plugin.setRenderingLayers;
PADrend.planTask :=				plugin -> plugin.planTask;

// --------------------


return plugin;
// ------------------------------------------------------------------------------

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2014 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Effects] Effects/Stereo.escript
 ** 2009-11 Urlaubsprojekt...
 **/
 //! ---|> Plugin
var plugin = new Plugin({
		Plugin.NAME : ' Effects/Stereo',
		Plugin.DESCRIPTION : "Render in stereo mode.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend'],
		Plugin.EXTENSION_POINTS : []
});


static compressGUI;	// DataWrapper (true for stereo-tv mode)
static stereoMode;	// DataWrapper MODE_????
static MODE_DISABLED = 0;
static MODE_LEFT = 1;
static MODE_RIGHT = 2;
static MODE_SIDE_BY_SIDE_LR = 3;
static MODE_SIDE_BY_SIDE_RL = 4;
static MODE_ANAGLYPH = 10;

static leftEyeHeadOffset; // DataWrapper "0 0 0"
static rightEyeHeadOffset; // DataWrapper "0 0 0"

static lCamera; // void | CameraNode
static rCamera; // void | CameraNode

//! [ext:PADrend_BeforeRendering]
static createRenderingPasses = fn(renderingPasses){

	var defaultPassFound = false;
	var newPasses = [];
	var dolly = PADrend.getDolly();
	var originalCamera = dolly.getCamera();

	foreach(renderingPasses as var pass){

		// only modify the "default" pass
		if(pass.getId()!="default"){
			newPasses += pass;
			continue;
		}
		defaultPassFound = true;

		// adapt parameters
		foreach( [lCamera,rCamera] as var cam){
			if(cam)
				cam.setNearFar( originalCamera.getNearPlane(), originalCamera.getFarPlane() );
		}
		var viewport = originalCamera.getViewport();

		switch(stereoMode()){
			case MODE_LEFT:{
				lCamera.setViewport( viewport );
				newPasses += new PADrend.RenderingPass(pass.getId()+"_left", pass.getRootNode(), lCamera, pass.getRenderingFlags(), pass.getClearColor(), pass.getRenderingLayers());
				break;
			}
			case MODE_RIGHT:{
				rCamera.setViewport( viewport );
				newPasses += new PADrend.RenderingPass(pass.getId()+"_right", pass.getRootNode(), rCamera, pass.getRenderingFlags(), pass.getClearColor(), pass.getRenderingLayers());
				break;
			}
			case MODE_SIDE_BY_SIDE_LR:{
				lCamera.setViewport( viewport.clone().setWidth( viewport.getWidth()*0.5) );
				newPasses += new PADrend.RenderingPass(pass.getId()+"_left", pass.getRootNode(), lCamera, pass.getRenderingFlags(), pass.getClearColor(), pass.getRenderingLayers());

				rCamera.setViewport( viewport.clone().setWidth( viewport.getWidth()*0.5).setX(viewport.getWidth()*0.5) );
				newPasses += new PADrend.RenderingPass(pass.getId()+"_right", pass.getRootNode(), rCamera, pass.getRenderingFlags(), pass.getClearColor(), pass.getRenderingLayers());
				break;
			}
			case MODE_SIDE_BY_SIDE_RL:{
				lCamera.setViewport( viewport.clone().setWidth( viewport.getWidth()*0.5).setX(viewport.getWidth()*0.5) );
				newPasses += new PADrend.RenderingPass(pass.getId()+"_left", pass.getRootNode(), lCamera, pass.getRenderingFlags(), pass.getClearColor(), pass.getRenderingLayers());

				rCamera.setViewport( viewport.clone().setWidth( viewport.getWidth()*0.5) );
				newPasses += new PADrend.RenderingPass(pass.getId()+"_right", pass.getRootNode(), rCamera, pass.getRenderingFlags(), pass.getClearColor(), pass.getRenderingLayers());
				break;
			}
			// ANAGLYPH...
		}
	}
	renderingPasses.swap(newPasses);

	if(!defaultPassFound){
		Runtime.warn("No 'default' rendering pass found.");
	}
};


plugin.init @(override) := fn(){
	stereoMode = DataWrapper.createFromConfig(systemConfig,'Effects.Stereo.stereoMode',MODE_DISABLED);
	compressGUI = DataWrapper.createFromConfig(systemConfig,'Effects.Stereo.compressGUI',false);
	compressGUI.onDataChanged += fn(...){
		stereoMode.forceRefresh();
	};
	leftEyeHeadOffset = DataWrapper.createFromConfig(systemConfig,'Effects.Stereo.lOffset',"-0.03 0 0");
	rightEyeHeadOffset = DataWrapper.createFromConfig(systemConfig,'Effects.Stereo.rOffset',"0.03 0 0");
	
	PADrend.syncVars.addDataWrapper('Effects.Stereo.lOffset', leftEyeHeadOffset);
	PADrend.syncVars.addDataWrapper('Effects.Stereo.rOffset', rightEyeHeadOffset);

	
	registerExtension('PADrend_Init',this->fn(){

		leftEyeHeadOffset.onDataChanged += fn(str){
			var arr = str.split(" ");
			if(arr.count()!=3){
				Runtime.warn("Ill formatted eye offset: "+str);
				arr = [0,0,0];
			}
			if(lCamera)
				lCamera.setRelOrigin( arr );
		};
		rightEyeHeadOffset.onDataChanged += fn(str){
			var arr = str.split(" ");
			if(arr.count()!=3){
				Runtime.warn("Ill formatted eye offset: "+str);
				arr = [0,0,0];
			}
			if(rCamera)
				rCamera.setRelOrigin( arr );
		};

		stereoMode.onDataChanged += fn(mode){
			var dolly = PADrend.getDolly();
			var originalCamera = dolly.getCamera();

			// cleanup old cameras
			if(lCamera){
				MinSG.destroy(lCamera);
				lCamera = void;
			}
			if(rCamera){
				MinSG.destroy(rCamera);
				rCamera = void;
			}

			// setup cameras
			if( mode==MODE_RIGHT||mode==MODE_SIDE_BY_SIDE_LR||mode==MODE_SIDE_BY_SIDE_RL||mode==MODE_ANAGLYPH ){
				rCamera = originalCamera.clone();
				dolly.getHeadNode() += rCamera;
			}
			if( mode==MODE_LEFT||mode==MODE_SIDE_BY_SIDE_LR||mode==MODE_SIDE_BY_SIDE_RL||mode==MODE_ANAGLYPH ){
				lCamera = originalCamera.clone();
				dolly.getHeadNode() += lCamera;
			}
			if( mode==MODE_SIDE_BY_SIDE_LR||mode==MODE_SIDE_BY_SIDE_RL ){
				Util.requirePlugin('PADrend/GUI').guiMode( compressGUI() ? 3:2); // temp!!!!!!!!!!!!!!
			}else{
				Util.requirePlugin('PADrend/GUI').guiMode(0); // temp!!!!!!!!!!!!!!
			}

			// register extension
			@(once) static isActive = false;
			if(mode==MODE_DISABLED){
				isActive = false;
				originalCamera.setRelOrigin( [0,0,0] );
			}else if(!isActive){
				isActive = true;
				registerExtension('PADrend_BeforeRendering',fn(renderingPasses){
					if(!isActive)
						return $REMOVE;
					createRenderingPasses(renderingPasses);
				});
			}

			leftEyeHeadOffset.forceRefresh();
			rightEyeHeadOffset.forceRefresh();
		};
		stereoMode.forceRefresh();

		Util.requirePlugin('PADrend/RemoteControl').registerFunctions({
            'EffectsStereo.toggle' : fn(){
                stereoMode(stereoMode() != MODE_DISABLED ? MODE_DISABLED : MODE_SIDE_BY_SIDE_LR ) ;
                print_r(stereoMode());
                return true;
            },
        });
	});
        
	// ------------------------
	module.on('PADrend/gui', fn(gui){
		// gui
		gui.register('Effects_MainMenu.stereo',[
			{
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "Stereoscopic",
				GUI.MENU : 'Effects_Stereo'
			}
		]);
		gui.register('Effects_Stereo.main',[
			{
				GUI.TYPE : GUI.TYPE_SELECT,
				GUI.DATA_WRAPPER : stereoMode,
				GUI.OPTIONS : [
					[MODE_DISABLED,"Disabled"],
					[MODE_LEFT,"Left eye"],
					[MODE_RIGHT,"Right eye"],
					[MODE_SIDE_BY_SIDE_LR,"SideBySide L-R"],
					[MODE_SIDE_BY_SIDE_RL,"SideBySide R-L"],
					// Anaglyph
				],
				GUI.TOOLTIP : "Stero mode"
			},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.DATA_WRAPPER : leftEyeHeadOffset,
				GUI.OPTIONS : ["-0.03 0 0"],
				GUI.TOOLTIP : "Left eye's offset relative to head node (cm).\nx y z"
			},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.DATA_WRAPPER : rightEyeHeadOffset,
				GUI.OPTIONS : ["0.03 0 0"],
				GUI.TOOLTIP : "Right eye's offset relative to head node (cm).\nx y z"
			},
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.DATA_WRAPPER : compressGUI,
				GUI.LABEL : "Compress GUI",
				GUI.TOOLTIP : "Enable for sideBySide stereo configurations\n having halved horizontal resolution.",
			},
			'----'
		]);

	});

	return true;
};

// ---------------------------------------------------------
return plugin;

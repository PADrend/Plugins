/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011-2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:PADrend] PADrend/SceneManagement/Plugin.escript
 **
 **/
PADrend.SceneManagement := new Plugin({
		Plugin.NAME : 'PADrend/SceneManagement',
		Plugin.DESCRIPTION : "Scene management and root node handling",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius, Ralf & Benjamin",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend'],
		Plugin.EXTENSION_POINTS : [
			/* [ext:PADrend_OnSceneSelected
			 * Called when a scene is selected.
			 *
			 * @param The selected scene
			 * @result  void
			 */
			'PADrend_OnSceneSelected',
			
			/* [ext:PADrend_OnSceneListChanged
			 * Called when the list of available scenes changed.
			 *
			 * @param The array of scenes (do not alter!)
			 * @result  void
			 */
			'PADrend_OnSceneListChanged',
						
			/* [ext:PADrend_OnSceneRegistered]
			 * Called when a new scene is registered (e.g. after loading).
			 *
			 * @param The new scene's root node
			 * @result  void
			 */
			'PADrend_OnSceneRegistered',
		]
});

var SceneManagement = PADrend.SceneManagement;

static registeredScenes = [];
static rootNode = void;
static activeScene = void;
static defaultSceneManager = void;
static dolly = void;

SceneManagement._defaultLight := void; // directional light 0; formerly known as PADrend.sun


SceneManagement.init @(override) := fn(){
	
	defaultSceneManager = new (Std.require( 'LibMinSGExt/SceneManagerExt' ));

	{
		registerExtension('PADrend_Init',this->ex_Init,Extension.HIGH_PRIORITY+2);
		registerExtension('PADrend_OnSceneRegistered', Std.require('LibMinSGExt/Traits/PersistentNodeTrait').initTraitsInSubtree);
	}
	
	return true;
};


//! [ext:PADrend_Init]
SceneManagement.ex_Init := fn(...){
	{	//  create Camera and dolly
		outln("Creating SceneGraph elements...");

		// --
		// create default perspective camera
		GLOBALS.camera = new MinSG.CameraNode;
		camera.name := "DefaultCamera";
		var viewport = systemConfig.getValue('PADrend.Camera.viewport',false);
		if(!viewport)
			viewport = [0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()];
		camera.setViewport( new Geometry.Rect(viewport[0],viewport[1],viewport[2],viewport[3]));
		camera.setNearFar(systemConfig.getValue('PADrend.Camera.near',0.1),systemConfig.getValue('PADrend.Camera.far',5000));
		camera.applyVerticalAngle(systemConfig.getValue('PADrend.Camera.vAngle',90));
		// when the application window is resized:
		
		static Listener = Std.require('LibUtilExt/deprecated/Listener');
		Listener.add( Listener.TYPE_APP_WINDOW_SIZE_CHANGED, camera->fn(evt,newSize){
			// update viewport only when it has not been fixed in the config
			if(! systemConfig.getValue('PADrend.Camera.viewport',false))
				this.setViewport( new Geometry.Rect( 0,0,newSize[0],newSize[1]));
			// if no observer position is set, this is a normal angle based camera and the angle should be updated
			if(!dolly.observerPosition)
				this.applyVerticalAngle(systemConfig.getValue('PADrend.Camera.vAngle'));
		});

		frameContext.setCamera( camera );
		
		// --
		// create dolly for camera
		dolly = new MinSG.ListNode;
		//! \see MinSG.DefaultDollyNodeTrait
		Traits.addTrait( dolly,Std.require('LibMinSGExt/Traits/DefaultDollyNodeTrait'),camera );


		setConfigInfo('PADrend.Camera.observerPosition',"[x,y,z] or false. If false, the default 'angle'-based camera is used.");
		setConfigInfo('PADrend.Camera.frame',"false or corners of projection frame e.g. [[-1,1,-1],[-1,-1,-1],[1,-1,-1]]. To use the frame, observerPosition has to be set. ");

		dolly.setFrame(systemConfig.getValue('PADrend.Camera.frame',false));//[[-1,1,-1],[-1,-1,-1],[1,-1,-1]]
		dolly.setRelPosition(new Geometry.Vec3(systemConfig.getValue('PADrend.Camera.position',[0,0,0])));

		// --
		// add camera ortho
		var cameraOrtho = new MinSG.CameraNodeOrtho();
		cameraOrtho.name := "OrthoCamera";
		cameraOrtho.setViewport( new Geometry.Rect(viewport[0],viewport[1],viewport[2],viewport[3]));
		cameraOrtho.setNearFar(systemConfig.getValue('PADrend.Camera.near',0.1),systemConfig.getValue('PADrend.Camera.far',5000));
		dolly.addChild(cameraOrtho);
		// when the application window is resized:
		Listener.add( Listener.TYPE_APP_WINDOW_SIZE_CHANGED, cameraOrtho->fn(evt,newSize){
			// update viewport only when it has not been fixed in the config
			if(! systemConfig.getValue('PADrend.Camera.viewport',false))
				this.setViewport( new Geometry.Rect( 0,0,newSize[0],newSize[1]));
		});
		
		// --
		// add sound-listener to camera
		if(MinSG.isSet($SoundReceivingBehaviour)){
			Sound.initSoundSystem();
			PADrend.getSceneManager().getBehaviourManager().registerBehaviour( new MinSG.SoundReceivingBehaviour(camera) );
		}
	}
	
	{  // Create Scene
		rootNode = new MinSG.ListNode;
		getRootNode().name := "RootNode";

		setConfigInfo('PADrend.sun',"Global directional light source.");
		if(systemConfig.getValue('PADrend.sun.enabled',true)){
			this._defaultLight = new MinSG.LightNode();
			this.initDefaultLightParameters();
			getRootNode().addChild(_defaultLight);
			this.lightingState := new MinSG.LightingState();
			lightingState.setLight(_defaultLight);
			getRootNode().addState(lightingState);
		}

		getRootNode().addChild(dolly);
		this.createNewSceneRoot("new MinSG.ListNode",false);
	}
   	defaultSceneManager.addSearchPath( Util.requirePlugin('LibRenderingExt').getBaseFolder() + "/resources/" );

};

/*! Set the defaultLight's parameter to the default values (position, color, etc. )
	\note this method can be called externally to restore the defaultLight's (= sun's) original parameters */
SceneManagement.initDefaultLightParameters := fn(){
	_defaultLight.name := "Sun";
	_defaultLight.setRelPosition(new Geometry.Vec3(systemConfig.getValue('PADrend.sun.position',[100,100,100])));
	_defaultLight.rotateToWorldDir(new Geometry.Vec3(systemConfig.getValue('PADrend.sun.direction',[0,1,0.6])));
	_defaultLight.setAmbientLightColor(new Util.Color4f(systemConfig.getValue('PADrend.sun.ambient',[0.5,0.5,0.5,1.0])));
	_defaultLight.setDiffuseLightColor(new Util.Color4f(systemConfig.getValue('PADrend.sun.diffuse',[0.8,0.8,0.8,1.0])));
	_defaultLight.setSpecularLightColor(new Util.Color4f(systemConfig.getValue('PADrend.sun.specular',[1.0,1.0,1.0,1.0])));
};

// -------------------------------------------------------------

SceneManagement.createNewSceneRoot := fn(String t,debugOutput=true){
	var newSceneRoot = eval(t+";");
	if(! (newSceneRoot---|>MinSG.Node) )
		return false;

	newSceneRoot.name := "";
	newSceneRoot.constructionString:=t;

	this.registerScene(newSceneRoot);
	this.selectScene(newSceneRoot);
	return newSceneRoot;
};

SceneManagement.deleteScene := fn(scene) {
	if(registeredScenes.contains(scene)) {
		if(scene == getCurrentScene()) {
			selectScene(void);
		}
		var index = registeredScenes.findValue(scene);
		registeredScenes.removeIndex(index);
		MinSG.destroy(scene);
		
		executeExtensions('PADrend_OnSceneListChanged',registeredScenes.clone());
	}
};

SceneManagement.getCurrentScene :=	fn(){	return activeScene;	};

SceneManagement.getDefaultLight :=	fn(){	return this._defaultLight;	};

//! Returns the unique global root node.
SceneManagement.getRootNode :=		fn(){	return rootNode;	};

SceneManagement.getSceneList :=		fn(){	return registeredScenes;	};

SceneManagement.getSceneManager :=	fn(){	return activeScene&&activeScene.isSet($__sceneManager) ? activeScene.__sceneManager : defaultSceneManager;	};

SceneManagement.loadScene := fn(filename,Number importOptions = MinSG.SceneManager.IMPORT_OPTION_USE_TEXTURE_REGISTRY | MinSG.SceneManager.IMPORT_OPTION_USE_MESH_REGISTRY){
	showWaitingScreen();
	var sceneRoot=PADrend.getSceneManager().loadScene(filename,importOptions);
	if(sceneRoot)
		this.registerScene(sceneRoot);
	return sceneRoot;
};

SceneManagement.mergeScenes := fn(targetScene,Collection scenes) {
	foreach(scenes as var s){
		if(s==targetScene)
			continue;
		if(registeredScenes.contains(s)){
			var index = registeredScenes.findValue(s);
			registeredScenes.removeIndex(index);
		}
		targetScene.addChild(s);
	}
	executeExtensions('PADrend_OnSceneListChanged',registeredScenes.clone());
};

SceneManagement.registerScene := fn(MinSG.Node scene) {
	if(!registeredScenes.contains(scene)) {
		registeredScenes.pushBack(scene);
	}
	if(!getCurrentScene()) {
		selectScene(scene);
	}
	// store scene manager at scene (\todo create a new one for each scene or workspace!)
	if(!scene.isSet($__sceneManager)||!scene.__sceneManager)
		scene.__sceneManager := defaultSceneManager;
		
	if(!scene.getAttribute('constructionString')) scene.constructionString:="";
	if(!scene.getAttribute('name')) scene.name:="";
	executeExtensions('PADrend_OnSceneRegistered',scene);
	executeExtensions('PADrend_OnSceneListChanged',registeredScenes.clone());
};
SceneManagement.unregisterScene := fn(MinSG.Node scene) {
	if(registeredScenes.contains(scene)) {
		if(scene == getCurrentScene()) {
			selectScene(void);
		}
		var index = registeredScenes.findValue(scene);
		registeredScenes.removeIndex(index);
		executeExtensions('PADrend_OnSceneListChanged',registeredScenes.clone());
	}
};

SceneManagement.selectScene := fn(scene) {
	var oldScene = this.getCurrentScene();
	
	if(scene != oldScene){
		if(oldScene) 
			this.getRootNode().removeChild(oldScene);
		
		activeScene = scene;
		if(scene){
			this.getRootNode().addChild(scene);
			this.initCoordinateSystem( this.getSceneCoordinateSystem(scene) );
		}
		if(scene.isSet($filename) && scene.filename){
			var f = new Util.FileName(scene.filename);
			this.getSceneManager().setWorkspaceRootPath( f.getFSName() + "://" + f.getDir() );
		}else{
			this.getSceneManager().setWorkspaceRootPath( false );
		}
		
	}
	executeExtensions('PADrend_OnSceneSelected',scene);
};



// --------------------------------------------------------------------------------------------
// World Up Vector / root Node transformation

SceneManagement.NODE_ATTR_UP_AXIS := "UP_AXIS";
SceneManagement.UP_AXIS_Y := "Y_UP";
SceneManagement.UP_AXIS_Z := "Z_UP";

SceneManagement.dollyProxy @(private) := void;
SceneManagement.currentCoordinateSystem @(private) := SceneManagement.UP_AXIS_Y;

//! (internal)
SceneManagement.getSceneCoordinateSystem @(private) := fn( MinSG.Node sceneRoot){
	var c = sceneRoot.findNodeAttribute(this.NODE_ATTR_UP_AXIS);
	return c ? c : this.UP_AXIS_Y;
};

//! (internal)
SceneManagement.initCoordinateSystem @(private) := fn( [PADrend.SceneManagement.UP_AXIS_Y, PADrend.SceneManagement.UP_AXIS_Z] upAxis){
	var dolly = PADrend.getDolly();
	
	if(!this.dollyProxy){
		this.dollyProxy = new MinSG.ListNode;
		this.dollyProxy.name := "Dolly proxy node";
		var p = dolly.getParent();
		p -= dolly;
		this.dollyProxy += dolly;
		p += this.dollyProxy;
	}
	if(upAxis == this.UP_AXIS_Y){
		frameContext.setWorldRightVector ( new Geometry.Vec3(1,0,0) );
		frameContext.setWorldUpVector ( new Geometry.Vec3(0,1,0) );
		frameContext.setWorldFrontVector ( new Geometry.Vec3(0,0,1) );
		this.dollyProxy.resetRelTransformation();
	}
	else if(upAxis == this.UP_AXIS_Z){
		frameContext.setWorldRightVector ( new Geometry.Vec3(1,0,0) );
		frameContext.setWorldUpVector ( new Geometry.Vec3(0,0,1) );
		frameContext.setWorldFrontVector ( new Geometry.Vec3(0,-1,0) );
		this.dollyProxy.resetRelTransformation();
		this.dollyProxy.rotateLocal_deg( 90, this.dollyProxy.worldDirToLocalDir(new Geometry.Vec3(1,0,0)));
	}
	this.currentCoordinateSystem = upAxis;
};

//! (internal)
SceneManagement.markSceneCoordinateSystem @(private) := fn( MinSG.Node sceneRoot, String coordinateSystemId){
	sceneRoot.setNodeAttribute(this.NODE_ATTR_UP_AXIS, coordinateSystemId);
	if(sceneRoot == this.getCurrentScene())
		this.initCoordinateSystem(coordinateSystemId);
};

// ----------------------------------------
// Coordinate system

SceneManagement.getCurrentSceneGroundPlane := fn(Number offset=0.0){
	var scene = this.getCurrentScene();
	if(this.isSceneCoordinateSystem_YUp(scene)){
		return new Geometry.Plane(new Geometry.Vec3(0,1,0),scene.getWorldBB().getMinY()+offset);
	}else if(this.isSceneCoordinateSystem_ZUp(scene)){
		return new Geometry.Plane(new Geometry.Vec3(0,0,1),scene.getWorldBB().getMinZ()+offset);
	}else{
		assert(false);
	}
};

PADrend.getWorldRightVector := fn(){ return frameContext.getWorldRightVector(); };
PADrend.getWorldUpVector	:= fn(){ return frameContext.getWorldUpVector(); };
PADrend.getWorldFrontVector := fn(){ return frameContext.getWorldFrontVector(); };

SceneManagement.markSceneCoordinateSystem_YUp := fn(MinSG.Node sceneRoot){	this.markSceneCoordinateSystem(sceneRoot,this.UP_AXIS_Y);	};
SceneManagement.markSceneCoordinateSystem_ZUp := fn(MinSG.Node sceneRoot){	this.markSceneCoordinateSystem(sceneRoot,this.UP_AXIS_Z);	};

SceneManagement.isCurrentCoordinateSystem_YUp := fn(){	return this.currentCoordinateSystem == this.UP_AXIS_Y;	};
SceneManagement.isCurrentCoordinateSystem_ZUp := fn(){	return this.currentCoordinateSystem == this.UP_AXIS_Z;	};

SceneManagement.isSceneCoordinateSystem_YUp := fn(MinSG.Node sceneRoot){	return this.getSceneCoordinateSystem(sceneRoot) == this.UP_AXIS_Y;	};
SceneManagement.isSceneCoordinateSystem_ZUp := fn(MinSG.Node sceneRoot){	return this.getSceneCoordinateSystem(sceneRoot) == this.UP_AXIS_Z;	};


// --------------------
// Aliases


GLOBALS.getCurrentScene := SceneManagement->SceneManagement.getCurrentScene; //!< \deprecated
GLOBALS.loadScene := SceneManagement->SceneManagement.loadScene; //!< \deprecated
GLOBALS.registerScene := SceneManagement->SceneManagement.registerScene; //!< \deprecated
GLOBALS.selectScene := SceneManagement->SceneManagement.selectScene; //!< \deprecated

PADrend.createNewSceneRoot := SceneManagement->SceneManagement.createNewSceneRoot;
PADrend.deleteScene := SceneManagement->SceneManagement.deleteScene;
PADrend.getCurrentScene := SceneManagement->SceneManagement.getCurrentScene;
PADrend.getCurrentSceneGroundPlane := SceneManagement->SceneManagement.getCurrentSceneGroundPlane;
PADrend.getDolly := fn(){ return dolly;	};
PADrend.getDefaultLight := SceneManagement->SceneManagement.getDefaultLight;
PADrend.getRootNode := SceneManagement->SceneManagement.getRootNode;
PADrend.getSceneList := SceneManagement->SceneManagement.getSceneList;
PADrend.getSceneManager := SceneManagement->SceneManagement.getSceneManager;
PADrend.isCurrentCoordinateSystem_YUp := SceneManagement->SceneManagement.isCurrentCoordinateSystem_YUp;
PADrend.isCurrentCoordinateSystem_ZUp := SceneManagement->SceneManagement.isCurrentCoordinateSystem_ZUp;
PADrend.isSceneCoordinateSystem_YUp := SceneManagement->SceneManagement.isSceneCoordinateSystem_YUp;
PADrend.isSceneCoordinateSystem_ZUp := SceneManagement->SceneManagement.isSceneCoordinateSystem_ZUp;
PADrend.loadScene := SceneManagement->SceneManagement.loadScene;
PADrend.markSceneCoordinateSystem_YUp := SceneManagement->SceneManagement.markSceneCoordinateSystem_YUp;
PADrend.markSceneCoordinateSystem_ZUp := SceneManagement->SceneManagement.markSceneCoordinateSystem_ZUp;
PADrend.mergeScenes := SceneManagement->SceneManagement.mergeScenes;
PADrend.registerScene := SceneManagement->SceneManagement.registerScene;
PADrend.selectScene := SceneManagement->SceneManagement.selectScene;
PADrend.unregisterScene := SceneManagement->SceneManagement.unregisterScene;

// -------------------

return PADrend.SceneManagement;
// ------------------------------------------------------------------------------

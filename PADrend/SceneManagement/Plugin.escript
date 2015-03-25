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
		Plugin.REQUIRES : ['PADrend','LibRenderingExt'],
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

static SceneManagement = PADrend.SceneManagement;

static registeredScenes = [];
static rootNode = void;
static activeScene = void;
static defaultSceneManager = void;
static dolly = void;

static _defaultLight; // directional light 0; formerly known as PADrend.sun


static SceneManager = Std.require( 'LibMinSGExt/SceneManagerExt' );
static SceneMarkerTrait = Std.require('LibMinSGExt/Traits/SceneMarkerTrait');

static initSceneManager = fn(sceneManager){
	sceneManager.addSearchPath( Util.requirePlugin('LibRenderingExt').getBaseFolder() + "/resources/" );
	sceneManager.registerNode( "L:Sun", _defaultLight );
};


SceneManagement.init @(override) := fn(){
	defaultSceneManager = new SceneManager;
	Util.registerExtension('PADrend_Init',this->ex_Init,Extension.HIGH_PRIORITY+2);
	Util.registerExtension('PADrend_OnSceneRegistered', Std.require('LibMinSGExt/Traits/PersistentNodeTrait').initTraitsInSubtree);
	return true;
};

//SceneManagement.init @(override) := fn(){

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
		
		Util.requirePlugin('PADrend/SystemUI').onWindowResized += [camera] => fn(camera, width,height){
			// update viewport only when it has not been fixed in the config
			if(! systemConfig.getValue('PADrend.Camera.viewport',false))
				camera.setViewport( new Geometry.Rect( 0,0,width,height));
			// if no observer position is set, this is a normal angle based camera and the angle should be updated
			if(!PADrend.getDolly().observerPosition)
				camera.applyVerticalAngle(systemConfig.getValue('PADrend.Camera.vAngle'));
		};

		frameContext.setCamera( camera );
		
		// --
		// create dolly for camera
		dolly = new MinSG.ListNode;
		//! \see MinSG.DefaultDollyNodeTrait
		Std.Traits.addTrait( dolly,Std.require('LibMinSGExt/Traits/DefaultDollyNodeTrait'),camera );


		setConfigInfo('PADrend.Camera.observerPosition',"[x,y,z] or false. If false, the default 'angle'-based camera is used.");
		setConfigInfo('PADrend.Camera.frame',"false or corners of projection frame e.g. [[-1,1,-1],[-1,-1,-1],[1,-1,-1]]. To use the frame, observerPosition has to be set. ");

		dolly.setFrame(systemConfig.getValue('PADrend.Camera.frame',false));//[[-1,1,-1],[-1,-1,-1],[1,-1,-1]]
		dolly.setRelPosition(new Geometry.Vec3(systemConfig.getValue('PADrend.Camera.position',[0,0,0])));

		// --
		// add camera ortho
		var cameraOrtho = new MinSG.CameraNodeOrtho;
		cameraOrtho.name := "OrthoCamera";
		cameraOrtho.setViewport( new Geometry.Rect(viewport[0],viewport[1],viewport[2],viewport[3]));
		cameraOrtho.setNearFar(systemConfig.getValue('PADrend.Camera.near',0.1),systemConfig.getValue('PADrend.Camera.far',5000));
		dolly.addChild(cameraOrtho);
		// when the application window is resized:
		Util.requirePlugin('PADrend/SystemUI').onWindowResized += [cameraOrtho] => fn(cameraOrtho, width,height){
			// update viewport only when it has not been fixed in the config
			if(! systemConfig.getValue('PADrend.Camera.viewport',false))
				cameraOrtho.setViewport( new Geometry.Rect( 0,0,width,height));
		};
		
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
			_defaultLight = new MinSG.LightNode;
			SceneManagement.initDefaultLightParameters();
			getRootNode() += _defaultLight;
			SceneManagement.lightingState := new MinSG.LightingState;
			lightingState.setLight( _defaultLight );
			getRootNode() += SceneManagement.lightingState;
		}

		getRootNode().addChild(dolly);
		SceneManagement.createNewSceneRoot("new MinSG.ListNode",false);
	}
	initSceneManager( defaultSceneManager );

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
	var scene = eval(t+";");
	if(! scene.isA(MinSG.Node) )
		return false;

	// init meta info
	if(true){
		var NodeMetaInfo = Std.require('LibMinSGExt/NodeMetaInfo');
		var d = getDate();
		NodeMetaInfo.accessMetaInfo_CreationDate(scene)("" + d["year"] + "-"+ d["mon"] + "-" + d["mday"] );
		NodeMetaInfo.accessMetaInfo_Title(scene)("New_" + time().toHex() );
		// ...	
	}
	this.registerScene(scene);
	this.selectScene(scene);
	return scene;
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

SceneManagement.getDefaultLight :=	fn(){	return _defaultLight;	};

//! Returns the unique global root node.
SceneManagement.getRootNode :=		fn(){	return rootNode;	};

SceneManagement.getSceneList :=		fn(){	return registeredScenes;	};

SceneManagement.getDefaultSceneManager :=	fn( ){	return defaultSceneManager;	};

//! get the active scene manager
SceneManagement.getSceneManager :=	fn(){
	//! \see SceneMarkerTrait
	return activeScene&&activeScene.isSet($sceneData)&&activeScene.sceneData.isSet($sceneManager) ? activeScene.sceneData.sceneManager : defaultSceneManager;
};
//! get the scene manager responsible for the given node
SceneManagement.getResponsibleSceneManager := fn( MinSG.Node node){
	var sm;
	for(;node;node=node.getParent()){
		if( Std.Traits.queryTrait(node,SceneMarkerTrait) && node.sceneData.isSet($sceneManager) && node.sceneData.sceneManager ){
			if(sm)
				Runtime.warn("SceneManagement.getResponsibleSceneManager: node has no unique resposnible scene manager!");
			sm = node.sceneData.sceneManager; //! \see SceneMarkerTrait
		}
	}
	return sm ? sm : defaultSceneManager;
	
};

	
SceneManagement.getNamedMapOfAvaiableSceneManagers := fn(){
	var m = new Map;
	var i = 0;
	foreach(registeredScenes as var scene){
		var sceneManager = SceneManagement.getResponsibleSceneManager(scene);
		if(!m[sceneManager]){
			if(sceneManager == SceneManagement.getDefaultSceneManager())
				m[sceneManager] = "default";
			else
				m[sceneManager] = "#"+ (++i);
		}
	}
	return m;
};

SceneManagement.createNewSceneManager := fn(){
	var sceneManager = new SceneManager;
	initSceneManager( sceneManager );
	return sceneManager;
};

//! if @p sceneManager is true, a new one is created; if it is void, the default sceneManager is used.
SceneManagement.loadScene := fn(filename,
								Number importOptions = MinSG.SceneManagement.IMPORT_OPTION_USE_TEXTURE_REGISTRY | MinSG.SceneManagement.IMPORT_OPTION_USE_MESH_REGISTRY, 
								[SceneManager,true,void] sceneManager = void){
	showWaitingScreen();
	
	if(!sceneManager)
		sceneManager = SceneManagement.getDefaultSceneManager();
	else if(true===sceneManager)
		sceneManager = SceneManagement.createNewSceneManager();
	var sceneRoot = sceneManager.loadScene(filename,importOptions);
	if(sceneRoot){
		Std.Traits.assureTrait(sceneRoot,SceneMarkerTrait);
		sceneRoot.sceneData.sceneManager := sceneManager; //! \see SceneMarkerTrait
		this.registerScene(sceneRoot);
	}
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
	Std.Traits.assureTrait(scene,SceneMarkerTrait);
	
	if(!registeredScenes.contains(scene)) 
		registeredScenes.pushBack(scene);
	
	// store sceneManager in sceneData
	if(!scene.sceneData.isSet($sceneManager)||!scene.sceneData.sceneManager)
		scene.sceneData.sceneManager := defaultSceneManager;

	if(!getCurrentScene())
		selectScene(scene);

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

/*! Select scene given by @p filename or by node. 
	If necessary, the file is loaded or registered.
	If a scene with the same filename has been registered, it is not loaded again.
	Additional parameters are passed to loadScene(...) if called.	*/
SceneManagement.assureScene := fn( [MinSG.Node,String] mixed,p...){
	if(mixed.isA(MinSG.Node)){
		var scene = mixed;
		if(scene != activeScene ){
			if(!registeredScenes.contains(scene))
				SceneManagement.registerScene(scene);
			SceneManagement.selectScene(scene);
		}
		return scene;
	}else{
		var filename = mixed;
		foreach( registeredScenes as var scene ){
			if(scene.isSet($filename) && scene.filename == filename){
				SceneManagement.selectScene( scene );
				return scene;
			}
		}
		var scene = SceneManagement.loadScene(filename,p...);
		if(!scene)
			Runtime.exception("Could not load scene '"+filename+"'");
		SceneManagement.selectScene( scene );
		return scene;
	}
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
PADrend.getResponsibleSceneManager := SceneManagement->SceneManagement.getResponsibleSceneManager;
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

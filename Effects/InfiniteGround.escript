/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2010 Robert Gmyr
 * Copyright (C) 2011-2012 Sascha Brandt
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/**
 * [Plugin:Effects] Effects/InfiniteGround.escript
 * Infinite ground plane.
 * Depends on DynamicSky.escript and it's resources.
 */


declareNamespace($Effects);

//!	Effects.InfiniteGround ---|> Plugin
Effects.InfiniteGround := new Plugin({
			Plugin.NAME : "Effects_InfiniteGround",
			Plugin.VERSION : "1.0",
			Plugin.DESCRIPTION : "Display of a infinite ground plane.",
			Plugin.AUTHORS : "Sascha Brandt, Benjamin Eikel, Robert Gmyr, Claudius Jaehn",
			Plugin.OWNER : "All",
			Plugin.REQUIRES : []
});

var plugin = Effects.InfiniteGround;

plugin.autoGroundLevel @(const) := DataWrapper.createFromConfig(systemConfig,'Effects.InfiniteGround.autoGroundLevel',true);
plugin.enabled @(const) := DataWrapper.createFromConfig(systemConfig,'Effects.InfiniteGround.enabled',false);
plugin.groundLevel @(const) := DataWrapper.createFromConfig(systemConfig,'Effects.InfiniteGround.groundLevel',0);
plugin.hazeEnabled @(const) := DataWrapper.createFromConfig(systemConfig,'Effects.InfiniteGround.useHaze',true);
plugin.hazeFar @(const) := DataWrapper.createFromConfig(systemConfig,'Effects.InfiniteGround.hazeFar',250);
plugin.hazeNear @(const) := DataWrapper.createFromConfig(systemConfig,'Effects.InfiniteGround.hazeNear',100);
plugin.scale @(const) := DataWrapper.createFromConfig(systemConfig,'Effects.InfiniteGround.scale',1);
plugin.type @(const) := DataWrapper.createFromConfig(systemConfig,'Effects.InfiniteGround.type',0);
plugin.waterRefraction @(const) := DataWrapper.createFromConfig(systemConfig,'Effects.InfiniteGround.waterRefraction',0.1);
plugin.waterReflection @(const) := DataWrapper.createFromConfig(systemConfig,'Effects.InfiniteGround.waterReflection',0.5);

plugin.groundNode @(private) := void;
plugin.groundShaderState @(private) := void;
	
plugin.init @(override) := fn(){
	registerExtension('PADrend_Init',this->this.registerGUI);

	static revoce = new Std.MultiProcedure;
	// enabled
	this.enabled.onDataChanged += this->fn( b ){
		revoce();
		if(b){
			if(groundNode){
				this.groundNode.activate();
			}else{
				this.createGround();
			}
			revoce += Util.registerExtensionRevocably('PADrend_AfterRendering',this->this.ext_PADrend_AfterRendering,Extension.LOW_PRIORITY*2); // should be executed after the camera is set
			revoce += Util.registerExtensionRevocably('PADrend_BeforeRenderingPass',this->this.ext_PADrend_BeforeRenderingPass);

		}else{
			if(groundNode)
				groundNode.deactivate();
		}
	};
	registerExtension('PADrend_Init',this.enabled->this.enabled.forceRefresh);

	// type
	this.type.onDataChanged += this->fn(t){
		if(this.groundShaderState){
			if(t == 0) { // grass
				groundShaderState.setUniform('texture_1', Rendering.Uniform.INT, [1]);
				groundShaderState.setUniform('type', Rendering.Uniform.INT, [0]);
			}else if(t == 1) { // concrete
				groundShaderState.setUniform('texture_1', Rendering.Uniform.INT, [2]);
				groundShaderState.setUniform('type', Rendering.Uniform.INT, [1]);
			}else if(t == 2) { // check board
				groundShaderState.setUniform('type', Rendering.Uniform.INT, [2]);
			}else if(t == 3) { // water
				groundShaderState.setUniform('texture_1', Rendering.Uniform.INT, [3]);
				groundShaderState.setUniform('texture_2', Rendering.Uniform.INT, [4]);
				groundShaderState.setUniform('type', Rendering.Uniform.INT, [3]);
			}else if(t == 4) { // white
				groundShaderState.setUniform('type', Rendering.Uniform.INT, [4]);
			}else if(t == 5) { // grid
				groundShaderState.setUniform('type', Rendering.Uniform.INT, [5]);
			}
		}
	};
	
	// haze (near should be smaller or equal to far)
	this.hazeFar.onDataChanged += [this.hazeNear] => fn(hazeNear, value){
		if(value<hazeNear())
			hazeNear(value);
	};
	this.hazeNear.onDataChanged += [this.hazeFar] => fn(hazeFar, value){
		if(value>hazeFar())
			hazeFar(value);
	};
	

	// register sync vars
	PADrend.syncVars.addDataWrapper('Effects.InfiniteGround.autoGroundLevel',this.autoGroundLevel);
	PADrend.syncVars.addDataWrapper('Effects.InfiniteGround.enabled',this.enabled);
	PADrend.syncVars.addDataWrapper('Effects.InfiniteGround.hazeEnabled',this.hazeEnabled);
	PADrend.syncVars.addDataWrapper('Effects.InfiniteGround.hazeFar',this.hazeFar);
	PADrend.syncVars.addDataWrapper('Effects.InfiniteGround.hazeNear',this.hazeNear);
	PADrend.syncVars.addDataWrapper('Effects.InfiniteGround.scale',this.scale);
	PADrend.syncVars.addDataWrapper('Effects.InfiniteGround.type',this.type);
	PADrend.syncVars.addDataWrapper('Effects.InfiniteGround.groundLevel',this.groundLevel);
	PADrend.syncVars.addDataWrapper('Effects.InfiniteGround.waterRefraction',this.waterRefraction);
	PADrend.syncVars.addDataWrapper('Effects.InfiniteGround.waterReflection',this.waterReflection);

	return true;
};

plugin.createGround @(private) := fn(){
	// create ground dome
	var dome=new MinSG.GeometryNode;
	dome.setMesh(Rendering.MeshBuilder.createDome(100,40,40,1));
	this.groundNode = new MinSG.EnvironmentState;

	groundNode.setEnvironment(dome);
	dome.moveRel(0,0,0);
	dome.rotateRel_deg(180, new Geometry.Vec3(1, 0, 0));
	PADrend.getRootNode().addState(groundNode);
	
	// create fbo for render water reflections
	this.fbo := new Rendering.FBO;
	renderingContext.pushAndSetFBO(this.fbo);
	this.mirrorTexture := Rendering.createStdTexture(512, 512, false);
	this.fbo.attachColorTexture(renderingContext,mirrorTexture);
	this.depthTexture:=Rendering.createDepthTexture(512, 512);
	this.fbo.attachDepthTexture(renderingContext,depthTexture);
	renderingContext.popFBO();
	
	var resourcesFolder = __DIR__+"/resources";
	
	// load textures
	var noise = new MinSG.TextureState(Rendering.createTextureFromFile(resourcesFolder+"/DynamicSky/dynamic_sky1.bmp"));
	noise.setTextureUnit(0);
	dome.addState(noise);
	var meadow1 = new MinSG.TextureState(Rendering.createTextureFromFile(resourcesFolder+"/InfiniteGround/meadow1.bmp"));
	meadow1.getTexture().createMipmaps(renderingContext);
	meadow1.setTextureUnit(1);
	dome.addState(meadow1);
	var meadow2 = new MinSG.TextureState(Rendering.createTextureFromFile(resourcesFolder+"/InfiniteGround/concrete2.bmp"));
	meadow2.getTexture().createMipmaps(renderingContext);
	meadow2.setTextureUnit(2);
	dome.addState(meadow2);    
	var water_normal = new MinSG.TextureState(Rendering.createTextureFromFile(resourcesFolder+"/InfiniteGround/water_normal.jpg"));
	water_normal.setTextureUnit(3);
	dome.addState(water_normal);
	var mirror_tex = new MinSG.TextureState(mirrorTexture);
	mirror_tex.setTextureUnit(4);
	dome.addState(mirror_tex);

	// load Shader
	this.groundShaderState=new MinSG.ShaderState(Rendering.Shader.loadShader(resourcesFolder+"/InfiniteGround/infiniteGround.vs",
																	   resourcesFolder+"/InfiniteGround/infiniteGround.fs"));
	dome.addState(groundShaderState);
	groundShaderState.setUniform('noise', Rendering.Uniform.INT, [0]);


	this.type.forceRefresh();
};

//!	[ext:PADrend_BeforeRenderingPass]
plugin.ext_PADrend_BeforeRenderingPass @(private) := fn(renderingPass){
	var pos = renderingPass.getCamera().getWorldPosition();
	var worldUp = PADrend.getWorldUpVector();
	var worldRot = new Geometry.Matrix3x3;
	worldRot.set(-1,0,0,0,1,0,0,0,1);

	if(worldUp.getX() ~= 1){
		var tmp = pos.getX();
		pos.setX(-pos.getY());
		pos.setY(tmp);
		worldRot.set(0,-1,0,1,0,0,0,0,1);
	}
	else if(worldUp.getZ() ~= 1){
		var tmp = -pos.getY();
		pos.setY(pos.getZ());
		pos.setZ(tmp);
		worldRot.set(-1,0,0,0,0,-1,0,1,0);
	}
	else if(!(worldUp.getY() ~= 1)){
		outln("Infinite Ground: unsupported world Up Vector");
	}
	groundShaderState.setUniform('viewerPos',Rendering.Uniform.VEC3F,[ [-pos.getX(), pos.getY(), pos.getZ()] ]);
	groundShaderState.setUniform('worldRot',Rendering.Uniform.MATRIX_3X3F,[ worldRot ]);
};

//!	[ext:PADrend_AfterRenderingPass]
plugin.ext_PADrend_AfterRendering @(private) := fn(...){
 
	var sun = PADrend.getDefaultLight();
	
	groundShaderState.setUniform('scale', Rendering.Uniform.FLOAT, [this.scale()]);
	if(this.autoGroundLevel() && PADrend.getCurrentScene())
		groundShaderState.setUniform('groundLevel',Rendering.Uniform.FLOAT,[PADrend.getCurrentSceneGroundPlane( this.groundLevel() ).getOffset() ]);
	else
		groundShaderState.setUniform('groundLevel',Rendering.Uniform.FLOAT,[this.groundLevel()]);

	groundShaderState.setUniform('useHaze', Rendering.Uniform.BOOL, [this.hazeEnabled()]);
	groundShaderState.setUniform('hazeNear', Rendering.Uniform.FLOAT, [this.hazeNear()]);
	groundShaderState.setUniform('hazeFar', Rendering.Uniform.FLOAT, [this.hazeFar()]);
	
	{	// haze
		var skyPlugin = Util.queryPlugin('Effects_DynamicSky');
		var hC = (skyPlugin && skyPlugin.isEnabled() && skyPlugin.getHazeColor()) ? skyPlugin.getHazeColor() :  PADrend.getBGColor();
		groundShaderState.setUniform('hazeColor',  Rendering.Uniform.VEC3F,[ [hC.r(),hC.g(),hC.b()] ]);
	}

	var p=sun.getWorldPosition();
	var up = PADrend.getWorldUpVector();
	if(up.getX() ~= 1){
		//out("Dynamic Sky: x-up ", sunPos);
		var tmp = p.getX();
		p.setX(p.getY());
		p.setY(tmp);
		//outln(" --> ", sunPos);
	}
	else if(up.getZ() ~= 1){
		//out("Dynamic Sky: z-up ", sunPos);
		var tmp = -p.getY();
		p.setY(p.getZ());
		p.setZ(tmp);
		//outln(" --> ", sunPos);
	}
	groundShaderState.setUniform('sunPosition',Rendering.Uniform.VEC3F,[ p]);
	var c = sun.getAmbientLightColor();
	groundShaderState.setUniform('sunAmbient',Rendering.Uniform.VEC3F,[ [c.r(),c.g(),c.b()] ]);
	c = sun.getDiffuseLightColor();
	groundShaderState.setUniform('sunDiffuse',Rendering.Uniform.VEC3F,[ [c.r(),c.g(),c.b()] ]);
	groundShaderState.setUniform('time',Rendering.Uniform.FLOAT,[ PADrend.getSyncClock() ]);
	groundShaderState.setUniform('refraction',Rendering.Uniform.FLOAT,[ this.waterRefraction() ]);
	groundShaderState.setUniform('reflection',Rendering.Uniform.FLOAT,[ this.waterReflection() ]);
	
	if(type()==3 && this.waterReflection() > 0.0) {
		var level = this.autoGroundLevel() ? PADrend.getCurrentScene().getWorldBB().getMinY() : this.groundLevel();	//! \todo use getCurrentSceneGroundPlane
		if(pos.getY()<=level)
			return;
		
		renderingContext.pushAndSetFBO(fbo);  
				
		var mirror_cam = camera.clone();
		
		// setup mirror cam
		var mirrorPos = camera.getWorldPosition();
		var wUp = new Geometry.Vec3(worldUp.getX(),worldUp.getY(),worldUp.getZ());
				
		if(worldUp.getX() ~= 1){
			mirrorPos.setX(2 * level - mirrorPos.getX());
		} else if(worldUp.getZ() ~= 1){
			mirrorPos.setZ(2 * level - mirrorPos.getZ());
		} else {
			mirrorPos.setY(2 * level - mirrorPos.getY());
		}
		
		var dir = PADrend.getDolly().localDirToWorldDir(new Geometry.Vec3(0,0,1));
		dir = dir.reflect( wUp );
		
		var up = PADrend.getDolly().localDirToWorldDir(new Geometry.Vec3(0,1,0));
		up = -up.reflect( wUp );
		
		mirror_cam.setSRT(new Geometry.SRT(mirrorPos, dir, up));
		mirror_cam.setViewport(new Geometry.Rect(0,0,512,512));
	
		
		// render reflection
		PADrend.renderScene(PADrend.getRootNode(),mirror_cam,PADrend.getRenderingFlags(),PADrend.getBGColor(), PADrend.getRenderingLayers());
		
		frameContext.setCamera(camera);
		 
		renderingContext.popFBO();
	}
};

plugin.registerGUI @(private) := fn(){
	gui.registerComponentProvider('Effects_MainMenu.20_infiniteGround',[
		"*Infinite Ground*",
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Enabled",
			GUI.DATA_WRAPPER : this.enabled
		},
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Options",
			GUI.MENU : 'Effects_InfiniteGroundOptions',
			GUI.MENU_WIDTH : 200
		}
	]);


	gui.registerComponentProvider('Effects_InfiniteGroundOptions.00Main',[
		{
			GUI.LABEL : "Type",
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [0,5],
			GUI.RANGE_STEPS : 5,
			GUI.DATA_WRAPPER : this.type
		},
		{
			GUI.LABEL : "Scale",
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [0.1,10],
			GUI.DATA_WRAPPER : this.scale
		},
		{
			GUI.LABEL : "Ground level",
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [-10,+10],
			GUI.DATA_WRAPPER : this.groundLevel
		},
		{
			GUI.LABEL : "Auto ground level",
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.DATA_WRAPPER : this.autoGroundLevel,
		},
		{
			GUI.LABEL : "Use haze",
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.DATA_WRAPPER : this.hazeEnabled
		},
		{
			GUI.LABEL				:	"Haze near",
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.RANGE				:	[0, 1000],
			GUI.DATA_WRAPPER		:	this.hazeNear,
		},
		{
			GUI.LABEL				:	"Haze far",
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.RANGE				:	[10, 1010],
			GUI.DATA_WRAPPER		:	this.hazeFar
		},
		{
			GUI.TYPE				:	GUI.TYPE_MENU,
			GUI.LABEL				:	"Set haze from scene",
			GUI.TOOLTIP				:	"Set 'Haze near' and 'Haze far' to the scaled extent of the scene.",
			GUI.MENU				:	[
											{
												GUI.LABEL				:	"Scale",
												GUI.TYPE				:	GUI.TYPE_RANGE,
												GUI.RANGE				:	[0.5, 10.0],
												GUI.RANGE_STEPS			:	19,
												GUI.DATA_VALUE			:	1,
												GUI.ON_DATA_CHANGED		:	this->fn(scale) {
																				var bb = PADrend.getCurrentScene().getWorldBB();
																				this.hazeNear(scale * bb.getExtentMax());
																				this.hazeFar(this.hazeNear() * 3);
																			}
											}
										],
			GUI.MENU_WIDTH			:	300
		},
		{
			GUI.LABEL : "reflection factor",
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [0,1],
			GUI.DATA_WRAPPER : this.waterReflection
		},
		{
			GUI.LABEL : "refraction factor",
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [0,1],
			GUI.DATA_WRAPPER : this.waterRefraction
		}
	]);

};

// --------------------------------
// interface

plugin.disable := fn(){		this.enabled(false);	};
plugin.enable := fn(){		this.enabled(true);	};
	
plugin.setType := fn(typeIndex){	this.type(0+typeIndex);	};

// -----------------------------------------------------------------------------------------
return plugin;

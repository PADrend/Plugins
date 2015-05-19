/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2015 Claudius Jähn <claudius@uni-paderborn.de>
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



//!	Effects.InfiniteGround ---|> Plugin
static plugin = new Plugin({
			Plugin.NAME : "Effects_InfiniteGround",
			Plugin.VERSION : "1.1",
			Plugin.DESCRIPTION : "Display of a infinite ground plane.",
			Plugin.AUTHORS : "Sascha Brandt, Benjamin Eikel, Robert Gmyr, Claudius Jaehn",
			Plugin.OWNER : "All",
			Plugin.REQUIRES : []
});

static config = new (module('LibUtilExt/ConfigGroup'))(systemConfig,'Effects.InfiniteGround');
	
plugin.autoGroundLevel @(const) := Std.DataWrapper.createFromEntry(config,'autoGroundLevel',true);
plugin.enabled @(const) := Std.DataWrapper.createFromEntry(config,'enabled',false);
plugin.groundLevel @(const) := Std.DataWrapper.createFromEntry(config,'groundLevel',0);
plugin.hazeEnabled @(const) := Std.DataWrapper.createFromEntry(config,'useHaze',true);
plugin.hazeFar @(const) := Std.DataWrapper.createFromEntry(config,'hazeFar',250);
plugin.hazeNear @(const) := Std.DataWrapper.createFromEntry(config,'hazeNear',100);
plugin.scale @(const) := Std.DataWrapper.createFromEntry(config,'scale',1);
plugin.type @(const) := Std.DataWrapper.createFromEntry(config,'type',0);
plugin.waterRefraction @(const) := Std.DataWrapper.createFromEntry(config,'waterRefraction',0.1);
plugin.waterReflection @(const) := Std.DataWrapper.createFromEntry(config,'waterReflection',0.5);

static resourcesFolder = __DIR__+"/resources";

plugin.getHazeColor := fn(){
	var skyPlugin = Util.queryPlugin('Effects_DynamicSky');
	return (skyPlugin && skyPlugin.isEnabled() && skyPlugin.getHazeColor()) ? skyPlugin.getHazeColor() :  PADrend.getBGColor();
};

plugin.groundColor := new Std.DataWrapper(new Util.Color4f(1,1,1,1));
	
plugin.init @(override) := fn(){
	module.on('PADrend/gui',registerGUI);

	{	// enabled
		static revoce = new Std.MultiProcedure;
		this.enabled.onDataChanged += fn( b ){
			revoce();
			if(b){
				revoce += Std.addRevocably(PADrend.getRootNode(), getEnvState());
				revoce += Util.registerExtensionRevocably('PADrend_AfterRendering', ext_PADrend_AfterRendering,Extension.LOW_PRIORITY*2); // should be executed after the camera is set
				plugin.type.forceRefresh();
			}
		};
		registerExtension('PADrend_Init',this.enabled->this.enabled.forceRefresh);
		
	}
	
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

static TYPE_GRASS = 0;
static TYPE_CONCRETE = 1;
static TYPE_CHECKBOARD = 2;
static TYPE_WATER = 3;
static TYPE_WHITE = 4;
static TYPE_GRID = 5;

static getShaderState = fn(){
	static shaderState;
	if(!shaderState){
		// load Shader
		shaderState = new MinSG.ShaderState(Rendering.Shader.loadShader(resourcesFolder+"/InfiniteGround/infiniteGround.vs",
																		   resourcesFolder+"/InfiniteGround/infiniteGround.fs"));
		shaderState.setUniform('noise', Rendering.Uniform.INT, [0]);
		
		// listen on type changes
		plugin.type.onDataChanged += fn(t){
			shaderState.setUniform('type', Rendering.Uniform.INT, [t]);
			switch(t){
			case TYPE_GRASS: { 
				shaderState.setUniform('texture_1', Rendering.Uniform.INT, [1]);
				break;
			}
			case TYPE_CONCRETE: { 
				shaderState.setUniform('texture_1', Rendering.Uniform.INT, [2]);
				break;
			}
			case TYPE_WATER: { 
				shaderState.setUniform('texture_1', Rendering.Uniform.INT, [3]);
				shaderState.setUniform('texture_2', Rendering.Uniform.INT, [4]);
				break;
			}
			}
		};
	}
	return shaderState;
};
static getDomeNode = fn(){
	static dome;
	if(!dome){
		dome = new MinSG.GeometryNode;
		dome.setMesh(Rendering.MeshBuilder.createDome(100,40,40,1));

		var updatePositionState = new MinSG.ScriptedState;
		updatePositionState.doEnableState @(override) := fn(node, rp) {
			
			var pos = frameContext.getCamera().getWorldOrigin();
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
			var shaderState = getShaderState();
			shaderState.setUniform('viewerPos',Rendering.Uniform.VEC3F,[ [-pos.getX(), pos.getY(), pos.getZ()] ]);
			shaderState.setUniform('worldRot',Rendering.Uniform.MATRIX_3X3F,[ worldRot ]);
		};
		dome += updatePositionState;

		// load textures
		var noise = new MinSG.TextureState(Rendering.createTextureFromFile(resourcesFolder+"/DynamicSky/dynamic_sky1.bmp"));
		noise.setTextureUnit(0);
		dome += noise;
		var meadow1 = new MinSG.TextureState(Rendering.createTextureFromFile(resourcesFolder+"/InfiniteGround/meadow1.bmp"));
		meadow1.getTexture().createMipmaps(renderingContext);
		meadow1.setTextureUnit(1);
		dome += meadow1;
		var meadow2 = new MinSG.TextureState(Rendering.createTextureFromFile(resourcesFolder+"/InfiniteGround/concrete2.bmp"));
		meadow2.getTexture().createMipmaps(renderingContext);
		meadow2.setTextureUnit(2);
		dome += meadow2;

		dome += getShaderState();
		
	}
	return dome;
};
static getEnvState = fn(){
	static envState;
	if(!envState){
		// create ground dome
		var dome = getDomeNode();
		envState = new MinSG.EnvironmentState;

		envState.setEnvironment(dome);
		dome.moveRel(0,0,0);
		dome.rotateRel_deg(180, new Geometry.Vec3(1, 0, 0));
	}
	return envState;
};

//!	[ext:PADrend_AfterRenderingPass]
static ext_PADrend_AfterRendering = fn(...){
 
	var sun = PADrend.getDefaultLight();
	
	var shaderState = getShaderState();
	shaderState.setUniform('scale', Rendering.Uniform.FLOAT, [plugin.scale()]);
	if(plugin.autoGroundLevel() && PADrend.getCurrentScene())
		shaderState.setUniform('groundLevel',Rendering.Uniform.FLOAT,[PADrend.getCurrentSceneGroundPlane( plugin.groundLevel() ).getOffset() ]);
	else
		shaderState.setUniform('groundLevel',Rendering.Uniform.FLOAT,[plugin.groundLevel()]);

	{	// haze
		shaderState.setUniform('useHaze', Rendering.Uniform.BOOL, [plugin.hazeEnabled()]);
		shaderState.setUniform('hazeNear', Rendering.Uniform.FLOAT, [plugin.hazeNear()]);
		shaderState.setUniform('hazeFar', Rendering.Uniform.FLOAT, [plugin.hazeFar()]);

		var hC = plugin.getHazeColor();
		shaderState.setUniform('hazeColor',  Rendering.Uniform.VEC3F,[ [hC.r(),hC.g(),hC.b()] ]);
		
		var gc = plugin.groundColor();
		shaderState.setUniform('groundColor',  Rendering.Uniform.VEC3F,[ [gc.r(),gc.g(),gc.b()] ]);
	}

	var p = sun.getWorldOrigin();
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
	shaderState.setUniform('sunPosition',Rendering.Uniform.VEC3F,[ p]);
	var c = sun.getAmbientLightColor();
	shaderState.setUniform('sunAmbient',Rendering.Uniform.VEC3F,[ [c.r(),c.g(),c.b()] ]);
	c = sun.getDiffuseLightColor();
	shaderState.setUniform('sunDiffuse',Rendering.Uniform.VEC3F,[ [c.r(),c.g(),c.b()] ]);
	shaderState.setUniform('time',Rendering.Uniform.FLOAT,[ PADrend.getSyncClock() ]);
	
	if(plugin.type()==TYPE_WATER && plugin.waterReflection() > 0.0) {
		shaderState.setUniform('refraction',Rendering.Uniform.FLOAT,[ plugin.waterRefraction() ]);
		shaderState.setUniform('reflection',Rendering.Uniform.FLOAT,[ plugin.waterReflection() ]);
		
		static fbo;
		@(once){
			fbo = new Rendering.FBO;
			renderingContext.pushAndSetFBO(fbo);
			var mirrorTexture = Rendering.createStdTexture(512, 512, false);
			fbo.attachColorTexture(renderingContext,mirrorTexture);
			fbo.attachDepthTexture(renderingContext,Rendering.createDepthTexture(512, 512));
			renderingContext.popFBO();

			var water_normal = new MinSG.TextureState(Rendering.createTextureFromFile(resourcesFolder+"/InfiniteGround/water_normal.jpg"));
			water_normal.setTextureUnit(3);
			getDomeNode() += water_normal;
			var mirror_tex = new MinSG.TextureState(mirrorTexture);
			mirror_tex.setTextureUnit(4);
			getDomeNode() += mirror_tex;

		}
		renderingContext.pushAndSetFBO(fbo);  

		var mirror_cam = camera.clone();
		
		// setup mirror cam
		var worldUp = PADrend.getWorldUpVector();

		var mirrorPos = camera.getWorldOrigin();
		var wUp = new Geometry.Vec3(worldUp.getX(),worldUp.getY(),worldUp.getZ());
				
		var level = plugin.autoGroundLevel() ? PADrend.getCurrentScene().getWorldBB().getMinY() : plugin.groundLevel();	//! \todo use getCurrentSceneGroundPlane
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
		
		mirror_cam.setRelTransformation(new Geometry.SRT(mirrorPos, dir, up));
		mirror_cam.setViewport(new Geometry.Rect(0,0,512,512));
	
		
		// render reflection
		PADrend.renderScene(PADrend.getRootNode(),mirror_cam,PADrend.getRenderingFlags(),PADrend.getBGColor(), PADrend.getRenderingLayers());
		
		frameContext.setCamera(camera);
		 
		renderingContext.popFBO();
	}
};

static registerGUI = fn(gui){
	gui.register('Effects_MainMenu.20_infiniteGround',[
		"*Infinite Ground*",
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Enabled",
			GUI.DATA_WRAPPER : plugin.enabled
		},
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Options",
			GUI.MENU : 'Effects_InfiniteGroundOptions',
			GUI.MENU_WIDTH : 200
		}
	]);


	gui.register('Effects_InfiniteGroundOptions.00Main',[
		{
			GUI.LABEL : "Type",
			GUI.TYPE : GUI.TYPE_SELECT,
			GUI.OPTIONS : [
				[TYPE_GRASS, "Grass"],
				[TYPE_CONCRETE,"Concrete"],
				[TYPE_CHECKBOARD,"Checkboard"],
				[TYPE_WATER,"Water"],
				[TYPE_WHITE,"Single Color"],
				[TYPE_GRID,"Grid"]
			],
			GUI.DATA_WRAPPER : plugin.type
		},
		{
			GUI.LABEL : "Scale",
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [0.1,10],
			GUI.DATA_WRAPPER : plugin.scale
		},
		{
			GUI.LABEL : "Ground level",
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [-10,+10],
			GUI.DATA_WRAPPER : plugin.groundLevel
		},
		{
			GUI.LABEL : "Auto ground level",
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.DATA_WRAPPER : plugin.autoGroundLevel,
		},
		{
			GUI.LABEL : "Use haze",
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.DATA_WRAPPER : plugin.hazeEnabled
		},
		{
			GUI.LABEL				:	"Haze near",
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.RANGE				:	[-1, 5],
			GUI.RANGE_FN_BASE		:	10,
			GUI.RANGE_STEP_SIZE		:	0.1,
			GUI.DATA_WRAPPER		:	plugin.hazeNear,
		},
		{
			GUI.LABEL				:	"Haze far",
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.RANGE				:	[-1, 5],
			GUI.RANGE_FN_BASE		:	10,
			GUI.RANGE_STEP_SIZE		:	0.1,
			GUI.DATA_WRAPPER		:	plugin.hazeFar
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
												GUI.ON_DATA_CHANGED		:	fn(scale) {
																				var bb = PADrend.getCurrentScene().getWorldBB();
																				plugin.hazeNear(scale * bb.getExtentMax());
																				plugin.hazeFar(plugin.hazeNear() * 3);
																			}
											}
										],
			GUI.MENU_WIDTH			:	300
		},
		{
			GUI.LABEL : "reflection factor",
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [0,1],
			GUI.DATA_WRAPPER : plugin.waterReflection
		},
		{
			GUI.LABEL : "refraction factor",
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [0,1],
			GUI.DATA_WRAPPER : plugin.waterRefraction
		},
		{
			GUI.TYPE : GUI.TYPE_COLOR,
			GUI.LABEL : "Ground Color",
			GUI.DATA_WRAPPER : plugin.groundColor,
			GUI.TOOLTIP : "Adjust the ground color (for type WHITE(4)).",
			GUI.WIDTH  : 200
		},
		'----',
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Set as default",
			GUI.ON_CLICK : fn(){	config.save(); PADrend.message("Settings stored.");	}
		}
	]);

};

// --------------------------------
// interface
declareNamespace($Effects);
Effects.InfiniteGround := plugin;

plugin.disable := fn(){		this.enabled(false);	};
plugin.enable := fn(){		this.enabled(true);	};
	
plugin.setType := fn(typeIndex){	this.type(0+typeIndex);	};

// -----------------------------------------------------------------------------------------
return plugin;

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2009-2011 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2010 Robert Gmyr
 * Copyright (C) 2011-2012 Sascha Brandt
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Spielerei/DynamicSky.escript
 ** 2009-11 Claudius Urlaubsprojekt...
 ** \see http://www.eisscholle.de/articles.html
 ** \see http://www.cs.utah.edu/~shirley/papers/sunsky/sunsky.pdf
 ** \see http://www.cs.utah.edu/~shirley/papers/sunsky/code/
 ** \see http://www.bonzaisoftware.com/volsmoke.html
 ** \see http://nifelheim.dyndns.org/~cocidius/normalmap/ (normal map plugin for gimp)
 **/

declareNamespace($Effects);
Effects.DynamicSky := new Plugin({
			Plugin.NAME : "Effects_DynamicSky",
			Plugin.VERSION : "1.3",
			Plugin.DESCRIPTION : "Display a procedural sky.",
			Plugin.AUTHORS : "Claudius Jaehn",
			Plugin.OWNER : "Claudius Jaehn",
			Plugin.REQUIRES : []
});

var plugin = Effects.DynamicSky;

static skyShaderState;
static COLORS = {//  skyColor_1(horizon) skyColor_2          skyColor_3          cloudColor         light
	0.0     : [ 0.03, 0.03, 0.05,   0.05, 0.05, 0.05,   0.02, 0.02, 0.02,   0.05, 0.05, 0.05,   0.00 ,0.00, 0.05],
	0.7     : [ 0.04, 0.04, 0.07,   0.04, 0.04, 0.05,   0.01, 0.01, 0.01,   0.05, 0.05, 0.05,   0.00 ,0.00, 0.05],
	0.8     : [ 0.05, 0.05, 0.10,   0.03, 0.03, 0.05,   0.00, 0.00, 0.00,   0.10, 0.00, 0.00,   0.10 ,0.10, 0.45],
	1.0     : [ 0.45, 0.28, 0.11,   0.41, 0.46, 0.49,   0.12, 0.14, 0.17,   0.71, 0.56, 0.46,   0.70 ,0.40, 0.40], //cimg0571
	1.1     : [ 0.91, 0.68, 0.32,   0.66, 0.66, 0.66,   0.36, 0.38, 0.41,   0.75, 0.65, 0.55,   0.80 ,0.70, 0.70], //cimg0566
	1.3     : [ 0.92, 0.84, 0.84,   0.82, 0.86, 0.91,   0.71, 0.77, 0.86,   0.75, 0.65, 0.55,   0.80 ,0.80, 0.80], //cimg0565
	1.5     : [ 0.85, 0.90, 0.90,   0.89, 1.00, 1.00,   0.00, 0.40, 0.70,   1.00, 1.00, 1.00,   0.80 ,0.80, 0.80],
	2.0     : [ 0.92, 0.99, 1.00,   0.55, 0.74, 0.95,   0.35, 0.50, 0.73,   1.00, 1.00, 1.00,   0.90 ,0.90, 0.90]
};
static activeTimeFactor = 0; 
static cloudActiveSpeed = 0;
static hazeColor;		// variable for haze of InfiniteGround	
static timeZone = 0;
static longitude = 10;
static latitude = 20;

// parameters (data wrappers)
static pEnabled;
static pJulianDay;
static pUseActualDay;
static pStarsEnabled;
static pInfluenceSunLight;
static pSkyClockOffset;
static pUseActualTime;
static pTimeFactor;
static pCloudDensity;
static pCloudClockOffset;
static pCloudSpeed;
static pMaxSunBrightness;

static config;

static getCloudTime = fn(){
	var seconds = cloudActiveSpeed == 0 ? 
					pCloudClockOffset() : 
					(PADrend.getSyncClock() - pCloudClockOffset())*cloudActiveSpeed;
	return (seconds/3600);
};
static setCloudTime	= fn(Number hours){
	var seconds = (hours%5) * 3600; // use modulo to prevent numeric instabilities; results in a short jump in the clouds.
	pCloudClockOffset( cloudActiveSpeed == 0 ?
							seconds : 
							(PADrend.getSyncClock() - seconds/cloudActiveSpeed)  );
};
static getTimeOfDay = fn(){
	var seconds = activeTimeFactor == 0 ? 
					pSkyClockOffset() : 
					(PADrend.getSyncClock() - pSkyClockOffset())*activeTimeFactor;
	return (seconds/3600)%24;
};
static setTimeOfDay = fn(Number hours){
	hours %= 24.0;
	if(hours<0)
		hours += 24;
	var seconds = hours * 3600;
	pSkyClockOffset( activeTimeFactor == 0 ?
							seconds : 
							(PADrend.getSyncClock() - seconds/activeTimeFactor)  );
};
static activeTask;
static changeTimeOfDay = fn(Number hours, Number duration=0.3){
	if(duration<=0){
		setTimeOfDay(hours);
		activeTask = void;
		return;
	}
	if(!activeTask){
		PADrend.planTask(0.05, fn(){
			while(activeTask){
				var x = (PADrend.getSyncClock()-activeTask.startClock) / activeTask.duration;
				if(x>=1)
					break;
				x = x*x*(3-2*x); // smoothstep
				setTimeOfDay( x*activeTask.targetTimeOfDay + (1-x)*activeTask.startTimeOfDay);
				yield 0.05;
			}
			setTimeOfDay(activeTask.targetTimeOfDay);
			activeTask = void;
		});
	}	
	var target = hours;
	var now = getTimeOfDay();
	var d = (target-now).abs();
	if( (target+24-now).abs() < d ){
		target = hours+24;
	}else if( (target-24-now).abs() < d ){
		target = hours-24;
	}
	activeTask = new ExtObject({
		$startTimeOfDay : now,
		$targetTimeOfDay : target,
		$startClock : PADrend.getSyncClock(),
		$duration : duration
	});
};
plugin.init @(override) := fn(){
	config = new (module('LibUtilExt/ConfigGroup'))(systemConfig,'Effects.DynSky');
	pTimeFactor = Std.DataWrapper.createFromEntry(config,'timeFactor',0.0);

	// time
	pSkyClockOffset = new Std.DataWrapper(0);
	// if 'useActualTime' is true, the current system time is taken as initial time. Otherwise, 'time' is taken.
	pUseActualTime = Std.DataWrapper.createFromEntry(config,'useActualTime',false);
	pUseActualTime.onDataChanged += fn(Bool b){
		if(b)
			setTimeOfDay( (getDate()["hours"]+getDate()["minutes"]/60) );
	};
	pUseActualTime.forceRefresh();
	if(!pUseActualTime())
		setTimeOfDay(  config.get('time',13.0) );

	pTimeFactor = Std.DataWrapper.createFromEntry(config,'timeFactor',0.0);
	pTimeFactor.onDataChanged += fn(Number v){
		var t = getTimeOfDay();
		activeTimeFactor = v;
		setTimeOfDay(t);
	};
	pTimeFactor.forceRefresh();

	// date
	pJulianDay = Std.DataWrapper.createFromEntry(config,'julianDay',180);
	pUseActualDay = Std.DataWrapper.createFromEntry(config,'useActualDay',false);
	pUseActualDay.onDataChanged += fn(Bool b){
		if(b)
			pJulianDay(getDate()["yday"]);
	};
	pUseActualDay.forceRefresh();

	// clouds
	pCloudClockOffset = new Std.DataWrapper(0);
	pCloudSpeed = Std.DataWrapper.createFromEntry(config,'cloudSpeed',0.004);
	pCloudSpeed.onDataChanged += fn(Number v){
		var t = getCloudTime();
		cloudActiveSpeed = v;
		setCloudTime(t);
	};
	pCloudSpeed.forceRefresh();
	pCloudDensity = Std.DataWrapper.createFromEntry(config,'cloudDensity',0.6);
	pMaxSunBrightness = Std.DataWrapper.createFromEntry(config,'maxSunBrightness',100);
	
	// misc
	pInfluenceSunLight = Std.DataWrapper.createFromEntry(config,'influenceSunLight',false);
	pStarsEnabled = Std.DataWrapper.createFromEntry(config,'starsEnabled',false);
	
	{	//enabled
		static envState;
		static revoce = new Std.MultiProcedure;
		pEnabled = Std.DataWrapper.createFromEntry(config,'enabled',false);
		pEnabled.onDataChanged += fn(Bool b){  
			revoce(); 	
			if(b){
				if( !envState )
					envState = createEnvState();
				revoce += Std.addRevocably(PADrend.getRootNode(), envState);
				revoce += Util.registerExtensionRevocably('PADrend_AfterFrame', updateSkyValues);
			}
		};
		registerExtension('PADrend_Init',pEnabled->pEnabled.forceRefresh);
	}

	PADrend.syncVars.addDataWrapper('Effects.DynSky.skyClockOffset', pSkyClockOffset);
	PADrend.syncVars.addDataWrapper('Effects.DynSky.timeFactor', pTimeFactor);
	PADrend.syncVars.addDataWrapper('Effects.DynSky.julianDay', pJulianDay);
	PADrend.syncVars.addDataWrapper('Effects.DynSky.cloudClockOffset', pCloudClockOffset);
	PADrend.syncVars.addDataWrapper('Effects.DynSky.cloudSpeed', pCloudSpeed);
	PADrend.syncVars.addDataWrapper('Effects.DynSky.cloudDensity', pCloudDensity);
	PADrend.syncVars.addDataWrapper('Effects.DynSky.influenceSunLight', pInfluenceSunLight);
	PADrend.syncVars.addDataWrapper('Effects.DynSky.enabled', pEnabled);
	PADrend.syncVars.addDataWrapper('Effects.DynSky.starsEnabled', pStarsEnabled);
	PADrend.syncVars.addDataWrapper('Effects.DynSky.maxSunBrightness', pMaxSunBrightness);
	
	module.on('PADrend/gui', initGUI);
	return true;
};


static createEnvState = fn(){
	var envState = new MinSG.EnvironmentState;

	// create sky dome
	var dome = new MinSG.GeometryNode;
	dome.setMesh(Rendering.MeshBuilder.createDome(100,40,40,1));
	
	var s = new MinSG.ScriptedState;
	s.doEnableState @(override) := fn(node, rp) {
		renderingContext.pushAndSetDepthBuffer(false, false, Rendering.Comparison.ALWAYS); // disable depth tests and writes
	};
	s.doDisableState @(override) := fn(node, rp) {
		renderingContext.popDepthBuffer();
	};
	dome += s;
	envState.setEnvironment(dome);
	dome.moveRel(0,-0.2,0); // move a little bit downward to reduce the possibly visible seam on the border to the floot

	var resourcesFolder = __DIR__+"/resources/DynamicSky";

	// load textures
	var tn1 = new MinSG.TextureState(Rendering.createTextureFromFile(resourcesFolder+"/dynamic_sky1.bmp"));
	tn1.setTextureUnit(0);
	dome += tn1;
	var tn2 = new MinSG.TextureState(Rendering.createTextureFromFile(resourcesFolder+"/dynamic_sky_normal.bmp"));
	tn2.setTextureUnit(1);
	dome += tn2;

	// load Shader
	skyShaderState = new MinSG.ShaderState(Rendering.Shader.loadShader(resourcesFolder+"/dynamicSky.vs",
																	resourcesFolder+"/dynamicSky.fs"));
	dome += skyShaderState;
	skyShaderState.setUniform(new Rendering.Uniform('ColorMap',Rendering.Uniform.INT,[0]));
	skyShaderState.setUniform(new Rendering.Uniform('BumpMap',Rendering.Uniform.INT,[1]));

	return envState;
};

static updateSkyValues = fn(...){
	var sun = PADrend.getDefaultLight();
	var sunHeight; //< y pos of the sun
	{         // calculate sun position
		var sunPos = MinSG.calculateSunPosition( getTimeOfDay(), pJulianDay(),timeZone,longitude,latitude);

		sunHeight = sunPos.getY()+1.0; // 0<sunHeight<2
		
		if(PADrend.isCurrentCoordinateSystem_ZUp()){
			//out("Dynamic Sky: z-up ", sunPos);
			var tmp = sunPos.getY();
			sunPos.setY(-sunPos.getZ());
			sunPos.setZ(tmp);
			//outln(" --> ", sunPos);
		}
		else if(!PADrend.isCurrentCoordinateSystem_YUp()){
			outln("Dynamic Sky: unsupported world Up Vector");
			pEnabled(false);
		}
		
		sun.setRelPosition(new Geometry.Vec3(0,0,0));
		sun.rotateToWorldDir(sunPos);
		sun.setRelPosition(sunPos*5000);
		
		skyShaderState.setUniform(new Rendering.Uniform('sunPosition',Rendering.Uniform.VEC3F,[ sunPos ]));
	}

	var c; //< final sky colors
	{   // interpolate sky colors
		var skyColors_1 = false;
		var skyY_1 =  false;
		var skyColors_2 = false;
		var skyY_2 = false;
		foreach( COLORS as var y,var cArray){
			if(!skyColors_2){
				skyColors_1 = skyColors_2=cArray;
				skyY_1 = skyY_2 = y;
				continue;
			}
			skyColors_1 = skyColors_2;
			skyY_1 = skyY_2;
			skyColors_2 = cArray;
			skyY_2 = y;
			if(new Number(y) >= sunHeight)
				break;
	//            out(y,"  ");

		}
	//        out("\r",sunHeight,"   ",skyY_1," ",skyY_2,"   ");
		var mix = (sunHeight-skyY_1) / (skyY_2-skyY_1+0.0001);
		c = skyColors_1.map( [skyColors_2,mix]->fn(key,value){
			var skyColors_2=this[0];
			var mix=this[1];
			return (1.0-mix)*value + mix*skyColors_2[key];
		});
	}

	// set sky colors
	var skyColor1 = new Util.Color4f(c[0], c[1], c[2], 1.0);
	skyShaderState.setUniform(new Rendering.Uniform('skyColor_1', Rendering.Uniform.VEC4F,[ skyColor1] ));
	skyShaderState.setUniform(new Rendering.Uniform('skyColor_2', Rendering.Uniform.VEC4F,[ new Util.Color4f(c[ 3], c[ 4], c[ 5], 1.0)] ));
	skyShaderState.setUniform(new Rendering.Uniform('skyColor_3', Rendering.Uniform.VEC4F,[ new Util.Color4f(c[ 6], c[ 7], c[ 8], 1.0)] ));
	skyShaderState.setUniform(new Rendering.Uniform('cloudColor', Rendering.Uniform.VEC4F,[ new Util.Color4f(c[ 9], c[10], c[11], 1.0)] ));

	// set cloud parameter
	skyShaderState.setUniform(new Rendering.Uniform('cloudTime',Rendering.Uniform.FLOAT,[ getCloudTime()*3600]));
	skyShaderState.setUniform(new Rendering.Uniform('cloudDensity',Rendering.Uniform.FLOAT,[ pCloudDensity()]));
	
	// sun parameters
	skyShaderState.setUniform(new Rendering.Uniform('maxSunBrightness',Rendering.Uniform.FLOAT,[ pMaxSunBrightness()]));
	
	// stars
	skyShaderState.setUniform(new Rendering.Uniform('starsEnabled',Rendering.Uniform.BOOL,[ pStarsEnabled()]));

	if( pInfluenceSunLight() ){
		sun.setAmbientLightColor(new Util.Color4f([c[12]*0.3,c[13]*0.3,c[14]*0.3]));
		sun.setDiffuseLightColor(new Util.Color4f([c[12]*0.7,c[13]*0.7,c[14]*0.7]));
		sun.setSpecularLightColor(new Util.Color4f([c[12]*1.0,c[13]*1.0,c[14]*1.0]));
	}

	// set hazeColor for InfiniteGround
	hazeColor = skyColor1;
};


static initGUI = fn(gui){
	gui.register('Effects_MainMenu.10_dynamicSky', fn(){
		return [
			"*Dynamic Sky*",
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Enabled",
				GUI.DATA_WRAPPER : pEnabled
			},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0,24],
				GUI.RANGE_STEPS : 24,
				GUI.ON_DATA_CHANGED : changeTimeOfDay,
				GUI.WIDTH : 100,
				GUI.TOOLTIP : "Time of day",
				GUI.ON_INIT : fn(...){
					Util.registerExtension('PADrend_AfterFrame',[this] => fn(timeSlider){
						if(timeSlider.isDestroyed())
							return Extension.REMOVE_EXTENSION;
						timeSlider.setData( getTimeOfDay() );
					});

				}
			},
			{
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "Options",
				GUI.MENU_WIDTH : 200,
				GUI.MENU : 'Effects_DynamicSkyOptions'
			}
		];
	});
		
		
	gui.register('Effects_DynamicSkyOptions',fn(){
		return [
			"*Sky options*",
				
			// --------
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.LABEL : "Time factor",
				GUI.DATA_WRAPPER : pTimeFactor,
				GUI.RANGE : [0,4],
				GUI.RANGE_STEPS : 100,
				GUI.RANGE_FN : fn(v){ return (10).pow(v)-1; },
				GUI.RANGE_INV_FN : fn(v){ return v>-1 ? (v+1).log(10) : 0; },
			},
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Use actual time",
				GUI.DATA_WRAPPER : pUseActualTime
			},
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Use actual day",
				GUI.DATA_WRAPPER : pUseActualDay
			},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "Day of year",
				GUI.DATA_WRAPPER : pJulianDay
			},
			'----',
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.LABEL : "Cloud speed",
				GUI.DATA_WRAPPER : pCloudSpeed,
				GUI.RANGE : [0.0,0.1],
				GUI.RANGE_STEPS : 200
			},			
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.LABEL : "Cloud density",
				GUI.DATA_WRAPPER : pCloudDensity,
				GUI.RANGE : [0.0,1.0],
				GUI.RANGE_STEPS : 200
			},		
			'----',
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Stars (experimental)",
				GUI.DATA_WRAPPER : pStarsEnabled
			},				
			'----',
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Influence sun light",
				GUI.DATA_WRAPPER : pInfluenceSunLight
			},			
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "maxSunBrightness(hdr)",
				GUI.DATA_WRAPPER : pMaxSunBrightness,
				GUI.OPTIONS : [ 1,10,100,1000,10000 ]
			},			
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Restore default light",
				GUI.ON_CLICK : fn(){
					PADrend.executeCommand( fn(){ PADrend.SceneManagement.initDefaultLightParameters(); } );
				},
				GUI.TOOLTIP : "Set the default light's parameter to the ones \nset in the config."
			},
			'----',
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Set as default",
				GUI.ON_CLICK : fn(){	config.save(); PADrend.message("Settings stored.");	}
			}
		];
	});
	
	if(Util.queryPlugin('Tools/GamePadConfig')){
		Tools.GamePadConfig.addOption("Time of day",fn(){ return "< "+ getTimeOfDay().round(0.1)+" >"; },fn(value){
			if( (value & Util.UI.MASK_HAT_LEFT) > 0){
				changeTimeOfDay( getTimeOfDay()-0.25 );
			}else if( (value & Util.UI.MASK_HAT_RIGHT) > 0){
				changeTimeOfDay( getTimeOfDay()+0.25 );
			}
		});
	}
};
// -----------------------------------------------------------------
// public interface

plugin.changeTimeOfDay		:=	changeTimeOfDay;
plugin.getHazeColor 		:= 	fn(){				return hazeColor;	};
plugin.getTimeOfDay 		:=	getTimeOfDay;
plugin.isEnabled 			:= 	fn(){				return pEnabled();	};
plugin.setCloudDensity		:=	fn(Number v){		pCloudDensity(v);	};
plugin.setCloudSpeed		:=	fn(Number v){		pCloudSpeed(v);	};

plugin.setEnabled 			:=	fn(Bool b){			pEnabled(b);	};
plugin.setInfluenceSunLight	:=	fn(Bool b){			pInfluenceSunLight(b);	};
plugin.setJulianDay			:=	fn(Number v){		pJulianDay(v);	};
plugin.setTimeFactor 		:=	fn(Number factor){	pTimeFactor(factor);	};
plugin.setTimeOfDay 		:=	setTimeOfDay;

// -----------------------------------------------------------------------------------------
return plugin;

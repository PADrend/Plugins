/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
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

//!	DynamicSky ---|> Plugin
Effects.DynamicSky := new Plugin({
			Plugin.NAME : "Effects_DynamicSky",
			Plugin.VERSION : "1.2",
			Plugin.DESCRIPTION : "Display of a procedural sky.",
			Plugin.AUTHORS : "Claudius Jaehn",
			Plugin.OWNER : "Claudius Jaehn",
			Plugin.REQUIRES : []
});

var plugin = Effects.DynamicSky;

//!	---|> Plugin
plugin.init @(override) := fn(){
    { // Register ExtensionPointHandler:
        registerExtension('PADrend_Init',this->this.ex_Init);
    }
    
    // time
	this.activeTimeFactor @(private) := 0; // (internal)
	this.skyClockOffset @(private) := DataWrapper.createFromValue(0);
	// if 'useActualTime' is true, the current system time is taken as initial time. Otherwise, 'time' is taken.
	this.useActualTime @(private) := DataWrapper.createFromConfig(systemConfig,'Effects.DynSky.useActualTime',false);
	this.useActualTime.onDataChanged += this->fn(Bool b){
		if(b)
			this.setTimeOfDay( (getDate()["hours"]+getDate()["minutes"]/60) );
	};
	this.useActualTime.forceRefresh();
	if(!useActualTime())
		this.setTimeOfDay(  systemConfig.getValue('Effects.DynSky.time',13.0) );

    this.timeFactor @(private) := DataWrapper.createFromConfig(systemConfig,'Effects.DynSky.timeFactor',0.0);
    this.timeFactor.onDataChanged += this->fn(Number v){
		var t = this.getTimeOfDay();
		this.activeTimeFactor = v;
		this.setTimeOfDay(t);
    };
	this.timeFactor.forceRefresh();

    // date
	this.julianDay := DataWrapper.createFromConfig(systemConfig,'Effects.DynSky.julianDay',180);
    this.useActualDay := DataWrapper.createFromConfig(systemConfig,'Effects.DynSky.useActualDay',false);
    this.useActualDay.onDataChanged += this->fn(Bool b){
		if(b)
			this.julianDay(getDate()["yday"]);
    };
    this.useActualDay.forceRefresh();
    this.timeZone:=0;
    this.longitude:=10;
    this.latitude:=20;

    
    // clouds
    this.cloudActiveSpeed @(private) := 0; // (internal)
    this.cloudClockOffset := DataWrapper.createFromValue(0);
    this.cloudSpeed := DataWrapper.createFromConfig(systemConfig,'Effects.DynSky.cloudSpeed',0.004);
    this.cloudSpeed.onDataChanged += this->fn(Number v){
		var t = this.getCloudTime();
		this.cloudActiveSpeed = v;
		this.setCloudTime(t);
    };
	this.cloudSpeed.forceRefresh();

    this.cloudDensity := DataWrapper.createFromConfig(systemConfig,'Effects.DynSky.cloudDensity',0.6);

    
    // misc
    this.influenceSunLight := DataWrapper.createFromConfig(systemConfig,'Effects.DynSky.influenceSunLight',false);
    this.skyNode := void;
    this.skyShaderState := void;
    this.colors := void;
    this.starsEnabled := DataWrapper.createFromConfig(systemConfig,'Effects.DynSky.starsEnabled',false);;
	// variable for haze of InfiniteGround	
    this.hazeColor := void;

    this.enabled := DataWrapper.createFromConfig(systemConfig,'Effects.DynSky.enabled',false);
    this.enabled.onDataChanged += this->fn(Bool b){    	
		if(b){
			if(this.skyNode){
				this.skyNode.activate();
			}else{
				this.createSky();
			}
		}else{
			if(this.skyNode)
				this.skyNode.deactivate();
		}
	};
	
	registerExtension('PADrend_Init',enabled->enabled.forceRefresh);

    PADrend.syncVars.addDataWrapper('Effects.DynSky.skyClockOffset',this.skyClockOffset);
    PADrend.syncVars.addDataWrapper('Effects.DynSky.timeFactor',this.timeFactor);
    PADrend.syncVars.addDataWrapper('Effects.DynSky.julianDay',this.julianDay);
    PADrend.syncVars.addDataWrapper('Effects.DynSky.cloudClockOffset',this.cloudClockOffset);
    PADrend.syncVars.addDataWrapper('Effects.DynSky.cloudSpeed',this.cloudSpeed);
    PADrend.syncVars.addDataWrapper('Effects.DynSky.cloudDensity',this.cloudDensity);
    PADrend.syncVars.addDataWrapper('Effects.DynSky.influenceSunLight',this.influenceSunLight);
    PADrend.syncVars.addDataWrapper('Effects.DynSky.enabled',this.enabled);
    PADrend.syncVars.addDataWrapper('Effects.DynSky.starsEnabled',this.starsEnabled);
    
    return true;
};

plugin.createSky @(private) := fn(){
    // create sky dome
    var dome=new MinSG.GeometryNode;
    dome.setMesh(Rendering.MeshBuilder.createDome(100,40,40,1));
    this.skyNode = new MinSG.EnvironmentState;

    skyNode.setEnvironment(dome);
    dome.moveRel(0,-0.2,0); // move a little bit downward to reduce the possibly visible seam on the border to the floot
    PADrend.getRootNode().addState(skyNode);

	var resourcesFolder = __DIR__+"/resources/DynamicSky";

    // load textures
    var tn1 = new MinSG.TextureState(Rendering.createTextureFromFile(resourcesFolder+"/dynamic_sky1.bmp"));
    tn1.setTextureUnit(0);
    dome.addState(tn1);
    var tn2 = new MinSG.TextureState(Rendering.createTextureFromFile(resourcesFolder+"/dynamic_sky_normal.bmp"));
    tn2.setTextureUnit(1);
    dome.addState(tn2);

    // load Shader
    this.skyShaderState=new MinSG.ShaderState(Rendering.Shader.loadShader(resourcesFolder+"/dynamicSky.vs",
                                                                    resourcesFolder+"/dynamicSky.fs"));
    dome.addState(skyShaderState);
    skyShaderState.setUniform(new Rendering.Uniform('ColorMap',Rendering.Uniform.INT,[0]));
    skyShaderState.setUniform(new Rendering.Uniform('BumpMap',Rendering.Uniform.INT,[1]));

    // init colors
    this.colors={//  skyColor_1(horizon) skyColor_2          skyColor_3          cloudColor         light
        0.0     : [ 0.03, 0.03, 0.05,   0.05, 0.05, 0.05,   0.02, 0.02, 0.02,   0.05, 0.05, 0.05,   0.00 ,0.00, 0.05],
        0.7     : [ 0.04, 0.04, 0.07,   0.04, 0.04, 0.05,   0.01, 0.01, 0.01,   0.05, 0.05, 0.05,   0.00 ,0.00, 0.05],
        0.8     : [ 0.05, 0.05, 0.10,   0.03, 0.03, 0.05,   0.00, 0.00, 0.00,   0.10, 0.00, 0.00,   0.10 ,0.10, 0.45],
        1.0     : [ 0.45, 0.28, 0.11,   0.41, 0.46, 0.49,   0.12, 0.14, 0.17,   0.71, 0.56, 0.46,   0.70 ,0.40, 0.40], //cimg0571
        1.1     : [ 0.91, 0.68, 0.32,   0.66, 0.66, 0.66,   0.36, 0.38, 0.41,   0.75, 0.65, 0.55,   0.80 ,0.70, 0.70], //cimg0566
        1.3     : [ 0.92, 0.84, 0.84,   0.82, 0.86, 0.91,   0.71, 0.77, 0.86,   0.75, 0.65, 0.55,   0.80 ,0.80, 0.80], //cimg0565
        1.5     : [ 0.85, 0.90, 0.90,   0.89, 1.00, 1.00,   0.00, 0.40, 0.70,   1.00, 1.00, 1.00,   0.80 ,0.80, 0.80],
        2.0     : [ 0.92, 0.99, 1.00,   0.55, 0.74, 0.95,   0.35, 0.50, 0.73,   1.00, 1.00, 1.00,   0.90 ,0.90, 0.90]
    };

    { // Register ExtensionPointHandler:
        registerExtension('PADrend_AfterFrame',this->this.ex_AfterFrame);
    }
    ex_AfterFrame(); // init other values...
};

//!	[ext:PADrend_AfterFrame]
plugin.ex_AfterFrame @(private) :=fn(...){
    if(!this.enabled())
        return;

	var sun = PADrend.getDefaultLight();
	var sunHeight; //< y pos of the sun
    {         // calculate sun position
        var sunPos=MinSG.calculateSunPosition(this.getTimeOfDay(),julianDay(),timeZone,longitude,latitude);

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
	    	this.enabled(false);
	    }
	    
        sun.setRelPosition(new Geometry.Vec3(0,0,0));
        sun.rotateToWorldDir(sunPos);
        sun.setRelPosition(sunPos*5000);
        
        skyShaderState.setUniform(new Rendering.Uniform('sunPosition',Rendering.Uniform.VEC3F,[ sunPos ]));
    }

    var c; //< final sky colors
    {   // interpolate sky colors
        var skyColors_1=false;
        var skyY_1=false;
        var skyColors_2=false;
        var skyY_2=false;
        foreach(this.colors as var y,var cArray){
            if(!skyColors_2){
                skyColors_1=skyColors_2=cArray;
                skyY_1=skyY_2=y;
                continue;
            }
            skyColors_1=skyColors_2;
            skyY_1=skyY_2;
            skyColors_2=cArray;
            skyY_2=y;
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
    skyShaderState.setUniform(new Rendering.Uniform('cloudTime',Rendering.Uniform.FLOAT,[this.getCloudTime()*3600]));
    skyShaderState.setUniform(new Rendering.Uniform('cloudDensity',Rendering.Uniform.FLOAT,[cloudDensity()]));
    
    // stars
    skyShaderState.setUniform(new Rendering.Uniform('starsEnabled',Rendering.Uniform.BOOL,[starsEnabled()]));

    if(influenceSunLight()){
        sun.setAmbientLightColor(new Util.Color4f([c[12]*0.3,c[13]*0.3,c[14]*0.3]));
        sun.setDiffuseLightColor(new Util.Color4f([c[12]*0.7,c[13]*0.7,c[14]*0.7]));
        sun.setSpecularLightColor(new Util.Color4f([c[12]*1.0,c[13]*1.0,c[14]*1.0]));
    }

    // set hazeColor for InfiniteGround
    this.hazeColor = skyColor1;
};


//!	[ext:PADrend_Init]
plugin.ex_Init @(private) :=fn(){
	gui.registerComponentProvider('Effects_MainMenu.10_dynamicSky',this->fn(){

		var menu=[];
	  
		menu+="*Dynamic Sky*";
		menu+={
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Enabled",
			GUI.DATA_WRAPPER : this.enabled
		};

		var timeSlider=gui.create({
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [0,24],
			GUI.RANGE_STEPS : 24,
			GUI.ON_DATA_CHANGED : this->this.changeTimeOfDay,
			GUI.WIDTH : 100,
			GUI.TOOLTIP : "Time of day"
		});
		menu+=timeSlider;
		registerExtension('PADrend_AfterFrame',[timeSlider] => this->fn(timeSlider){
			if(timeSlider.isDestroyed()){
				return Extension.REMOVE_EXTENSION;
			}
			timeSlider.setData(this.getTimeOfDay());
		});
		menu += {
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Options",
			GUI.MENU_WIDTH : 200,
			GUI.MENU : 'Effects_DynamicSkyOptions'
		};
		return menu;
	});
		
		
	gui.registerComponentProvider('Effects_DynamicSkyOptions',this->fn(){
		var menu = [];
		menu += "*Sky options*";
			
		// --------
		menu += {
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Time factor",
			GUI.DATA_WRAPPER : this.timeFactor,
			GUI.RANGE : [0,4],
			GUI.RANGE_STEPS : 100,
			GUI.RANGE_FN : fn(v){ return (10).pow(v)-1; },
			GUI.RANGE_INV_FN : fn(v){ return v>-1 ? (v+1).log(10) : 0; },
		};
		menu += {
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Use actual time",
			GUI.DATA_WRAPPER : this.useActualTime
		};
		menu += {
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Use actual day",
			GUI.DATA_WRAPPER : this.useActualDay
		};
		menu += {
			GUI.TYPE : GUI.TYPE_NUMBER,
			GUI.LABEL : "Day of year",
			GUI.DATA_WRAPPER : this.julianDay
		};
		
		menu += '----';
		
		menu += {
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Cloud speed",
			GUI.DATA_WRAPPER : this.cloudSpeed,
			GUI.RANGE : [0.0,0.1],
			GUI.RANGE_STEPS : 200
		};			
		menu += {
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Cloud density",
			GUI.DATA_WRAPPER : this.cloudDensity,
			GUI.RANGE : [0.0,1.0],
			GUI.RANGE_STEPS : 200
		};
		
		menu += '----';
		menu += {
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Stars (experimental)",
			GUI.DATA_WRAPPER : this.starsEnabled
		};				
		menu += '----';
		menu += {
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Influence sun light",
			GUI.DATA_WRAPPER : this.influenceSunLight
		};			
		menu += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Restore default light",
			GUI.ON_CLICK : fn(){
				PADrend.executeCommand( fn(){ PADrend.SceneManagement.initDefaultLightParameters(); } );
			},
			GUI.TOOLTIP : "Set the default light's parameter to the ones \nset in the config."
		};
		
		return menu;
	});
	
	if(queryPlugin('Tools/GamePadConfig')){
		Tools.GamePadConfig.addOption("Time of day",this->fn(){ return "< "+ this.getTimeOfDay().round(0.1)+" >"; },this->fn(value){
			if( (value & Util.UI.MASK_HAT_LEFT) > 0){
				this.changeTimeOfDay( this.getTimeOfDay()-0.25 );
			}else if( (value & Util.UI.MASK_HAT_RIGHT) > 0){
				this.changeTimeOfDay( this.getTimeOfDay()+0.25 );
			}
		});
	}
};
// -----------------------------------------------------------------
// public interface


plugin.changeTimeOfDay := fn(Number hours, Number duration=0.3){
	if(duration<=0){
		this.setTimeOfDay(hours);
		thisFn.task := void;
		return;
	}
	var target = hours;
	var now = this.getTimeOfDay();
	var d = (target-now).abs();
	if( (target+24-now).abs() < d ){
		target = hours+24;
	}else if( (target-24-now).abs() < d ){
		target = hours-24;
	}
	
	var task = new ExtObject({
		$startTimeOfDay : now,
		$targetTimeOfDay : target,
		$startClock : PADrend.getSyncClock(),
		$duration : duration
	});
	if(thisFn.isSet($task)&&thisFn.task){
		thisFn.task = task;
	}else{
		thisFn.task := task;
		PADrend.planTask(0.05,[thisFn] => this->fn(closure){
			var task;
			while(true){
				task = closure.task;
				if(!task)
					return;
				var x = (PADrend.getSyncClock()-task.startClock) / task.duration;
				if(x>=1)
					break;
				x = x*x*(3-2*x); // smoothstep
				this.setTimeOfDay( x*task.targetTimeOfDay + (1-x)*task.startTimeOfDay);
				yield 0.05;
			}
			this.setTimeOfDay(task.targetTimeOfDay);
			closure.task := void;
		});
	
	}
};

plugin.getCloudTime 		:= fn(){
	var seconds = this.cloudActiveSpeed == 0 ? 
					this.cloudClockOffset() : 
					(PADrend.getSyncClock() - this.cloudClockOffset())*this.cloudActiveSpeed;
	return (seconds/3600);
};
plugin.getHazeColor 		:= 	fn(){				return this.hazeColor;	};
plugin.getTimeOfDay 		:=	fn(){
	var seconds = this.activeTimeFactor == 0 ? 
					this.skyClockOffset() : 
					(PADrend.getSyncClock() - this.skyClockOffset())*this.activeTimeFactor;
	return (seconds/3600)%24;
};
plugin.isEnabled 			:= 	fn(){				return this.enabled();	};
plugin.setCloudDensity		:=	fn(Number v){		this.cloudDensity(v);	};
plugin.setCloudSpeed		:=	fn(Number v){		this.cloudSpeed(v);	};
plugin.setCloudTime			:=	fn(Number hours){
	var seconds = (hours%5) * 3600; // use modulo to prevent numeric instabilities; results in a short jump in the clouds.
	this.cloudClockOffset( this.cloudActiveSpeed == 0 ?
							seconds : 
							(PADrend.getSyncClock() - seconds/this.cloudActiveSpeed)  );
};
plugin.setEnabled 			:=	fn(Bool b){			this.enabled(b);	};
plugin.setInfluenceSunLight	:=	fn(Bool b){			this.influenceSunLight(b);	};
plugin.setJulianDay			:=	fn(Number v){		this.julianDay(v);	};
plugin.setTimeFactor 		:=	fn(Number factor){	this.timeFactor(factor);	};
plugin.setTimeOfDay 		:=	fn(Number hours){
	hours %= 24.0;
	if(hours<0)
		hours += 24;
	var seconds = hours * 3600;
	this.skyClockOffset( this.activeTimeFactor == 0 ?
							seconds : 
							(PADrend.getSyncClock() - seconds/this.activeTimeFactor)  );
};

// -----------------------------------------------------------------------------------------
return plugin;

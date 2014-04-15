/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tools_Screenshot] Tools/Screenshot.escript
 ** 2008-12
 **/

var plugin=new Plugin({
		Plugin.NAME : 'Tools_Screenshot',
		Plugin.DESCRIPTION : "Take screenshot and save it to path \"{userPath}{screenshotPath}\". (Key [F12])\nTo show options, press [shift]+[F12]." ,
		Plugin.VERSION : 2.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

/**
 * Plugin initialization.
 * ---|> Plugin
 */
plugin.init @(override) := fn() {

	{ // Register ExtensionPointHandler:
        registerExtension('PADrend_KeyPressed',this->this.ex_KeyPressed);
		
		
		registerExtension('PADrend_Init',this->fn(){
			gui.registerComponentProvider('Tools_ToolsMenu.screenshot',{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Screenshot ...",
					GUI.ON_CLICK : this->openConfigWindow
			});
		});
	}
	
	// settings
	this.settings @(const) := new ExtObject({
		$alpha : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.alpha',false ),
		$filename : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.filename',"scr_${counter}_(${date})" ),
		$path : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.path',PADrend.getUserPath()+"screens/" ),
		$shotCounter : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.shotCounter',0 ),
		$showGUI : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.showGUI',false ),
		$hrScale : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.hrScale',9 ),
		$hqSteps : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.hqSteps',11 ),
	});
	return true;
};

/**
 * [ext:PADrend_KeyPressed]
 */
plugin.ex_KeyPressed:=fn(evt) {
	if (!(evt.key == Util.UI.KEY_F12))  // F12
		return false;

	if(PADrend.getEventContext().isShiftPressed()){
		openConfigWindow();
	}else{
		planNormalScreenshot();
	}
	
	return true;
};

plugin.saveTexture @(private) := fn(Rendering.Texture tex, filename){
	var pngFileName = filename + ".png";

	var success = Rendering.saveTexture(renderingContext,tex, pngFileName);
	if(success) {
		PADrend.message("Screenshot: \""+ pngFileName+ "\": "+ tex+ "\t"+ (success ? "ok." : "\afailed!"));
		return pngFileName;
	} else {
		var bmpFileName = fileName + ".bmp";
		success = Rendering.saveTexture(renderingContext,tex, bmpFileName);
		PADrend.message("Screenshot: \""+ bmpFileName+ "\": "+ tex+ "\t"+ (success ? "ok." : "\afailed!"));
		return bmpFileName;
	}
};

plugin.generateFilename @(private) := fn(){
	var date = Util.createTimeStamp();
	return settings.path() + "/" + settings.filename().replaceAll({
							'${date}':date, 
							'${time}':time().toIntStr() , 
							'${counter}' : this.getUniqueShotId().format(0,false,3) });
};

// --------------------------------------------------------------

plugin.openConfigWindow := fn(){
	
	var w = gui.createPopupWindow(320,300,"Screenshot");
	w.addOption("*Common settings*");
	w.addOption({
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Use alpha channel",
		GUI.DATA_WRAPPER : settings.alpha
	});

	w.addOption({
		GUI.TYPE : GUI.TYPE_FOLDER,
		GUI.LABEL : "Folder",
		GUI.DATA_WRAPPER : settings.path,
		GUI.OPTIONS : [PADrend.getUserPath()+"screens/"]
	});	
	w.addOption({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "File name",
		GUI.DATA_WRAPPER : settings.filename,
		GUI.OPTIONS : ["scr_${counter}_(${date})"],
		GUI.TOOLTIP : "Notes:\n - Do not add an ending!\n - ${time} is replaced by the current unix timestamp.\n - ${counter} : running number\n - ${date} : formatted date and time"
	});
	w.addOption('----');
	w.addOption("*Rendering-loop embedded screenshot*");
	w.addOption({
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Show gui",
		GUI.DATA_WRAPPER : settings.showGUI,
	});	
	w.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL :"single frame (normal [F12] )",
		GUI.ON_CLICK : [w] => this->fn(window){
			window.close();
			planNormalScreenshot();
		}
	});

	w.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL :"high quality multi pass",
		GUI.ON_CLICK : [w] => this->fn(window){
			window.close();
			planHQScreenshot();
		}
	});
	w.addOption({
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL :"high quality steps",
		GUI.DATA_WRAPPER : this.settings.hqSteps,
		GUI.TYPE_RANGE : [2,20],
		GUI.RANGE_STEP_SIZE : 1,
		GUI.TOOLTIP : "An hq-screenshot is composed of steps*steps many images."
	});
	w.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL :"high resolution multi pass",
		GUI.ON_CLICK : [w] => this->fn(window){
			window.close();
			planHRScreenshot();
		}
	});
		
	w.addOption({
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL :"high resolution scaling",
		GUI.DATA_WRAPPER : this.settings.hrScale,
		GUI.TYPE_RANGE : [2,10],
		GUI.RANGE_STEP_SIZE : 1,
		GUI.TOOLTIP : "An hr-screenshot is composed of scale*scale many images."
	});
	w.addOption('----');
	w.addOption("*Custom FBO screenshot*");
	w.addOption("Resolution");
	w.addOption("TODO...");
	
	w.addAction("Close");
	w.init();

};

plugin.planNormalScreenshot := fn(filename=void){
	if(!filename){
		filename = generateFilename();
	}

	if(PADrend.configCache.getValue('Tools.ScreenShot.showGUI')){
		registerExtension('PADrend_AfterFrame',[filename] => this->fn(filename){
			yield; // wait one frame, to allow the window to close.
			saveTexture( Rendering.createTextureFromScreen( settings.alpha() ),filename );
			return Extension.REMOVE_EXTENSION;
		},Extension.HIGH_PRIORITY);
	}else{
		registerExtension('PADrend_AfterRendering',[filename] => this->fn(p,filename){
			saveTexture( Rendering.createTextureFromScreen( settings.alpha() ),filename );
			return Extension.REMOVE_EXTENSION;
		},Extension.LOW_PRIORITY);
	}
};

plugin.planHQScreenshot := fn(filename=void){
	if(!filename){
		filename = generateFilename() +"_hq";
	}

	if(PADrend.configCache.getValue('Tools.ScreenShot.showGUI')){
		registerExtension('PADrend_AfterFrame',[filename] => this->fn(filename){
			yield; // wait one frame, to allow the window to close.
			
			var it = performHq(filename);
			yield;
			while(!it.end()) {
				it.next();
				yield;
			}
			return Extension.REMOVE_EXTENSION;
		},Extension.HIGH_PRIORITY);
	}else{
		registerExtension('PADrend_AfterRendering',[filename] => this->fn(p,filename){
			var it = performHq(filename);
			yield;
			while(!it.end()) {
				it.next();
				yield;
			}
			return Extension.REMOVE_EXTENSION;
		},Extension.LOW_PRIORITY);
	}
};

plugin.planHRScreenshot := fn(filename=void){
	if(!filename){
		filename = generateFilename() +"_hr";
	}
	
	if(PADrend.configCache.getValue('Tools.ScreenShot.showGUI')){
		registerExtension('PADrend_AfterFrame',[filename] => this->fn(filename){
			yield; // wait one frame, to allow the window to close.
			
			var it = performHr(filename);
			yield;
			while(!it.end()) {
				it.next();
				yield;
			}
			return Extension.REMOVE_EXTENSION;
		},Extension.HIGH_PRIORITY);
	}else{
		registerExtension('PADrend_AfterRendering',[filename] => this->fn(p,filename){
			var it = performHr(filename);
			yield;
			while(!it.end()) {
				it.next();
				yield;
			}
			return Extension.REMOVE_EXTENSION;
		},Extension.LOW_PRIORITY);
	}
};


plugin.performHq @(private) := fn(filename){
	// TODO: stop the clock!



	var progressOutput = new Util.ProgressIndicator("Taking shots ", this.settings.hqSteps()*this.settings.hqSteps(), 1);
	
	var cam = PADrend.getActiveCamera();

	var angles = cam.getAngles();
	var viewport = cam.getViewport();

	var leftAngle = angles[0];
	var rightAngle = angles[1];
	var topAngle = angles[2];
	var bottomAngle = angles[3];

	var left = leftAngle.degToRad().tan();
	var right = rightAngle.degToRad().tan();
	var top = topAngle.degToRad().tan();
	var bottom = bottomAngle.degToRad().tan();
	var dx = (right-left)/viewport.width();
	var dy = (bottom-top)/viewport.height();

	var textures = [];

	var inc = 1.0/(this.settings.hqSteps()-1);
	for(var x=-0.5;x<=0.501;x+=inc){
		for(var y=-0.5;y<=0.501;y+=inc){
			progressOutput.increment();
			var left2 = left +dx*x;
			var right2 = right +dx*x;
			var top2 = top +dy*y;
			var bottom2 = bottom +dy*y;

			cam.setAngles([left2.atan().radToDeg(), right2.atan().radToDeg(), top2.atan().radToDeg(), bottom2.atan().radToDeg()]);

			yield; // render next scene

			textures += Rendering.createBitmapFromTexture( renderingContext, Rendering.createTextureFromScreen( settings.alpha()) );
		}
	}

	cam.setAngles(angles);
	outln("\nComposing image...\n");
	showWaitingScreen();
	var tex = Rendering.createTextureFromBitmap(Util.blendTogether( settings.alpha() ? Util.Bitmap.RGBA : Util.Bitmap.RGB,textures)); 
	saveTexture(tex, filename);

	return false;
};


plugin.performHr @(private) := fn(filename){
	// TODO: stop the clock!

	var scale = this.settings.hrScale(); // --> imagesize (2*x * 2*y) --> *4

	var progressOutput = new Util.ProgressIndicator("Taking shots ", scale*scale, 1);
	
	var cam = PADrend.getActiveCamera();
	
	var angles = cam.getAngles();
	var viewport = cam.getViewport();
	
	var leftAngle = angles[0];
	var rightAngle = angles[1];
	var topAngle = angles[2];
	var bottomAngle = angles[3];
	
	var left = leftAngle.degToRad().tan();
	var right = rightAngle.degToRad().tan();
	var top = topAngle.degToRad().tan();
	var bottom = bottomAngle.degToRad().tan();
	var dx = (right-left)/viewport.width();
	var dy = (bottom-top)/viewport.height();

	
	var textures = [];

	var tdx = dx / scale;
	var tdy = dy / scale;
	for(var y = dy/2 - tdy/2; y > -dy/2; y -= tdy){
		for(var x = -dx/2 + tdx/2; x < dx/2; x += tdx){
			progressOutput.increment();
			
			var left2 = left + x;
			var right2 = right + x;
			var top2 = top + y;
			var bottom2 = bottom + y;
			
			cam.setAngles([left2.atan().radToDeg(), right2.atan().radToDeg(), top2.atan().radToDeg(), bottom2.atan().radToDeg()]);
			
			yield; // render next scene
			
			textures += Rendering.createBitmapFromTexture( renderingContext, Rendering.createTextureFromScreen( settings.alpha()) );
		}
	}
	
	cam.setAngles(angles);
	outln("\nComposing image...\n");
	showWaitingScreen();
	var tex = Rendering.createTextureFromBitmap(Util.combineInterleaved( settings.alpha() ? Util.Bitmap.RGBA : Util.Bitmap.RGB,textures));
	saveTexture(tex, filename);
	
	return false;
};

//! Returns a continuous number (stored in the config cache)
plugin.getUniqueShotId @(public) := fn(){
	this.settings.shotCounter( this.settings.shotCounter()+1 );
	return this.settings.shotCounter();
};


plugin.grabAndSaveCurrentScreen @(public) := fn(filenamePrefix){
	return this.saveTexture( Rendering.createTextureFromScreen( settings.alpha() ),filenamePrefix );
};

return plugin;
// ------------------------------------------------------------------------------

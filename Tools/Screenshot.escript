/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2014 Claudius Jähn <claudius@uni-paderborn.de>
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

var plugin = new Plugin({
		Plugin.NAME : 'Tools_Screenshot',
		Plugin.DESCRIPTION : "Take screenshot and save it to path \"{userPath}{screenshotPath}\". (Key [F12])\nTo show options, press [shift]+[F12]." ,
		Plugin.VERSION : 2.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

static settings;

plugin.init @(override) := fn() {
	Util.registerExtension('PADrend_KeyPressed',fn(evt) {
			if(!(evt.key == Util.UI.KEY_F12))  // F12
				return false;

			if(PADrend.getEventContext().isShiftPressed()){
				openConfigWindow();
			}else{
				planNormalScreenshot();
			}
			return true;
		};);
		
		
	Util.registerExtension('PADrend_Init',fn(){
		gui.register('Tools_ToolsMenu.screenshot',{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Screenshot ...",
				GUI.ON_CLICK : openConfigWindow
		});
	});
	
	// settings
	settings = new ExtObject({
		$alpha : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.alpha',false ),
		$filename : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.filename',"scr_${counter}_(${date})" ),
		$path : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.path',PADrend.getUserPath()+"screens/" ),
		$shotCounter : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.shotCounter',0 ),
		$showGUI : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.showGUI',false ),
		$hrScale : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.hrScale',9 ),
		$hqSteps : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.hqSteps',11 ),
		$stopClock : DataWrapper.createFromConfig( PADrend.configCache,'Tools.ScreenShot.stopClock',true ),
	});
	return true;
};

static saveTexture = fn(Rendering.Texture tex, String filename){
	var pngFileName = filename + ".png";

	var success = Rendering.saveTexture(renderingContext,tex, pngFileName);
	if(success) {
		PADrend.message("Screenshot: \""+ pngFileName+ "\": "+ tex+ "\t"+ (success ? "ok." : "\afailed!"));
		return pngFileName;
	} else {
		var bmpFileName = filename + ".bmp";
		success = Rendering.saveTexture(renderingContext,tex, bmpFileName);
		PADrend.message("Screenshot: \""+ bmpFileName+ "\": "+ tex+ "\t"+ (success ? "ok." : "\afailed!"));
		return bmpFileName;
	}
};

//! Returns a continuous number (stored in the config cache)
static getUniqueShotId = fn(){
	settings.shotCounter( settings.shotCounter()+1 );
	return settings.shotCounter();
};

static generateFilename = fn(){
	var date = Util.createTimeStamp();
	return settings.path() + "/" + settings.filename().replaceAll({
							'${date}':date, 
							'${time}':time().toIntStr() , 
							'${counter}' : getUniqueShotId().format(0,false,3) });
};
static prepareFolder = fn(filename){
	var dir = (new Util.FileName(filename)).getDir();
	if(!Util.isDir(dir)){
		outln("Creating folder '"+dir+"'...");
		Util.createDir(dir);
	}
};

static openConfigWindow = fn(){
	var closeDialog = new Std.MultiProcedure;
	var d = gui.createDialog({
		GUI.TYPE : GUI.TYPE_POPUP_DIALOG,
		GUI.LABEL : "Screenshot",
		GUI.SIZE : [350,300],
		GUI.OPTIONS : [
			"*Common settings*",
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Use alpha channel",
				GUI.DATA_WRAPPER : settings.alpha
			},
			{
				GUI.TYPE : GUI.TYPE_FOLDER,
				GUI.LABEL : "Folder",
				GUI.DATA_WRAPPER : settings.path,
				GUI.OPTIONS : [PADrend.getUserPath()+"screens/"]
			},	
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "File name",
				GUI.DATA_WRAPPER : settings.filename,
				GUI.OPTIONS : ["scr_${counter}_(${date})"],
				GUI.TOOLTIP : "Notes:\n - Do not add an ending!\n - ${time} is replaced by the current unix timestamp.\n - ${counter} : running number\n - ${date} : formatted date and time"
			},
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Show gui",
				GUI.DATA_WRAPPER : settings.showGUI,
			},	
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Stop clock",
				GUI.DATA_WRAPPER : settings.stopClock,
				GUI.TOOLTIP : "Stop the PADrend.getSyncClock while executing a multi-frame screenshot."
			},
			'----',
			"*Rendering-loop embedded screenshot*",
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL :"single frame (normal [F12] )",
				GUI.ON_CLICK : [closeDialog] => fn(closeDialog){
					closeDialog();
					planNormalScreenshot();
				}
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL :"high quality multi pass",
				GUI.ON_CLICK : [closeDialog] => fn(closeDialog){
					closeDialog();
					planHQScreenshot();
				}
			},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.LABEL :"high quality steps",
				GUI.DATA_WRAPPER : settings.hqSteps,
				GUI.TYPE_RANGE : [2,20],
				GUI.RANGE_STEP_SIZE : 1,
				GUI.TOOLTIP : "An hq-screenshot is composed of steps*steps many images."
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL :"high resolution multi pass",
				GUI.ON_CLICK : [closeDialog] => fn(closeDialog){
					closeDialog();
					planHRScreenshot();
				}
			},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.LABEL :"high resolution scaling",
				GUI.DATA_WRAPPER : settings.hrScale,
				GUI.TYPE_RANGE : [2,5],
				GUI.RANGE_STEP_SIZE : 1,
				GUI.TOOLTIP : "An hr-screenshot is composed of scale*scale many images."
			}
		],
		GUI.ACTIONS : [
			"close"
		]
	});
	closeDialog += d->d.close;
	d.init();

};

static planNormalScreenshot = fn(filename=void){
	if(!filename)
		filename = generateFilename();
	prepareFolder(filename);

	if(settings.showGUI()){
		Util.registerExtension('PADrend_AfterFrame',[filename] => fn(filename){
			yield; // wait one frame, to allow the window to close.
			saveTexture( Rendering.createTextureFromScreen( settings.alpha() ),filename );
			return Extension.REMOVE_EXTENSION;
		},Extension.HIGH_PRIORITY);
	}else{
		Util.registerExtension('PADrend_AfterRendering',[filename] => fn(filename,...){
			saveTexture( Rendering.createTextureFromScreen( settings.alpha() ),filename );
			return Extension.REMOVE_EXTENSION;
		},Extension.LOW_PRIORITY);
	}
};

static stopClockRevocably = fn(){
	var t = PADrend.getSyncClock();
	var originalClock = PADrend.getSyncClock;
	PADrend.getSyncClock = [t]=>fn(t){return t;};
	return [originalClock]=>fn(originalClock){
		PADrend.getSyncClock = originalClock;
		return $REMOVE;
	};
};

static planHQScreenshot = fn(filename=void){
	if(!filename)
		filename = generateFilename() +"_hq";
	prepareFolder(filename);

	if(settings.showGUI()){
		Util.registerExtension('PADrend_AfterFrame',[filename] => fn(filename){
			var revoce = new Std.MultiProcedure;
			if(settings.stopClock())
				revoce += stopClockRevocably();
			yield; // wait one frame, to allow the window to close.
			
			var it = performHq(filename);
			yield;
			while(!it.end()) {
				it.next();
				yield;
			}
			revoce();
			return Extension.REMOVE_EXTENSION;
		},Extension.HIGH_PRIORITY);
	}else{
		Util.registerExtension('PADrend_AfterRendering',[filename] => fn(filename,...){
			var revoce = new Std.MultiProcedure;
			if(settings.stopClock())
				revoce += stopClockRevocably();
			var it = performHq(filename);
			yield;
			while(!it.end()) {
				it.next();
				yield;
			}
			revoce();
			return Extension.REMOVE_EXTENSION;
		},Extension.LOW_PRIORITY);
	}
};

static planHRScreenshot = fn(filename=void){
	if(!filename)
		filename = generateFilename() +"_hr";
	prepareFolder(filename);
	
	if(settings.showGUI()){
		Util.registerExtension('PADrend_AfterFrame',[filename] => fn(filename){
			var revoce = new Std.MultiProcedure;
			if(settings.stopClock())
				revoce += stopClockRevocably();
			yield; // wait one frame, to allow the window to close.
			
			var it = performHr(filename);
			yield;
			while(!it.end()) {
				it.next();
				yield;
			}
			revoce();
			return Extension.REMOVE_EXTENSION;
		},Extension.HIGH_PRIORITY);
	}else{
		Util.registerExtension('PADrend_AfterRendering',[filename] => fn(filename,...){
			var revoce = new Std.MultiProcedure;
			if(settings.stopClock())
				revoce += stopClockRevocably();
			var it = performHr(filename);
			yield;
			while(!it.end()) {
				it.next();
				yield;
			}
			revoce();
			return Extension.REMOVE_EXTENSION;
		},Extension.LOW_PRIORITY);
	}
};


static performHq = fn(filename){
	// TODO: stop the clock!

	var progressOutput = new Util.ProgressIndicator("Taking shots ", settings.hqSteps()*settings.hqSteps(), 1);
	
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

	var inc = 1.0/(settings.hqSteps()-1);
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


static performHr = fn(filename){
	var scale = settings.hrScale(); // --> imagesize (2*x * 2*y) --> *4

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

// -----------------------------------------------------------------------

//! Returns a continuous number (stored in the config cache)
plugin.getUniqueShotId @(public) := getUniqueShotId;


plugin.grabAndSaveCurrentScreen @(public) := fn(filenamePrefix){
	return saveTexture( Rendering.createTextureFromScreen( settings.alpha() ),filenamePrefix );
};

return plugin;
// ------------------------------------------------------------------------------

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
/****
 **	[Plugin:PADrend] PADrend/Navigation/Plugin.escript
 **
 **/

PADrend.Navigation := new Plugin({
		Plugin.NAME : 'PADrend/Navigation',
		Plugin.DESCRIPTION : "Keyboard and mouse navigation for PADrend.",
		Plugin.VERSION : 0.6,
		Plugin.AUTHORS : "Claudius, Ralf & Benjamin",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend','PADrend/EventLoop','PADrend/HID'],
		Plugin.EXTENSION_POINTS : []
});

// -------------------

PADrend.Navigation.storedPositions := void;
PADrend.Navigation.cameraMover := void;
PADrend.Navigation.flyToHandler := void;
PADrend.Navigation.joystickSupport := void;

PADrend.Navigation.init @(override) := fn(){

	Util.registerExtension('PADrend_Init',this->ex_Init, Extension.HIGH_PRIORITY+1);

	Util.registerExtension('PADrend_KeyPressed',onKeyPressed, Extension.HIGH_PRIORITY);
	Util.registerExtension('PADrend_AfterFrame',this->ex_FrameEnding);
	
	return true;
};
// ------------------
//! [ext:PADrend_AfterFrame]
PADrend.Navigation.ex_FrameEnding := fn(){
	// -------------------
	// ---- Perform Movements
	this.cameraMover.execute();
};

//! [ext:PADrend_Init]
PADrend.Navigation.ex_Init := fn(){
	
	
	// create cameraMover
			
	this.cameraMover = new (Std.module('LibMinSGExt/CameraMover'))(PADrend.SystemUI.getWindow(), PADrend.SystemUI.getEventContext(), PADrend.getDolly(),GLOBALS.camera);
	this.cameraMover.setInvertYAxis(systemConfig.getValue('PADrend.Input.invertMouse',false));
	this.cameraMover.smoothMouse = systemConfig.getValue('PADrend.Input.smoothMouse',true);

	this.cameraMover.joypad_rotationFactor := systemConfig.getValue('PADrend.Input.rotationFactor',3);
	this.cameraMover.joypad_rotationExponent := systemConfig.getValue('PADrend.Input.rotationExponent',2);
	
//    cameraMover.registerGamepad( PADrend.HID.getDevice("VirtualGamepad")  );

	Util.registerExtension('PADrend_UIEvent',[cameraMover] => fn(cameraMover,evt){	return cameraMover.getMouseView() ? cameraMover.handleEvent(evt,false) : false;	}, Extension.HIGH_PRIORITY);
	Util.registerExtension('PADrend_UIEvent',[cameraMover] => fn(cameraMover,evt){	return cameraMover.getMouseView() ? false : cameraMover.handleEvent(evt,false);	}, Extension.LOW_PRIORITY);

	joystickSupport = Std.DataWrapper.createFromEntry(systemConfig,'PADrend.Input.joystickSupport',false);
	if(joystickSupport())
		cameraMover.registerGamepad( PADrend.HID.getDevice("Gamepad_1")  );
	
	this.storedPositions = [ ];

};

static onKeyPressed = fn(evt){
	// The keys are not handled in PADrend_KeyPressed as the keys defined in this plugin should even work in mouse view mode.
	if(evt.key == Util.UI.KEY_SPACE) { // [space] (Panic! Reset camera)
		PADrend.getDolly().setRelTransformation(new Geometry.SRT());
		PADrend.getDolly().setWorldOrigin(PADrend.getCurrentScene().getWorldBB().getCenter());
		PADrend.Navigation.getCameraMover().reset();
		return true;
	} else if(evt.key == Util.UI.KEY_KP5) { // numpad '5' (TopView)
		var sceneBB = PADrend.getCurrentScene().getWorldBB();
		
		// Calculate the distance such that the bounding box fits into the viewing frustum.
		var angles = PADrend.getActiveCamera().getAngles();
		
		var worldUp = PADrend.getWorldUpVector();
		var width; var height; var depth;
		if(worldUp.getY() ~= 1){
			width = sceneBB.getExtentX();
			depth = sceneBB.getExtentY();
			height = sceneBB.getExtentZ();
		}
		else if(worldUp.getZ() ~= 1){
			width = sceneBB.getExtentX();
			depth = sceneBB.getExtentZ();
			height = sceneBB.getExtentY();
		}
		else{
			outln("PADrend.Navigation: unsupported world up vector");
		}
		
		var distances = [
			// X direction of scene will be horizontal
			(width / 2) / -angles[0].degToRad().tan(), // left
			(width / 2) / angles[1].degToRad().tan(), // right
			// Z direction of scene will be vertical
			(height / 2) / -angles[2].degToRad().tan(), // bottom
			(height / 2) / angles[3].degToRad().tan() // top
		];
		var targetSRT = new Geometry.SRT(
			sceneBB.getCenter() + worldUp * (distances.max() + depth / 2), // position
			worldUp, // direction (frustum goes to negative direction)
			-PADrend.getWorldFrontVector() //new Geometry.Vec3(0, 0, -1) // up
		);

		PADrend.Navigation.flyTo(targetSRT, 1.0);
		return true;
	} else if(evt.key == Util.UI.KEY_KP8) { // numpad '8' (RotateX around center)
		var sceneCenter=PADrend.getCurrentScene().getWorldBB().getCenter();
		var dist=(PADrend.getDolly().getWorldOrigin()-sceneCenter).length();
		PADrend.getDolly().setRelPosition(sceneCenter);
		PADrend.getDolly().rotateLocal_rad(Math.PI/8,1,0,0);
		PADrend.getDolly().moveLocal(new Geometry.Vec3(0,0,1)*dist);
		return true;
	} else if(evt.key == Util.UI.KEY_KP2) { // numpad '2' (RotateX around center)
		var sceneCenter=PADrend.getCurrentScene().getWorldBB().getCenter();
		var dist=(PADrend.getDolly().getWorldOrigin()-sceneCenter).length();
		PADrend.getDolly().setRelPosition(sceneCenter);
		PADrend.getDolly().rotateLocal_rad(-Math.PI/8,1,0,0);
		PADrend.getDolly().moveLocal(new Geometry.Vec3(0,0,1)*dist);
		return true;
	} else if(evt.key == Util.UI.KEY_KP4) { // numpad '4' (RotateY around center)
		var sceneCenter=PADrend.getCurrentScene().getWorldBB().getCenter();
		var dist=(PADrend.getDolly().getWorldOrigin()-sceneCenter).length();
		PADrend.getDolly().setRelPosition(sceneCenter);
		PADrend.getDolly().rotateRel_rad(-Math.PI/8,0,1,0);
		PADrend.getDolly().moveLocal(new Geometry.Vec3(0,0,1)*dist);
		return true;
	} else if(evt.key == Util.UI.KEY_KP6) { // numpad '6' (RotateY around center)
		var sceneCenter=PADrend.getCurrentScene().getWorldBB().getCenter();
		var dist=(PADrend.getDolly().getWorldOrigin()-sceneCenter).length();
		PADrend.getDolly().setRelPosition(sceneCenter);
		PADrend.getDolly().rotateRel_rad(Math.PI/8,0,1,0);
		PADrend.getDolly().moveLocal(new Geometry.Vec3(0,0,1)*dist);
		return true;
	} else if(evt.key == Util.UI.KEY_KP1) { // numpad '1' (TopView)
		var sceneBB = PADrend.getCurrentScene().getWorldBB();
		var dir = new Geometry.Vec3(0, 1, 0);
		var up = new Geometry.Vec3(0, 0, -1);
		var pos = sceneBB.getCenter() + dir * ([sceneBB.getExtentX(), sceneBB.getExtentZ()].max());
		PADrend.getDolly().setRelTransformation(new Geometry.SRT(pos, dir, up));
		return true;
	} else if(evt.key == Util.UI.KEY_KP7) { // numpad '7' (FrontView)
		var sceneBB = PADrend.getCurrentScene().getWorldBB();
		var dir = new Geometry.Vec3(0, 0, 1);
		var up = new Geometry.Vec3(0, 1, 0);
		var pos = sceneBB.getCenter() + dir * ([sceneBB.getExtentX(), sceneBB.getExtentY()].max());
		PADrend.getDolly().setRelTransformation(new Geometry.SRT(pos, dir, up));
		return true;
	} else if(evt.key == Util.UI.KEY_KP9) { // numpad '9' (LeftView)
		var sceneBB = PADrend.getCurrentScene().getWorldBB();
		var dir = new Geometry.Vec3(-1, 0, 0);
		var up = new Geometry.Vec3(0, 1, 0);
		var pos = sceneBB.getCenter() + dir * ([sceneBB.getExtentY(), sceneBB.getExtentZ()].max());
		PADrend.getDolly().setRelTransformation(new Geometry.SRT(pos, dir, up));
		return true;
	}
	// [shift] + [0...9] jump to stored position
	// [ctrl] + [shift] + [0...9] store position
	foreach( [Util.UI.KEY_0, Util.UI.KEY_1, Util.UI.KEY_2, Util.UI.KEY_3, Util.UI.KEY_4, Util.UI.KEY_5, Util.UI.KEY_6, Util.UI.KEY_7, Util.UI.KEY_8, Util.UI.KEY_9] as var index, var key) {
		if(evt.key == key) {
			if(!PADrend.getEventContext().isShiftPressed())
				return false;
			
			if(PADrend.getEventContext().isCtrlPressed()){ // store
				out("Storing current position at #",index,"\n");
				this.storedPositions[index] = PADrend.getDolly().getRelTransformationSRT();
			} else {
				var srt = this.storedPositions[index];
				if(!srt){
					Runtime.warn("No position stored at #"+index);
				}else{
					out("Restoring position #",index,"\n");
					this.flyTo(srt);
				}
			}
			return true;
		};
	}

	

	return false;
};

//! Smoothly assign the dolly a new SRT
PADrend.Navigation.flyTo := fn(Geometry.SRT targetSRT, Number duration=0.5){

	// if we are not already flying...
	if(!this.flyToHandler){
		this.flyToHandler = new ExtObject({
			$targetSRT : void,
			$sourceSRT : void,
			$duration : 0,
			$start :0 ,
			$execute : fn(...){
				var p0 = new Geometry.Vec2(0,0);
				var p1 = new Geometry.Vec2(1.0,0.0);
				var p2 = new Geometry.Vec2(0.0,1.0);
				var p3 = new Geometry.Vec2(1,1);
				while( (Util.Timer.now()-start)<duration ){
					var f = Geometry.interpolateCubicBezier(p0,p1,p2,p3,(Util.Timer.now()-start)/duration ).getY();
					PADrend.getDolly().setRelTransformation( new Geometry.SRT(sourceSRT,targetSRT,f));
					yield Extension.CONTINUE;
				}
				PADrend.getDolly().setRelTransformation( targetSRT );
				PADrend.Navigation.flyToHandler = void;
				return Extension.REMOVE_EXTENSION;	
			}
		});
		Util.registerExtension('PADrend_AfterFrame',flyToHandler->flyToHandler.execute);
	}
	flyToHandler.sourceSRT = PADrend.getDolly().getRelTransformationSRT().clone();
	flyToHandler.targetSRT = PADrend.getDolly().getParent().getWorldTransformationMatrix().inverse().toSRT() * targetSRT;
	flyToHandler.duration = duration;
	flyToHandler.start = Util.Timer.now();;

};

PADrend.Navigation.getCameraMover := fn(){
	return cameraMover;
};

// --------------------
// Aliases

PADrend.getCameraMover := (PADrend.Navigation)->PADrend.Navigation.getCameraMover; 

return PADrend.Navigation;
// ------------------------------------------------------------------------------

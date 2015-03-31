/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2008-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2009 Jan Krems
 * Copyright (C) 2010 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 ** [LibMinSGExt] CameraMover.escript
 **
 ** Control a Node's movement by user input (mouse, keyboard, and gamepad)
 **/


static T = new Type;

/*! public attributes */
T.joypad_sensitivity := 10;
T.joypad_rotationFactor := 3;
T.joypad_rotationExponent := 2;
T.initialSpeed := 10;

T.smoothMouse := true;
T.pivotOffset @(init,private) := Geometry.Vec3;


/*! internal attributes */
T.cameraNode @(private) := void;
T.dolly @(private) := void;
T.evtentContext @(private) := void;
T.frameDuration @(private) := 0;
T.invertYAxis @(private) := false;
T.joypad_planeMovementModifier @(private) := 0;
T.keyboardMoveLocalVec @(private,init) 	:= Geometry.Vec3;
T.lastFrameTimestamp @(private,init) := clock;
T.mouseView @(private) := false;
T.moveLocalVectors @(private,init) 	:= Array; // [Geometry.Vec3*]; // each device can add a separate movelLocalVec, so that they don't interfere with each other.
T.moveAbsVec @(private,init) 	:= Geometry.Vec3;
T.moveWalkVec @(private,init) 	:= Geometry.Vec3;
T.pressedWithCtrl @(private,init) := Map;
T.rotateDollyVec @(private,init)	:= Geometry.Vec3;

T.mouseRotationVec @(private,init)	:= Geometry.Vec3;
T.mouseRotationTime @(private)	:= 0;

T.discreteRotationSpeed @(private) := 2.0;
T.speed @(private) := void;
T.walkMode @(private) := false;
T.window @(private) := false;
T.registeredDevices @(private,init) := Map;


T._actions @(private,init) := fn(){
	return {
		Util.UI.EVENT_KEYBOARD : {
			Util.UI.KEY_W : fn(evt) { // [w] forward
					if(evt.pressed) {
						this.walkMode ? moveWalkVec.z(this.moveWalkVec.z() - 1) : this.keyboardMoveLocalVec.z(this.keyboardMoveLocalVec.z() - 1);
					} else {
						this.walkMode ? moveWalkVec.z(this.moveWalkVec.z() + 1) : this.keyboardMoveLocalVec.z(this.keyboardMoveLocalVec.z() + 1);
					}
				},
			Util.UI.KEY_S : fn(evt) { // [s] backward
					if(evt.pressed) {
						this.walkMode ? moveWalkVec.z(this.moveWalkVec.z() + 1) : this.keyboardMoveLocalVec.z(this.keyboardMoveLocalVec.z() + 1);
					} else {
						this.walkMode ? moveWalkVec.z(this.moveWalkVec.z() - 1) : this.keyboardMoveLocalVec.z(this.keyboardMoveLocalVec.z() - 1);
					}
				},
			Util.UI.KEY_R : fn(evt) { // [r] up
					if(evt.pressed) {
						this.keyboardMoveLocalVec.y(this.keyboardMoveLocalVec.y() + 1);
					} else {
						this.keyboardMoveLocalVec.y(this.keyboardMoveLocalVec.y() - 1);
					}
				},
			Util.UI.KEY_F : fn(evt) { // [f] down
					if(evt.pressed) {
						this.keyboardMoveLocalVec.y(this.keyboardMoveLocalVec.y() - 1);
					} else {
						this.keyboardMoveLocalVec.y(this.keyboardMoveLocalVec.y() + 1);
					}
				},
			Util.UI.KEY_A : fn(evt) { // [a] left
					if(evt.pressed) {
						this.keyboardMoveLocalVec.x(this.keyboardMoveLocalVec.x() - 0.5);
					} else {
						this.keyboardMoveLocalVec.x(this.keyboardMoveLocalVec.x() + 0.5);
					}
				},
			Util.UI.KEY_D : fn(evt) { // [d] right
					if(evt.pressed) {
						this.keyboardMoveLocalVec.x(this.keyboardMoveLocalVec.x() + 0.5);
					} else {
						this.keyboardMoveLocalVec.x(this.keyboardMoveLocalVec.x() - 0.5);
					}
				},
			Util.UI.KEY_Q : fn(evt) { // [q] rotate left
					if(evt.pressed) {
						this.rotateDollyVec.y(this.rotateDollyVec.y() + 1);
					} else {
						this.rotateDollyVec.y(this.rotateDollyVec.y() - 1);
					}
				},
			Util.UI.KEY_E : fn(evt) { // [e] rotate right
					if(evt.pressed) {
						this.rotateDollyVec.y(this.rotateDollyVec.y() - 1);
					} else {
						this.rotateDollyVec.y(this.rotateDollyVec.y() + 1);
					}
				},
			Util.UI.KEY_M : fn(evt) { // [m] toggle MouseView
					if(evt.pressed) {
						this.setMouseView(!this.mouseView);
					}
				}, 
			Util.UI.KEY_ESCAPE : fn(evt) { // esc ends mouse view mode; otherwise the event is explicitly NOT consumed
					if(evt.pressed && this.getMouseView()) {
						this.setMouseView(false);
					} else {
						return false;
					}
				}
		},
		Util.UI.EVENT_MOUSE_MOTION : {
			Util.UI.MASK_NO_BUTTON : fn(evt) {
				var dx = evt.deltaY*(this.invertYAxis?1:-1);
				var dy = -evt.deltaX;
				if(this.smoothMouse){
					this.mouseRotationTime = clock();
					this.mouseRotationVec = this.mouseRotationVec*0.5 + new Geometry.Vec3( dx*0.5, dy*0.5, 0  )*0.5;
					this.execute();
				}else{
					var pivot = this.getPivot();
					this.dolly.rotateAroundLocalAxis_rad( dx*0.01, new Geometry.Line3( pivot, [1,0,0]));
					this.dolly.rotateAroundRelAxis_rad( dy*0.01, new Geometry.Line3( this.dolly.localPosToRelPos( pivot ), [0,1,0]));
				}
			},
			Util.UI.MASK_MOUSE_BUTTON_LEFT : fn(evt) {
				this.dolly.moveLocal(evt.deltaX*this.speed*this.frameDuration,0,evt.deltaY*this.speed*this.frameDuration);
			},
			Util.UI.MASK_MOUSE_BUTTON_RIGHT : fn(evt) {
				this.dolly.moveLocal(evt.deltaX*this.speed*this.frameDuration,evt.deltaY*this.speed*this.frameDuration*(this.invertYAxis?1:-1),0);
			}
		},
		Util.UI.EVENT_MOUSE_BUTTON : {
			Util.UI.MOUSE_BUTTON_MIDDLE : fn(evt) { // middle: toggle mouseView
				if(evt.pressed) {
					this.setMouseView(!this.mouseView);
				}
			},
			Util.UI.MOUSE_WHEEL_UP : fn(evt) { //wheel up + ctr: move camera
				if(evt.pressed) {
					if(this.evtentContext.isCtrlPressed()) {
						var dist = this.pivotOffset.z()*0.9;
						this.dolly.moveLocal(new Geometry.Vec3(0,0,this.pivotOffset.z()-dist));
						this.pivotOffset.z( dist );
					} else { //wheel up: increase speed
						this.speed*=2; 
					}
				}
			},
			Util.UI.MOUSE_WHEEL_DOWN:fn(evt){ //wheel down + ctr: move camera
				if(evt.pressed) {
					if(this.evtentContext.isCtrlPressed()) {
						var dist = [this.pivotOffset.z()*1.1,-0.1].min();
						this.dolly.moveLocal(new Geometry.Vec3(0,0,this.pivotOffset.z()-dist));
						this.pivotOffset.z( dist );
					} else { //wheel down: decrease speed
						this.speed*=0.5;
					}
				}
			},
		}
	};
};


/*!	(ctor)
	@param window and eventContext
	@param dolly The node moved by the CameraMover
	@param camera (optional) The (real) camera placed inside the dolly. If left out, camera and dolly are the same.	*/
T._constructor ::= fn(Util.UI.Window _window, Util.UI.EventContext _evtentContext, MinSG.Node _dolly,[MinSG.Node,false] _camera=false){
	this.window = _window;
	this.evtentContext = _evtentContext;
	this.dolly = _dolly;
	this.cameraNode = _camera ? _camera : _dolly;
	this.speed = this.initialSpeed;
	this.moveLocalVectors += this.keyboardMoveLocalVec;
};

T.execute ::= fn(){
	var tmp=clock();
	this.frameDuration=(tmp-lastFrameTimestamp);
	this.lastFrameTimestamp=tmp;

	if(!this.moveWalkVec.isZero()){
		var m = this.dolly.getRelTransformationSRT();
		var v = m*this.moveWalkVec - m*new Geometry.Vec3(0,0,0);
		v.y(0);
		if(v!=new Geometry.Vec3(0,0,0))
			v.normalize();
		this.dolly.moveRel( v*this.speed*this.frameDuration );
	}
	foreach(this.moveLocalVectors as var localVec){
		if(!localVec.isZero())
			this.dolly.moveLocal( localVec *this.speed*this.frameDuration);
	}
	if(!this.moveAbsVec.isZero())
		this.dolly.moveRel( this.moveAbsVec *this.speed*this.frameDuration);
	

	var pivot = this.getPivot();
	foreach( [rotateDollyVec,mouseRotationVec] as var rVec){
		// rotate around head
		if(rVec.x()!=0){
			this.dolly.rotateAroundLocalAxis_rad( rVec.x()* this.frameDuration*this.discreteRotationSpeed,  
													new Geometry.Line3(pivot, [1,0,0]));
		}
		if(rVec.y()!=0){
			this.dolly.rotateAroundRelAxis_rad( rVec.y()* this.frameDuration*this.discreteRotationSpeed, 
												new Geometry.Line3(  this.dolly.localPosToRelPos( pivot ), [0,1,0] ));
		}
	}
	var mouseEventDelta = clock()-this.mouseRotationTime;
	if(mouseEventDelta>0.2){
		mouseRotationVec.setValue(0,0,0);
	}else if( mouseEventDelta>0.04 )
		mouseRotationVec*=0.2;
};
T.getDiscreteRotationSpeed ::= 	fn(){	return this.discreteRotationSpeed;	};
T.getDolly ::= 					fn(){	return this.dolly;	};
T.getPivot ::= fn(){
	return this.dolly.isSet($getHeadNode) ? this.dolly.getHeadNode().getRelOrigin()+this.pivotOffset : this.pivotOffset;
};

T.getInvertYAxis ::= 			fn(){	return this.invertYAxis;	};
T.getMouseView ::= 				fn(){	return this.mouseView;	};
T.getSpeed ::= 					fn(){	return this.speed;	};
T.getWalkMode ::= 				fn(){	return this.walkMode;	};
T.handleEvent ::= fn(evt,consumeKeysInMouseView=false){
	var action=false;
	var actionSlot = this._actions.get(evt.type,new Map);

	if(evt.type==Util.UI.EVENT_KEYBOARD){
		if(pressedWithCtrl[evt.key]){ // if [ctrl] is pressed while pressing another button, the release of the other button should be ignored.
			if(!evt.pressed){
				pressedWithCtrl[evt.key] = false;
				return false;
			}
		}
		if(this.evtentContext.isCtrlPressed()){ 
			if(evt.pressed)
				pressedWithCtrl[evt.key] = true;
		}else{
			action = actionSlot.get(evt.key,actionSlot[evt.key]);
			if(!action)
				return consumeKeysInMouseView && this.mouseView;
		}
	} else if(evt.type==Util.UI.EVENT_MOUSE_MOTION) {
		// The additional delta check prevents sudden jumps in the movement which may e.g. occur
		// if the cursor is warped. The value of 50 is chosen by try and error.
		if(!this.mouseView || evt.deltaX.abs()>50 || evt.deltaY.abs()>50) { 
			return false;
		}
		var border = 20;
		if(evt.x < border || evt.x > renderingContext.getWindowWidth() - border ||
			evt.y < border || evt.y > renderingContext.getWindowHeight() - border) {
			this.window.warpCursor(renderingContext.getWindowWidth() / 2, renderingContext.getWindowHeight() / 2);
		}
		action=actionSlot[evt.buttonMask];
	}else if(evt.type==Util.UI.EVENT_MOUSE_BUTTON) {
		action=actionSlot[evt.button];
		if(!action && this.mouseView) // consume all mouse button events in mouseView-mode, even if no action is performed.
			return true;
	}
	if(!action)
		return false;
	var consumeEvent = (this->action)(evt);
	if(void == consumeEvent) // per default, events are consumed
		consumeEvent = true;
	return consumeEvent;
};

//		}

T.reset ::= fn(){
	this.mouseRotationVec = new Geometry.Vec3;
	this.pivotOffset = new Geometry.Vec3;
	this.keyboardMoveLocalVec.setValue(0,0,0);
	this.rotateDollyVec = new Geometry.Vec3;
	this.moveWalkVec = new Geometry.Vec3;
	this.speed = this.initialSpeed;
	this.joypad_planeMovementModifier = 0;
	this.setMouseView(false);
};

T.setAction ::= 		fn(eventType, eventState, action)	{	this._actions[eventType][eventState] = action;	};
T.setDiscreteRotationSpeed ::= 	fn(Number s)	{	this.discreteRotationSpeed = s;	};
T.setDolly ::= 		fn(MinSG.Node newCamera)	{	this.dolly=newCamera;	};

//! This method is part of the ongoing HID-redesign \see #677
T.registerGamepad ::= fn(gamepad){
	Std.Traits.requireTrait(gamepad, Std.module('LibUtilExt/HID_Traits').ControllerAnalogAxisTrait); //! \see HID_Traits.ControllerAnalogAxisTrait
	
	
	var localMovementVec = new Geometry.Vec3;
	this.moveLocalVectors += localMovementVec;
	
	//! \see HID_Traits.ControllerAnalogAxisTrait
	gamepad.onAnalogAxisChanged += [localMovementVec]=>this->fn(localMovementVec,axis,value){
		if(axis==0){ // move left/right
			localMovementVec.x(value.sign()*(value*0.8).pow(2));
		}else if(axis==1){ // move forward/backward
			if(this.joypad_planeMovementModifier>0)
				this.moveAbsVec.y(-(value.sign()*(value*0.6).pow(2)));
			else
				this.walkMode ? 	(this.moveWalkVec.z(value.sign()*(value).pow(2))):
									(localMovementVec.z(value.sign()*(value).pow(2)));
		}else if(axis==2){ // rotate around y-axis
			this.rotateDollyVec.y(-(value.sign()*(value * this.joypad_rotationFactor ).pow(this.joypad_rotationExponent)));
		}else if(axis==3){ // rotate around x-axis
			this.rotateDollyVec.x((value.sign()*(value * this.joypad_rotationFactor ).pow(this.joypad_rotationExponent)) * (this.invertYAxis?1:-1) );
		}else{
			return $CONTINUE;
		}
		return $BREAK;
	};

	
	//! \see HID.???Trait
	gamepad.onButton += [localMovementVec]=>this->fn(localMovementVec,button,pressed){
		if(button == 9) {	// reset
			if(pressed) {
				this.reset();
				this.dolly.setRelPosition(new Geometry.Vec3(0,0,0)); 
			}

		}else if(button == 4) {	
			if(pressed) {
				if(this.joypad_planeMovementModifier == 0)
					localMovementVec.z(0);
				this.joypad_planeMovementModifier++;
			} else {
				this.joypad_planeMovementModifier--;
				if(this.joypad_planeMovementModifier == 0)
					this.moveAbsVec.y(0);
			}
		}else{
			return $CONTINUE;
		}
		return $BREAK;
	};
		
};

T.setInvertYAxis ::= 	fn(Bool b)	{	this.invertYAxis=b;	};

T.setMouseView ::= fn(Bool enable){
	if(enable){
		this.mouseView=true;
		this.window.hideCursor();
		this.window.grabInput();
		
	}else{
		this.mouseView=false;
		this.window.showCursor();
		this.window.ungrabInput();
	}
};

T.setSpeed ::= 					fn(Number s)	{	this.speed = s;	};
T.setWalkMode ::= 				fn(Bool b)		{	this.walkMode=b;	};

return T;
// --------------------------------------

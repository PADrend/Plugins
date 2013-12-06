/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2008-2013 Claudius Jähn <claudius@uni-paderborn.de>
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


/***
 ** CameraMover
 **/
MinSG.CameraMover := new Type;

var CameraMover = MinSG.CameraMover;
/*! public attributes */
CameraMover.joypad_sensitivity := 10;
CameraMover.joypad_rotationFactor := 3;
CameraMover.joypad_rotationExponent := 2;
CameraMover.initialSpeed := 10;

/*! internal attributes */
CameraMover.cameraNode @(private) := void;
CameraMover.dolly @(private) := void;
CameraMover.evtentContext @(private) := void;
CameraMover.frameDuration @(private) := 0;
CameraMover.invertYAxis @(private) := false;
CameraMover.joypad_planeMovementModifier @(private) := 0;
CameraMover.lastFrameTimestamp @(private,init) := clock;
CameraMover.mouseView @(private) := false;
CameraMover.moveLocalVec @(private,init) 	:= Geometry.Vec3;
CameraMover.moveAbsVec @(private,init) 	:= Geometry.Vec3;
CameraMover.moveWalkVec @(private,init) 	:= Geometry.Vec3;
CameraMover.pressedWithCtrl @(private,init) := Map;
CameraMover.rotateDollyVec @(private,init)	:= Geometry.Vec3;
CameraMover.discreteRotationSpeed @(private) := 2.0;
CameraMover.speed @(private) := void;
CameraMover.walkMode @(private) := false;
CameraMover.window @(private) := false;
CameraMover.registeredDevices @(private,init) := Map;


CameraMover._actions @(private,init) := fn(){
	return {
		Util.UI.EVENT_KEYBOARD : {
			Util.UI.KEY_W : fn(evt) { // [w] forward
					if(evt.pressed) {
						this.walkMode ? moveWalkVec.z(this.moveWalkVec.z() - 1) : this.moveLocalVec.z(this.moveLocalVec.z() - 1);
					} else {
						this.walkMode ? moveWalkVec.z(this.moveWalkVec.z() + 1) : this.moveLocalVec.z(this.moveLocalVec.z() + 1);
					}
				},
			Util.UI.KEY_S : fn(evt) { // [s] backward
					if(evt.pressed) {
						this.walkMode ? moveWalkVec.z(this.moveWalkVec.z() + 1) : this.moveLocalVec.z(this.moveLocalVec.z() + 1);
					} else {
						this.walkMode ? moveWalkVec.z(this.moveWalkVec.z() - 1) : this.moveLocalVec.z(this.moveLocalVec.z() - 1);
					}
				},
			Util.UI.KEY_R : fn(evt) { // [r] up
					if(evt.pressed) {
						this.moveLocalVec.y(this.moveLocalVec.y() + 1);
					} else {
						this.moveLocalVec.y(this.moveLocalVec.y() - 1);
					}
				},
			Util.UI.KEY_F : fn(evt) { // [f] down
					if(evt.pressed) {
						this.moveLocalVec.y(this.moveLocalVec.y() - 1);
					} else {
						this.moveLocalVec.y(this.moveLocalVec.y() + 1);
					}
				},
			Util.UI.KEY_A : fn(evt) { // [a] left
					if(evt.pressed) {
						this.moveLocalVec.x(this.moveLocalVec.x() - 0.5);
					} else {
						this.moveLocalVec.x(this.moveLocalVec.x() + 0.5);
					}
				},
			Util.UI.KEY_D : fn(evt) { // [d] right
					if(evt.pressed) {
						this.moveLocalVec.x(this.moveLocalVec.x() + 0.5);
					} else {
						this.moveLocalVec.x(this.moveLocalVec.x() - 0.5);
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
				this.dolly.rotateLocal_rad(evt.deltaY*0.01*(this.invertYAxis?1:-1),1,0,0);
				this.dolly.rotateRel_rad(-evt.deltaX/100,0,1,0);
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
						var dist = this.cameraNode.getRelPosition().length();
						this.cameraNode.moveLocal(new Geometry.Vec3(0,0,-dist*0.1));
					} else { //wheel up: increase speed
						this.speed*=2; 
					}
				}
			},
			Util.UI.MOUSE_WHEEL_DOWN:fn(evt){ //wheel down + ctr: move camera
				if(evt.pressed) {
					if(this.evtentContext.isCtrlPressed()) {
						var dist = this.cameraNode.getRelPosition().length();
						this.cameraNode.moveLocal(new Geometry.Vec3(0,0,[dist*0.1,0.1].max()));
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
CameraMover._constructor ::= fn(Util.UI.Window _window, Util.UI.EventContext _evtentContext, MinSG.Node _dolly,[MinSG.Node,false] _camera=false){
	this.window = _window;
	this.evtentContext = _evtentContext;
	this.dolly = _dolly;
	this.cameraNode = _camera ? _camera : _dolly;
	this.speed = this.initialSpeed;
};

CameraMover.execute ::= fn(){
	var tmp=clock();
	this.frameDuration=(tmp-lastFrameTimestamp);
	this.lastFrameTimestamp=tmp;

	if(!this.moveWalkVec.isZero()){
		var m = this.dolly.getSRT();
		var v = m*this.moveWalkVec - m*new Geometry.Vec3(0,0,0);
		v.y(0);
		if(v!=new Geometry.Vec3(0,0,0))
			v.normalize();
		this.dolly.moveRel( v*this.speed*this.frameDuration );
	}
	if(!this.moveLocalVec.isZero())
		this.dolly.moveLocal( this.moveLocalVec *this.speed*this.frameDuration);
	if(!this.moveAbsVec.isZero())
		this.dolly.moveRel( this.moveAbsVec *this.speed*this.frameDuration);
	if(this.rotateDollyVec.x()!=0)
		this.dolly.rotateLocal_rad( this.rotateDollyVec.x()* this.frameDuration*this.discreteRotationSpeed,1,0,0);
	if(this.rotateDollyVec.y()!=0)
		this.dolly.rotateRel_rad( this.rotateDollyVec.y()* this.frameDuration*this.discreteRotationSpeed,0,1,0);
};
CameraMover.getDiscreteRotationSpeed ::= 	fn(){	return this.discreteRotationSpeed;	};
CameraMover.getDolly ::= 					fn(){	return this.dolly;	};
CameraMover.getInvertYAxis ::= 				fn(){	return this.invertYAxis;	};
CameraMover.getMouseView ::= 				fn(){	return this.mouseView;	};
CameraMover.getSpeed ::= 					fn(){	return this.speed;	};
CameraMover.getWalkMode ::= 				fn(){	return this.walkMode;	};
CameraMover.handleEvent ::= fn(evt,consumeKeysInMouseView=false){
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

CameraMover.reset ::= fn(){
	this.moveLocalVec = new Geometry.Vec3;
	this.rotateDollyVec = new Geometry.Vec3;
	this.moveWalkVec = new Geometry.Vec3;
	this.speed = this.initialSpeed;
	this.joypad_planeMovementModifier = 0;
	this.setMouseView(false);
};

CameraMover.setAction ::= 		fn(eventType, eventState, action)	{	this._actions[eventType][eventState] = action;	};
CameraMover.setDiscreteRotationSpeed ::= 	fn(Number s)	{	this.discreteRotationSpeed = s;	};
CameraMover.setDolly ::= 		fn(MinSG.Node newCamera)	{	this.dolly=newCamera;	};

//! This method is part of the ongoing HID-redesign \see #677
CameraMover.registerGamepad ::= fn(gamepad){
	Traits.requireTrait(gamepad,HID.ControllerAnalogAxisTrait); //! \see HID.ControllerAnalogAxisTrait
	
	//! \see HID.ControllerAnalogAxisTrait
	gamepad.onAnalogAxisChanged += this->fn(axis,value){
		if(axis==0){ // move left/right
			this.moveLocalVec.x(value.sign()*(value*0.8).pow(2));
		}else if(axis==1){ // move forward/backward
			if(this.joypad_planeMovementModifier>0)
				this.moveAbsVec.y(-(value.sign()*(value*0.6).pow(2)));
			else
				this.walkMode ? 	(this.moveWalkVec.z(value.sign()*(value).pow(2))):
									(this.moveLocalVec.z(value.sign()*(value).pow(2)));
		}else if(axis==2){ // rotate around y-axis
			this.rotateDollyVec.y(-(value.sign()*(value * this.joypad_rotationFactor ).pow(this.joypad_rotationExponent)));
		}else if(axis==3){ // rotate around x-axis
			this.rotateDollyVec.x((value.sign()*(value * this.joypad_rotationFactor ).pow(this.joypad_rotationExponent)) * (this.invertYAxis?1:-1) );
		}else{
			return $CONTINUE;
		}
		return $BREAK;
	};

	
	//! \see HID.ControllerAnalogAxisTrait
	gamepad.onButton += this->fn(button,pressed){
		if(button == 9) {	// reset
			if(pressed) {
				this.reset();
				this.dolly.setRelPosition(new Geometry.Vec3(0,0,0)); 
			}
		}else if(button == 5) {	
			if(pressed) {
				this.moveAbsVec.y(this.moveAbsVec.y() + 1);
			} else {
				this.moveAbsVec.y(this.moveAbsVec.y() - 1);
			}
		}else if(button == 7) {	
			if(pressed) {
				this.moveAbsVec.y(this.moveAbsVec.y() - 1);
			} else {
				this.moveAbsVec.y(this.moveAbsVec.y() + 1);
			}	
		}else if(button == 4) {	
			if(pressed) {
				if(this.joypad_planeMovementModifier == 0)
					this.moveLocalVec.z(0);
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

CameraMover.setInvertYAxis ::= 	fn(Bool b)	{	this.invertYAxis=b;	};

CameraMover.setMouseView ::= fn(Bool enable){
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

CameraMover.setSpeed ::= 					fn(Number s)	{	this.speed = s;	};
CameraMover.setWalkMode ::= 				fn(Bool b)		{	this.walkMode=b;	};

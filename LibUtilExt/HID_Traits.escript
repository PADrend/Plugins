/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	LibUtilExt/HID_Traits.escript
 **/
    
static HID_Traits = new Namespace; 

/*! Basic HID-Trait required by all HIDs. 
	Adds the following methods:
	
	- String getDeviceId()
	- onResetDevice						Extendable MultiProcedure
	- onResetDevice_static				Static extendable MultiProcedure
	- resetDevice						Resets the device's status (pressed buttons, etc.)
	- void setDeviceId(String)

*/
HID_Traits.DeviceBaseTrait := new Traits.GenericTrait("HID_Traits.DeviceBaseTrait");
{
	var t = HID_Traits.DeviceBaseTrait;
	
	t.attributes.hidID @(private) := void;
	
	t.attributes.onResetDevice_static ::= void;
	t.attributes.onResetDevice @(init) := MultiProcedure;
	
	t.attributes.getDeviceId ::= 	fn()	{		return this.hidID;	};
	t.attributes.resetDevice ::= fn(){
		onResetDevice_static();
		onResetDevice();
	};
	t.attributes.setDeviceId ::= 	fn(id)	{	this.hidID=id;	};

	t.onInit += fn(obj,id=void){
		(obj->fn(id){ 
			this.hidID = id ? id : this.toString();
			this.onResetDevice_static = new MultiProcedure;
		})(id);
		
	};
}


//----------

/*! The HID-Controller has @param numberOfButtons many buttons.
	Adds the following methods:
	
	- getButtonCount()								Returns the number of available buttons.
	- getButtonStatus(Number buttonId)				Returns if the given button is pressed.
	- onButton(Number buttonId, Bool pressed)		Chained extension point called 
													on each button event. 
													\see LibUtilExt/Extension.escript
	- registerButtonListener(Number buttonId,fun)	Register a listener that is called when an 
													event for the specific button occurs.

	- sendButtonEvent(Number buttonId, Bool pressed) Needs to be called to invoke
													the Button listener.
													
	\note requires HID_Traits.DeviceBaseTrait
*/
HID_Traits.ControllerButtonTrait := new Traits.GenericTrait("HID_Traits.ControllerButtonTrait");
{
	var t = HID_Traits.ControllerButtonTrait;
	
	t.attributes.onButton @(init) := 	fn(){	
		var ExtensionPoint = Std.module('LibUtilExt/ExtensionPoint');
		return new ExtensionPoint(ExtensionPoint.CHAINED|ExtensionPoint.THROW_EXCEPTION);
	};

	t.attributes.getButtonCount ::= 	fn(){	return this._buttonStatus.count(); };
	t.attributes.getButtonStatus ::= 	fn(Number buttonId){	return this._buttonStatus[buttonId]; };

	t.attributes.registerButtonListener ::= fn(buttonId,fun,p...){
		return this.onButton.registerExtension([buttonId,fun] => fn(desiredButton,fun,buttonId,pressed){
			if(desiredButton == buttonId){
				return fun(buttonId,pressed);
			}
		} ,p...);
	};
	
	t.attributes.sendButtonEvent ::= fn(Number buttonId,Bool pressed){
		this._buttonStatus[buttonId] = pressed;
		return this.onButton(buttonId,pressed);
	};
	t.onInit += fn(obj,numberOfButtons){
		Std.Traits.requireTrait(obj,HID_Traits.DeviceBaseTrait);		//! \see HID_Traits.DeviceBaseTrait
		obj._buttonStatus @(init,private) := (new Array).resize(numberOfButtons,false);
		
		//! \see HID_Traits.DeviceBaseTrait
		obj.onResetDevice_static += fn(){
			foreach(this._buttonStatus as var id,var value)
				this._buttonStatus[id] = false;
		};
	};
}

/*! The HID-Controller has @param numberOfAxes many analog axes.
	Adds the following methods:
	
	- getAxisCount()								Returns the number of available axes.
	- getAxisStatus(Number axisId)					Returns the value of the given axis.
	- onAnalogAxisChanged(Number axisId, Number value)	Chained extension point called 
													on each axis event. 
													\see LibUtilExt/Extension.escript
	- registerAxisListener(Number axisId,fun)		Register a listener that is called when an 
													event for the specific axis occurs.

	- sendAxisEvent(Number axisId, Number value)	Needs to be called to invoke
													the axes listener.
	\note The axis values should be normalized in the range from -1.0 to 1.0!
	\note requires HID_Traits.DeviceBaseTrait
*/
HID_Traits.ControllerAnalogAxisTrait := new Traits.GenericTrait("HID_Traits.ControllerAnalogAxisTrait");
{
	var t = HID_Traits.ControllerAnalogAxisTrait;
	
	t.attributes.onAnalogAxisChanged @(init) := 	fn(){	
		var ExtensionPoint = Std.module('LibUtilExt/ExtensionPoint');
		return new ExtensionPoint(ExtensionPoint.CHAINED|ExtensionPoint.THROW_EXCEPTION);
	};

	t.attributes.getAnalogAxisCount ::= 	fn(){	return this._axesStatus.count(); };
	t.attributes.getAnalogAxisValue ::= 	fn(Number axisId){	return this._axesStatus[axisId]; };

	t.attributes.registerAnalogAxisListener ::= fn(axisId,fun,p...){
		return this.onAnalogAxisChanged.registerExtension([axisId,fun] => fn(desiredAxis,fun,axisId,value){
			if(desiredAxis == axisId){
				return fun(value);
			}
		} ,p...);
	};
	
	t.attributes.sendAnalogAxisEvent ::= fn(Number axisId,Number value){
		this._axesStatus[axisId] = value;
		return this.onAnalogAxisChanged(axisId,value);
	};
	t.onInit += fn(obj,numberOfAxes){
		Std.Traits.requireTrait(obj,HID_Traits.DeviceBaseTrait);		//! \see HID_Traits.DeviceBaseTrait
		obj._axesStatus @(init,private) := (new Array).resize(numberOfAxes,0.0);
		
		//! \see HID_Traits.DeviceBaseTrait
		obj.onResetDevice_static += fn(){
			foreach(this._axesStatus as var id,var value)
				this._axesStatus[id] = 0;
		};
	};
}

/*! The HID-Controller has @param numberOfHats many digital hats.
	Adds the following methods:
	
	- getHatCount()								Returns the number of available hats.
	- getHatStatus(Number hatId)					Returns the value of the given hat.
	- onHat(Number hatId, Number value)			Chained extension point called 
													on each hat event. 
													\see LibUtilExt/Extension.escript
	- registerHatListener(Number hatId,fun)		Register a listener that is called when an 
													event for the specific hat occurs.

	- sendHatEvent(Number hatId, Number value)	Needs to be called to invoke
													the hats listener.
	\note The value is a bit combination of:
			Util.UI.MASK_HAT_DOWN, Util.UI.MASK_HAT_UP, Util.UI.MASK_HAT_LEFT, Util.UI.MASK_HAT_RIGHT
	\note requires HID_Traits.DeviceBaseTrait
*/
HID_Traits.ControllerHatTrait := new Traits.GenericTrait("HID_Traits.ControllerHatTrait");
{
	var t = HID_Traits.ControllerHatTrait;
	
	t.attributes.onHatChanged @(init) := fn(){	
		var ExtensionPoint = Std.module('LibUtilExt/ExtensionPoint');
		return new ExtensionPoint(ExtensionPoint.CHAINED|ExtensionPoint.THROW_EXCEPTION);
	};

	t.attributes.getHatCount ::= 	fn(){	return this._hatsStatus.count(); };
	t.attributes.getHatValue ::= 	fn(Number hatId){	return this._hatsStatus[hatId]; };

	t.attributes.registerHatListener ::= fn(hatId,fun,p...){
		return this.onHatChanged.registerExtension([hatId,fun] => fn(desiredHat,fun,hatId,value){
			if(desiredHat == hatId){
				return fun(hatId,value);
			}
		} ,p...);
	};
	
	t.attributes.sendHatEvent ::= fn(Number hatId,Number value){
		this._hatsStatus[hatId] = value;
		return this.onHatChanged(hatId,value);
	};
	t.onInit += fn(obj,numberOfHats){
		Std.Traits.requireTrait(obj,HID_Traits.DeviceBaseTrait);		//! \see HID_Traits.DeviceBaseTrait
		obj._hatsStatus @(init,private) := (new Array).resize(numberOfHats,0.0);
		
		//! \see HID_Traits.DeviceBaseTrait
		obj.onResetDevice_static += fn(){
			foreach(this.getHatCount as var id,var value)
				this.getHatCount[id] = 0;
		};
	};
}


/*! The HID-Controller provides a 6d transformation in room coordinates (position and direction)
	for tracked devices.
	Adds the following methods:
	
	- SRT|void getRoomTransformation()				Returns the current transformation
													\note may return void if no valid transformation
													is available.
	- onRoomTransformationChanged(SRT|void value)	Chained extension point called 
													when the transformation changed. 
													\see LibUtilExt/Extension.escript

	- sendTransformationEvent(SRT|void)				Needs to be called to invoke the transformation listener.
	\note requires HID_Traits.DeviceBaseTrait
*/
HID_Traits.Controller_Room6D_Trait := new Traits.GenericTrait("HID_Traits.Controller_Room6D_Trait");
{
	var t = HID_Traits.Controller_Room6D_Trait;
	
	t.attributes._controllerRoomSRT @(private) := void;
	t.attributes.onRoomTransformationChanged @(init) := fn(){	
		var ExtensionPoint = Std.module('LibUtilExt/ExtensionPoint');
		return new ExtensionPoint(ExtensionPoint.CHAINED|ExtensionPoint.THROW_EXCEPTION);
	};

	t.attributes.getRoomTransformation ::= 		fn(){	return this._controllerRoomSRT; };
	t.attributes.isTransformationValid ::=		fn(){	return true & this._controllerRoomSRT;	};
	
	t.attributes.sendTransformationEvent ::= fn([Geometry.SRT,void] value){
		_controllerRoomSRT = value.clone();
		return this.onRoomTransformationChanged(_controllerRoomSRT);
	};
	t.onInit += fn(obj){
		Std.Traits.requireTrait(obj,HID_Traits.DeviceBaseTrait);		//! \see HID_Traits.DeviceBaseTrait
				
		//! \see HID_Traits.DeviceBaseTrait
		obj.onResetDevice_static += fn(){
			this._controllerRoomSRT = void;
		};
	};
}

// -------------------------------------

/*! Add this trait to a device object to mark it as gamepad device.
	A gamepad needs to have at least buttons and analog axes.
	\see HID_Traits.ControllerButtonTrait
	\see HID_Traits.ControllerAnalogAxisTrait	*/
HID_Traits.GamepadDeviceTrait := new Traits.GenericTrait("HID_Traits.GamepadDeviceTrait");
{
	var t = HID_Traits.GamepadDeviceTrait;

	t.onInit += fn(obj){
		Std.Traits.requireTrait(obj,HID_Traits.ControllerButtonTrait);
		Std.Traits.requireTrait(obj,HID_Traits.ControllerAnalogAxisTrait);
	};
}


GLOBALS.HID := HID_Traits;	//! \deprecated alias

return HID_Traits;

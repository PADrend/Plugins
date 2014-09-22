/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
 
 
var plugin = new Plugin({
		Plugin.NAME : 'PADrend/HID',
		Plugin.DESCRIPTION : "Central registry for Human Interface Devices connected to PADrend.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius, Ralf",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend'],
		Plugin.EXTENSION_POINTS : [	]
});

plugin.init @(override) := fn(){
	

	PADrend.HID.initDefaultGamepad( DataWrapper.createFromConfig(systemConfig,'PADrend.Input.analogSensitivity',0.05) );


//		// create and register virtual keyboard gamepad \see #677
//		PADrend.HID.initVirtualGamepad();

	
	return true;
};
 
 
declareNamespace($PADrend,$HID);

//
////! Use Keyboard to create a virutal gamepad controller.
//PADrend.HID.initVirtualGamepad := fn(){
//
//	// init virtual gamepad
//	var virtualGamepad = new ExtObject;
//
//	Traits.addTrait( virtualGamepad, HID.DeviceBaseTrait, "VirtualGamepad");
//	Traits.addTrait( virtualGamepad, HID.ControllerButtonTrait, 2);
////	Traits.addTrait( virtualGamepad, HID.ControllerHatTrait, 1);
//	Traits.addTrait( virtualGamepad, HID.ControllerAnalogAxisTrait, 4);
//	Traits.addTrait( virtualGamepad, HID.GamepadDeviceTrait);
//	
//	
//	registerExtension('PADrend_UIEvent',virtualGamepad->fn(evt){
//		if(evt.type==Util.UI.EVENT_KEYBOARD){
//			if(evt.key == Util.UI.KEY_B){
//				return this.sendButtonEvent(0,evt.pressed);
//			}else if(evt.key == Util.UI.KEY_N){
//				return this.sendButtonEvent(1,evt.pressed);
//			}
////			if(evt.key == Util.UI.KEY_UP){
////				return this.sendHatEvent(0, this.getHatValue(0).setBitMask(Util.UI.MASK_HAT_UP,evt.pressed) );
////			}else if(evt.key == Util.UI.KEY_DOWN){
////				return this.sendHatEvent(0, this.getHatValue(0).setBitMask(Util.UI.MASK_HAT_DOWN,evt.pressed) );
////			}else if(evt.key == Util.UI.KEY_LEFT){
////				return this.sendHatEvent(0, this.getHatValue(0).setBitMask(Util.UI.MASK_HAT_LEFT,evt.pressed) );
////			}else if(evt.key == Util.UI.KEY_RIGHT){
////				return this.sendHatEvent(0, this.getHatValue(0).setBitMask(Util.UI.MASK_HAT_RIGHT,evt.pressed) );
////			}
//			if(evt.key == Util.UI.KEY_LEFT){
//				return this.sendAnalogAxisEvent(0, this.getAnalogAxisValue(0)+(evt.pressed ? -0.5 : 0.5) );
//			}else if(evt.key == Util.UI.KEY_RIGHT){
//				return this.sendAnalogAxisEvent(0, this.getAnalogAxisValue(0)+(evt.pressed ? 0.5 : -0.5) );
//			}else if(evt.key == Util.UI.KEY_UP){
//				return this.sendAnalogAxisEvent(1, this.getAnalogAxisValue(1)+(evt.pressed ? -0.5 : 0.5) );
//			}else if(evt.key == Util.UI.KEY_DOWN){
//				return this.sendAnalogAxisEvent(1, this.getAnalogAxisValue(1)+(evt.pressed ? 0.5 : -0.5) );
//			}
//
//		}
//	});
//
//	PADrend.HID.registerDevice(virtualGamepad);
//
//
//	virtualGamepad.registerButtonListener(0,fn(button,pressed){
//		outln("FOO:",pressed);
//	});
//
//	virtualGamepad.registerButtonListener(1,fn(button,pressed){
//		outln("Bar:",pressed);
//	});
////	virtualGamepad.registerHatListener(0,fn(hatId,value){
////		outln("hat:",value);
////	});
//};

// ------------------------

PADrend.HID.initDefaultGamepad := fn(DataWrapper sensitivityValue){

	// init the real gamepad here....
	var gamepad = new ExtObject;

	var HIDTraits = Std.require('LibUtilExt/HID_ControllerTraits');
	Traits.addTrait( gamepad, HIDTraits.DeviceBaseTrait, "Gamepad_1");
	Traits.addTrait( gamepad, HIDTraits.ControllerButtonTrait, 10);
	Traits.addTrait( gamepad, HIDTraits.ControllerHatTrait, 1);
	Traits.addTrait( gamepad, HIDTraits.ControllerAnalogAxisTrait, 4);
	Traits.addTrait( gamepad, HIDTraits.GamepadDeviceTrait);
	
	gamepad.sensitivityValue @(private) := sensitivityValue;
	
	registerExtension('PADrend_UIEvent',gamepad->fn(evt){
		var handled = false;
		if(evt.type==Util.UI.EVENT_JOY_AXIS){
			if(evt.joystick == 0){
				var value = evt.value / 32268;
				if(value.abs()<this.sensitivityValue()){
					value = 0;
				}else{
					value -= this.sensitivityValue()*value.sign();
				}
				handled = this.sendAnalogAxisEvent(evt.axis, value  ); 					//!	\see HIDTraits.ControllerAnalogAxisTrait
			}
		}else if(evt.type==Util.UI.EVENT_JOY_BUTTON){
			if(evt.joystick == 0)
				handled = this.sendButtonEvent(evt.button, evt.pressed); 				//!	\see HIDTraits.ControllerButtonTrait
		} else if(evt.type==Util.UI.EVENT_JOY_HAT){
			if(evt.joystick == 0)
				handled = this.sendHatEvent(evt.hat, evt.value); 						//!	\see HIDTraits.ControllerHatTrait
		} 
		return handled ?  Extension.BREAK : Extension.CONTINUE;
	});
	PADrend.HID.registerDevice(gamepad);

};

PADrend.HID.devices @(private) := new Map;

PADrend.HID.registerDevice := fn(deviceObject){
	Traits.requireTrait(deviceObject,Std.require('LibUtilExt/HID_ControllerTraits').DeviceBaseTrait);
	PADrend.HID.devices[deviceObject.getDeviceId()] = deviceObject;
};

PADrend.HID.getDevices := fn(){
	return PADrend.HID.devices;
};

PADrend.HID.getDevice := fn(String name){
	return PADrend.HID.devices[name];
};

PADrend.HID.getDevicesByTraits := fn(requestedFeatures...){
	var m = new Map;
	foreach(PADrend.HID.devices as var name,var device){
		var valid = true;
		foreach(requestedFeatures as var feature){
			if(!Traits.queryTrait(device,feature)){
				valid = false;
				break;
			}
		}
		if(valid)
			m[name] = device;
	}
	return m;
};

PADrend.HID.queryPossibleDeviceNames := fn(requestedFeatures...){
	var names = [];
	foreach(PADrend.HID.getDevicesByTraits(requestedFeatures...) as var name,var device)
		names += name;
	return names;
};

return plugin;

// ------------------------------------------------------------------------------

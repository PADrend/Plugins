/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
 
 
// DeviceHandler
/*! A DeviceHandler wraps a set of HID-devices. 
	- The devices are identified by their name.
	- Callbacks are provided when a device is enabled or disabled.
*/
static T = new Type;
	
T.enabled @(private) := void; // Std.DataWrapper( Bool )
T.deviceNames @(private) := void; // Std.DataWrapper( [String*] )

T.devices @(private,init) := Array;

T.onDeviceEnabled @(init) := MultiProcedure;  // fn(device)
T.onDeviceDisabled @(init) := MultiProcedure;  // fn(device)

T.getDevice ::= fn(){	return this.devices;	};

T._constructor ::= fn(Std.DataWrapper enabledWrapper, Std.DataWrapper deviceNameWrapper){
	this.enabled = enabledWrapper;
	this.deviceNames = deviceNameWrapper;
		
	this.enabled.onDataChanged += this->fn(b){
//		outln("DeviceHandler.enabled.onDataChanged ",b,"(",device,")");
		if(b){
			foreach(this.devices as var device)
				this.onDeviceEnabled(device);
		}else{
			foreach(this.devices as var device)
				this.onDeviceDisabled(device);
		}
	};

	this.deviceNames.onDataChanged += this->fn(Array newDeviceNames){
//		outln("DeviceHandler.newDeviceName.onDataChanged ",newDeviceName);
		var wasEnabled = this.enabled();
		if(wasEnabled)
			this.enabled(false);
		
		this.devices.clear();
		foreach(newDeviceNames as var deviceName){
			var device = PADrend.HID.getDevice(""+deviceName);
			if(device)
				this.devices += device;
		}

		if(wasEnabled)
			this.enabled(true);
		
		
		
		PADrend.message("New devices:"+newDeviceNames.implode(","));
	};
	
	this.deviceNames.forceRefresh();
//	this.enabled.forceRefresh();
};

//! call after the DeviceHandler has been fully initialized to initially call onDeviceEnabled() if necessary.
T.refresh ::= fn(){
	this.deviceNames.forceRefresh();	
};

return T;

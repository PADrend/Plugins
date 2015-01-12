/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014 Mouns R. Husan Almarrani<murrani@mail.uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

// this trait is not required. It only makes things more complex...
var TrackingAppTrait = {
	/*! 
		init( enabled DataWrapper, deviceName DataWrapper, Array with required deviceTraits

		Public attributes:
			- trackingApp_enabled			DataWrapper(Bool)
			- trackingApp_deviceName		DataWrapper(String)
			- getTrackingDevice()			-> HID device
			- onEnableDevice(Device)		MultiProcedure
			- onDisableDevice(Device)		MultiProcedure
			- getPossibleDeviceNames() 		-> [HID device*] (fullfilling required deviceTraits)

	*/
	var t = new Std.Traits.GenericTrait("Tracking.TrackingAppTrait");

	t.attributes.trackingApp_device @(private) := void;
	t.attributes.trackingApp_enabled @(public) := void;
	t.attributes.trackingApp_deviceName @(public) := void;
	t.attributes.trackingApp_deviceTraits @(private) := void;

	t.attributes.getTrackingDevice ::= fn(){	return trackingApp_device;	};


	t.attributes.onEnableDevice @(init) := MultiProcedure;  // fn(device)
	t.attributes.onDisableDevice @(init) := MultiProcedure;  // fn(device)

	t.attributes.getPossibleDeviceNames ::= fn(){
		var names = [];
		foreach(PADrend.HID.getDevicesByTraits(this.trackingApp_deviceTraits...) as var name,var device)
			names += [name];
		return names;
	};
	t.attributes.appInit ::= fn(){
		this.trackingApp_enabled.forceRefresh();
		this.trackingApp_deviceName.forceRefresh();
	};

	t.onInit += fn(app,Std.DataWrapper enabledWrapper,Std.DataWrapper deviceNameWrapper,Array deviceTraits){
		(app -> fn(enabledWrapper,deviceNameWrapper,deviceTraits){
			this.trackingApp_enabled = enabledWrapper;
			this.trackingApp_deviceName = deviceNameWrapper;
			this.trackingApp_deviceTraits = deviceTraits.clone();
			
			this.trackingApp_enabled.onDataChanged += this->fn(b){
				if(this.trackingApp_device){
					if(b){
						this.onEnableDevice(this.trackingApp_device);
					}else{
						this.onDisableDevice(this.trackingApp_device);
					}
				}
			};

			this.trackingApp_deviceName.onDataChanged += this->fn(newDeviceName){
				var newDevice = PADrend.HID.getDevice(""+newDeviceName);
				if(this.trackingApp_enabled()){
					this.trackingApp_enabled(false);
					this.trackingApp_device = newDevice;
					this.trackingApp_enabled(true);
				}else{
					this.trackingApp_device = newDevice;	
				}
				PADrend.message("New device:"+trackingApp_deviceName()+" : "+newDevice);
			};
			
		})(enabledWrapper,deviceNameWrapper,deviceTraits);
		
	};
	t;
};
 
var app = new ExtObject;

//! \see Tracking.TrackingAppTrait
Std.Traits.addTrait(app, TrackingAppTrait,
				DataWrapper.createFromConfig(systemConfig,'Tracking.FlystickCrossHairs.intitiallyEnabled',false ),
				DataWrapper.createFromConfig(systemConfig,'Tracking.FlystickCrossHairs.deviceName', "Flystick"),
				[Std.require('LibUtilExt/HID_Traits').Controller_Room6D_Trait]
);


app.icon := gui.getIcon(__DIR__+"/../resources/CrossHairs.png");
app.marker := void;
app.isActive := true;
app.materialState @(init):= new MinSG.MaterialState();
app.color := new Util.Color4f(255,0,0,1);
app.selectedNode :=void;

var positionHandler = app->fn(roomSRT){
	if(roomSRT){
		var dolly = PADrend.getDolly();

		var cameraFrameArr = dolly.getFrame();
		if(!cameraFrameArr){
			@(once) Runtime.warn("@(once) Using Tracked device for SyncGUI without a camera frame!");
			return;
		}

		var roomScreenPlane = new Geometry.Plane( cameraFrameArr... );
		var roomDeviceRay = new Geometry.Line3( roomSRT.getTranslation(), roomSRT.getDirVector() );
        var worldScreenIntersection = dolly.localPosToWorldPos( roomScreenPlane.getIntersection(roomDeviceRay) );

        this.icon.setWidth(50);
        this.icon.setHeight(50);

		if(worldScreenIntersection){
            this.marker := gui.create({
                GUI.TYPE : GUI.TYPE_ICON,
                GUI.ICON: this.icon,
            });

            gui.registerWindow(this.marker);

            var screenPos = frameContext.convertWorldPosToScreenPos(worldScreenIntersection);
			this.marker.setPosition( [screenPos.x()-this.marker.getWidth()*0.5,screenPos.y()-this.marker.getHeight()*0.5] );
            //--------------------------
//            {
//                var r=new MinSG.RendRayCaster;
//                var node = r.queryNodeFromScreen(frameContext,PADrend.getRootNode(),new Geometry.Vec2(screenPos.getX(),screenPos.getY()),true);
//
//                materialState.setAmbient(color);
//                materialState.setDiffuse(color);
//                if(selectedNode)
//                    selectedNode.removeState(materialState);
//                if(node)
//                    node.addState(materialState);
//                selectedNode = node;
//            }

            this.isActive = true;
		}

	}else if(this.marker){
		this.isActive = false;
		PADrend.planTask(0.5,this->fn(){ // delay window deactivation to prevent flickering
			if(!this.isActive && this.marker){
				gui.markForRemoval(marker);
				this.marker = void;
			}
		});

	}
};


//!	\see Tracking.TrackingAppTrait
app.onEnableDevice += [positionHandler] => fn(positionHandler,device){
	device.onRoomTransformationChanged += positionHandler; /*! \see HID_Traits.Controller_Room6D_Trait */


//    print_r(this);

};

//!	\see Tracking.TrackingAppTrait
app.onDisableDevice += [positionHandler]=>fn(positionHandler,device){	device.onRoomTransformationChanged -= positionHandler; /*! \see HID_Traits.Controller_Room6D_Trait */	};

gui.registerComponentProvider('Tracking_applications.flystickCrossHairs',app->fn(){
	return [
		"FlystickCrossHairs",
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "enabled",
			GUI.DATA_WRAPPER : this.trackingApp_enabled 				//!	\see Tracking.TrackingAppTrait
		},
		{
			GUI.TYPE : GUI.TYPE_SELECT,
			GUI.LABEL : "Device",
			GUI.DATA_WRAPPER : this.trackingApp_deviceName,				//!	\see Tracking.TrackingAppTrait
			GUI.OPTIONS_PROVIDER : this->this.getPossibleDeviceNames	//!	\see Tracking.TrackingAppTrait
		},
		'----'
	];
});

//! \todo make eyeOffsetVector adjustable (parseJSON(getText()))...

app.appInit();		//!	\see Tracking.TrackingAppTrait


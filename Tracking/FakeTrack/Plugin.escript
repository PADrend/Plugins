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


var plugin = new Plugin({
		Plugin.NAME : 'Tracking/FakeTrack',
		Plugin.DESCRIPTION :  "Simulation of a tracking system for development.",
		Plugin.VERSION :  1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "Claudius",
		Plugin.LICENSE : "PROPRIETARY",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});



plugin.init @(override) := fn(){
	static active = Std.DataWrapper.createFromEntry(PADrend.configCache,'Tracking.fakeTrackEnabled', false);
	static controllerNode;

	static HID_Traits = Std.require('LibUtilExt/HID_Traits');

	registerExtension('PADrend_Init', fn(){
		var buttons = [];
		for(var buttonNr=0; buttonNr<5; ++buttonNr){
			var b = new Std.DataWrapper(false);
			b.onDataChanged += [buttonNr] => fn(buttonNr,b){
				//! \see HID_Traits.ControllerButtonTrait
				controllerNode.sendButtonEvent(buttonNr,b);
			};
			buttons += b;
		}
		var buttonEntries = [];
		foreach(buttons as var id,var b){
//			buttonEntries += ;
			buttonEntries += {
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Button #"+id,
				GUI.DATA_WRAPPER : b
			};
		}
		gui.register('Tracking_drivers.fake',[{
			GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
			GUI.COLLAPSED : true,
			GUI.HEADER : ["Device: Fake tracking device(debug)"],
			GUI.CONTENTS : [
				{
					GUI.TYPE : GUI.TYPE_BOOL,
					GUI.LABEL : "Enable fake tracker (requires restart)",
					GUI.DATA_WRAPPER : active
				},
				{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
				buttonEntries...
			]
		}]);
	});

	active.onDataChanged += fn(a){
		if(!a){
			if(controllerNode){
				MinSG.destroy(controllerNode);
				controllerNode = void;
			}
		}else if(!controllerNode){
			controllerNode = new MinSG.GeometryNode;
			var mb = new Rendering.MeshBuilder;
			mb.color( new Util.Color4f(1,1,1,1) );
			mb.addBox( new Geometry.Box(new Geometry.Vec3(0,0,0),0.2,0.2,0.2) );
			controllerNode.setMesh( mb.buildMesh() );

			PADrend.getRootNode() += controllerNode;

			//! \see HID_Traits.DeviceBaseTrait
			Std.Traits.addTrait( controllerNode, HID_Traits.DeviceBaseTrait, "Fake6DoF");

			//! \see HID_Traits.Controller_Room6D_Trait
			Std.Traits.addTrait( controllerNode, HID_Traits.Controller_Room6D_Trait);
			controllerNode.onRoomTransformationChanged += fn(t){
//				out(".");
			};

			//! \see HID_Traits.ControllerButtonTrait
			Std.Traits.addTrait( controllerNode, HID_Traits.ControllerButtonTrait, 5);

			//! \see HID_Traits.ControllerAnalogAxisTrait
			Std.Traits.addTrait( controllerNode, HID_Traits.ControllerAnalogAxisTrait, 2);

			//! \see TransformationObserverTrait
			var TransformationObserverTrait = Std.require('LibMinSGExt/Traits/TransformationObserverTrait');
			Std.Traits.addTrait( controllerNode, TransformationObserverTrait);
			controllerNode.onNodeTransformed += fn(node){
				this.sendTransformationEvent(node.getRelTransformationSRT()); //! \see HID_Traits.Controller_Room6D_Trait
			};

			outln("**Registering HID Device: Fake6DoF");
			PADrend.HID.registerDevice(controllerNode);
		}
	};

	registerExtension('PADrend_Init', fn(){	active.forceRefresh();	},Util.EXTENSION_PRIORITY_HIGH);


	// -------------------------------------------------------------------------------------------------------------

//	static mouseTrackEnabled = new Std.DataWrapper(false);
	static mouseTracker = new ExtObject;

	//! \see HID_Traits.DeviceBaseTrait
	Std.Traits.addTrait( mouseTracker, HID_Traits.DeviceBaseTrait, "MouseTracker6DoF");

	//! \see HID_Traits.Controller_Room6D_Trait
	Std.Traits.addTrait( mouseTracker, HID_Traits.Controller_Room6D_Trait);

	//! \see HID_Traits.ControllerButtonTrait
	Std.Traits.addTrait( mouseTracker, HID_Traits.ControllerButtonTrait, 5);

	PADrend.HID.registerDevice(mouseTracker);

	static posText = new Std.DataWrapper("...");

	module.on('PADrend/gui',fn(gui){

		gui.register('Tracking_drivers.mouse',[{
			GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
			GUI.COLLAPSED : true,
			GUI.HEADER : ["Device: Mouse tracking device (debug)"],
			GUI.CONTENTS : [
				{
					GUI.TYPE : GUI.TYPE_LABEL,
					GUI.LABEL : "[ TouchArea ]",
					GUI.SIZE :  [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , 200 ,200 ],
					GUI.FLAGS : GUI.BORDER,
					GUI.DATA_WRAPPER : posText,
					GUI.ON_MOUSE_BUTTON : fn( evt ){
						outln( "Button: ", evt.button, " ",evt.pressed);
						mouseTracker.sendButtonEvent(evt.button,evt.pressed);	//! \see HID_Traits.ControllerButtonTrait
					},
					GUI.ON_INIT : fn(){
						gui.onMouseMove += [this] => fn(panel, evt){
							if(panel.isDestroyed())
								return $REMOVE;
							if( panel.coversAbsPosition( [evt.x, evt.y] )){
								for(var c=panel;c;c=c.getParentComponent()){
									if(c---|>GUI.Window && !c.isSelected())
										return;
								}
								var localPos = new Geometry.Vec2([evt.x, evt.y]) - panel.getAbsPosition();
								var roomPos = new Geometry.Vec3( (localPos.x()-100)*0.01 , (100-localPos.y())*0.01, 0.5);
								posText( roomPos.toString() );
								var roomSRT = new Geometry.SRT( roomPos, [0,0,-1], [0,1,0]);
//								print_r(localPos.toArray());
								mouseTracker.sendTransformationEvent(roomSRT); //! \see HID_Traits.Controller_Room6D_Trait
							}
	//						this.handlePointerMovement( [evt.x, evt.y] );
						};
					},
					GUI.TOOLTIP : "Selecte to activate\n"
					"[L-Button] -> Button 0\n"
					"[M-Button] -> Button 1\n"
					"[R-Button] -> Button 2\n"
					"[Esc] to stop capturing."
				}
//				{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
			]
		}]);
	});


	return true;
};


return plugin;
// ------------------------------------------------------------------------------

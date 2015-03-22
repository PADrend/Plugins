/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2014 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static deviceRequirements = [	Std.require('LibUtilExt/HID_Traits').Controller_Room6D_Trait,
								Std.require('LibUtilExt/HID_Traits').ControllerButtonTrait];
static enabled = Std.DataWrapper.createFromEntry( systemConfig,'Tracking.Graffite.intitiallyEnabled',false );
static deviceNames = Std.DataWrapper.createFromEntry(systemConfig,'Tracking.Graffite.deviceNames', ["Flystick"]);

// ------------

static GraffitiRendererState = new Type(MinSG.ScriptedState);
GraffitiRendererState._printableName @(override) ::= "GraffitiPointer";
GraffitiRendererState.name ::= "GraffitiPointer";

GraffitiRendererState.roomSource := void;
GraffitiRendererState.roomTarget := void;

GraffitiRendererState._constructor @(override) ::= fn(){
	this.setTempState( true );
	this.roomSource = new Geometry.Vec3(0,0,0);
	this.roomTarget = new Geometry.Vec3(0,10,0);
};
GraffitiRendererState.doEnableState @(override) ::= fn(d*) {};

static DISTANCE = 1;
static POINT_SIZE = 20;

static COLOR = new Util.Color4f(1,0,0,1.2);

GraffitiRendererState.doDisableState @(override) ::= fn(d*) {
	if(this.roomSource&&this.roomTarget){

		static pointerNode;
		static TrackingTools;
		@(once){
			TrackingTools = module('../TrackingTools');

			{
				var mb = new Rendering.MeshBuilder;
				mb.color(COLOR);
				mb.position([0,0,0]);
				mb.addVertex();
				var mesh = mb.buildMesh();
				mesh.setDrawPoints();
				mesh.setUseIndexData(false);
				pointerNode = new MinSG.GeometryNode( mesh );

			}
		}

		var p1 = TrackingTools.roomPosToWorldPos( this.roomSource );
		var p2 = TrackingTools.roomPosToWorldPos( this.roomTarget );

		// -----------
		

//		pointerNode.setRelOrigin( p2 );
		pointerNode.setRelOrigin( p1+(p2-p1)*0.99 );


//		color.setColor(0, new Util.Color4f(0, 1, 0, 1));
//		color.setColor(1, new Util.Color4f(0, 1, 0, (1.0-p1.distance(p2)*0.1).clamp(0.2,1.0)  ));


		renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );
		renderingContext.pushLine();
		renderingContext.pushPointParameters();


		renderingContext.pushAndSetLighting(false);
		renderingContext.setLineWidth(6.0);

		var blending=new Rendering.BlendingParameters;
		blending.enable();
		blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE);
		renderingContext.pushAndSetBlending(blending);
			renderingContext.pushAndSetDepthBuffer(false, false, Rendering.Comparison.LESS);

				// draw beams
				renderingContext.setLineWidth(1.0);

				renderingContext.setPointParameters( new Rendering.PointParameters(POINT_SIZE*0.5) );
				pointerNode.display(frameContext);
				renderingContext.setPointParameters( new Rendering.PointParameters(POINT_SIZE*0.25) );
				pointerNode.display(frameContext);


			renderingContext.popDepthBuffer();
			renderingContext.pushAndSetDepthBuffer(true, false, Rendering.Comparison.LESS);

				renderingContext.applyChanges();

				// draw beams
				for(var i=1;i<=4.0;++i){
					renderingContext.setLineWidth(i);

				}

				for(var i=1;i<=POINT_SIZE;++i){
					renderingContext.setPointParameters( new Rendering.PointParameters(i) );
					pointerNode.display(frameContext);

				}
			renderingContext.popDepthBuffer();

		renderingContext.popBlending();


		renderingContext.popPointParameters();
		renderingContext.popLine();
		renderingContext.popLighting();
		renderingContext.popMatrix_modelToCamera();

	}
};

// -----------------

static renderer;

static rpc = Util.requirePlugin('PADrend/RemoteControl');
rpc.registerFunction('Tracking.GraffitiApp.set',fn(Array roomSource,Array roomTarget, Bool active = false){
	if(!renderer){
		renderer = new GraffitiRendererState;
		PADrend.getRootNode() += renderer;
	}
	renderer.roomSource = new Geometry.Vec3(roomSource);
	renderer.roomTarget = new Geometry.Vec3(roomTarget);
	
	
});

rpc.registerFunction('Tracking.GraffitiApp.disable',fn(){
	if(renderer){
		PADrend.getRootNode().removeState(renderer);
		renderer = void;
	}
});

rpc.registerFunction('Tracking.GraffitiApp.setMode',fn(mode){
	enabled (mode =="true" ? true : false);
});

static buttonHandler = fn(button,pressed){
	if(button==0){
		
		
		
	}
};
static positionHandler = fn(roomSRTOrVoid){
	if(roomSRTOrVoid.isA(Geometry.SRT)){
		@(once) static TrackingTools = module('../TrackingTools');

		var worldSRT = TrackingTools.roomSRTToWorldSRT(roomSRTOrVoid);
		var worldSource = worldSRT.getTranslation();
		var worldTarget = TrackingTools.querySceneIntersection( new Geometry.Segment3( worldSource, worldSource+worldSRT.getDirVector()*DISTANCE ));

		rpc.broadcast('Tracking.GraffitiApp.set',
						TrackingTools.worldPosToRoomPos(worldSource).toArray(),
						TrackingTools.worldPosToRoomPos(worldTarget).toArray());
	}else{
		rpc.broadcast('Tracking.GraffitiApp.disable' );
	}

};

static myDeviceHandler = new (module('../DeviceHandler'))(enabled, deviceNames);
myDeviceHandler.onDeviceEnabled += fn(device){
//	outln("Graffiti enabled.");
	device.onRoomTransformationChanged += positionHandler; 	/*! \see HID_Traits.Controller_Room6D_Trait */
	device.onButton += buttonHandler;						//!	\see HID_Traits.ControllerButtonTrait
};
myDeviceHandler.onDeviceDisabled += fn(device){
	positionHandler(void);
	device.onRoomTransformationChanged -= positionHandler; 	/*! \see HID_Traits.Controller_Room6D_Trait */
	device.onButton -= buttonHandler;						//!	\see HID_Traits.ControllerButtonTrait
};
myDeviceHandler.refresh();

gui.register('Tracking_applications.graffiti',fn(){
	return [{
		GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
		GUI.COLLAPSED : true,
		GUI.HEADER : [{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL :"3-D-Graffiti",
			GUI.DATA_WRAPPER : enabled
		}],
		GUI.CONTENTS : fn(){
			var options = [];
			foreach( PADrend.HID.queryPossibleDeviceNames(deviceRequirements...) as var deviceName)
				options += [deviceName,deviceName];
			return [{
				GUI.TYPE : GUI.TYPE_LIST,
				GUI.LABEL : "Device",
				GUI.DATA_WRAPPER : deviceNames,
				GUI.OPTIONS : options,
				GUI.HEIGHT : options.count() * 15+3,
				GUI.TOOLTIP : "Used devices. Hold [ctrl] to select multiple devices."
			}];
		}
	}];
});

return true;
